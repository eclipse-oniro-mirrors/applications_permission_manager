/*
 * Copyright (c) 2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import UIExtensionAbility from '@ohos.app.ability.UIExtensionAbility';
import window from '@ohos.window';
import { Log, PermissionDialogException, setAvoidArea } from '../common/utils/utils';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import Want from '@ohos.app.ability.Want';
import uiExtensionHost from '@ohos.uiExtensionHost';
import display from '@ohos.display';
import { BusinessError } from '@ohos.base';
import Constants from '../common/utils/constant';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';

let terminating: boolean = false;
let state: boolean = false;

export default class GlobalSwitchSheetAbility extends UIExtensionAbility {
  private subWindowForHost: window.Window | null = null;
  private shouldChangeState: boolean = true;

  onCreate(launchParam: AbilityConstant.LaunchParam): void {
    Log.info('GlobalSwitchSheetAbility on create');
  }

  onSessionCreate(want: Want, session: UIExtensionContentSession): void {
    Log.info('current state:' + state);
    if (state == true) {
      this.shouldChangeState = false;
      Log.error('window state is already set');
      PermissionDialogException(Constants.ERR_MODAL_ALREADY_EXIST, session);
      this.context.terminateSelf();
      return;
    } else {
      Log.info('set window state to true');
      state = true;
    }

    let param: Record<string, Object> = {
      'session': session, 'want': want
    };

    let storage: LocalStorage = new LocalStorage(param);
    this.createSubWindow(session, storage).then(() => {
      // if met error, do not load window,
      // in case of nested error codes passed to applications
      if (terminating) {
        this.context.terminateSelf();
        return;
      }
      this.loadContentAndSetColor(storage).then((result: boolean) => {
        if (!result) {
          return;
        }
        this.showWindow();
      })
    })
  }

  onSessionDestroy(): void {
    Log.info('OnSessionDestroy start');
    try {
      Log.info('try to reshow non-secure windows.');
      this.subWindowForHost?.hideNonSystemFloatingWindows(false);
    } catch (error) {
      Log.error('failed to reshowing the non-secure windows. Cause: ' + JSON.stringify(error));
    }
    try {
      this.subWindowForHost?.off('windowEvent');
    } catch (exception) {
      Log.error('fail to call off window event: ' + JSON.stringify(exception));
    }
    this.subWindowForHost?.destroyWindow((err, data) => {
      if (err && err.code !== 0) {
        Log.info('destroy window:' + err.message + ' ' + JSON.stringify(data));
      }
    });
    Log.info('destroy window end');
  }

  onForeground(): void {
    Log.info('onForegorund');
    this.subWindowForHost?.showWindow();
  }

  onBackground(): void {
    Log.info('extension onBackground');
    this.subWindowForHost?.hide();
  }

  onDestroy(): void | Promise<void> {
    Log.info('onDestroy');
    if (this.shouldChangeState == true) {
      state = false;
      Log.info('set window state to false');
    }
    this.subWindowForHost = null;
  }

  async loadContentAndSetColor(storage: LocalStorage): Promise<boolean> {
    let promise: Promise<void> | undefined =
      this.subWindowForHost?.loadContent('PermissionSheet/GlobalSwitchSheetDialog', storage);
    if (promise) {
      await promise.then(() => {
        Log.info('Succeeded in loading the content');
        try {
          this.subWindowForHost?.setWindowBackgroundColor('#00000000');
        } catch (error) {
          Log.error(`setWindowBackgroundColor failed, error code ${JSON.stringify(error)}`);
        }
      }).catch((err: BusinessError) => {
        Log.error('Failed to load the content. Cause:' + JSON.stringify(err));
        return false;
      })
    }
    return true;
  }

  async createSubWindow(session: UIExtensionContentSession, storage: LocalStorage): Promise<void> {
    let extensionWinProxy: uiExtensionHost.UIExtensionHostWindowProxy = session?.getUIExtensionHostWindowProxy();
    setAvoidArea(extensionWinProxy);
    let subWindowOpts: window.SubWindowOptions = {
      title: '', decorEnabled: false, isModal: true,
    };
    if (!extensionWinProxy) {
      Log.error('extensionWinProxy is nullptr!');
      return;
    }
    // try to create subwindow first
    await extensionWinProxy.createSubWindowWithOptions('permissionSubWindowForHost' + Date(), subWindowOpts)
      .then((subWindow: window.Window)=>{
        this.subWindowForHost = subWindow;
      }).catch((err: BusinessError) => {
        Log.error('create sub window error:' + err.message + ' ' + err.code);
      });
    // if create subwindow fails, try create floating window
    if (!this.subWindowForHost) {
      Log.error('subwindow is null, failed to create subwindow, tray create float window');
      await this.createFloatingWindow(session);
      if (!this.subWindowForHost) {
        terminating = true;
        PermissionDialogException(Constants.ERR_MODAL_ALREADY_EXIST, session);
        this.context.terminateSelf();
        Log.error('floating is null, failed to create float window, terminate self');
        return;
      }
    }
    try {
      let dis = display.getDefaultDisplaySync();
      await this.subWindowForHost?.resize(dis.width, dis.height).catch((err: BusinessError) => {
        Log.error('resize window error: ' + err.code + ' ' + err.message);
      });
    } catch (error) {
      Log.error('getDefaultDisplaySync error: ' + error.code + ' ' + error.message);
    }
    this.subWindowForHost?.on('windowEvent', (eventType: window.WindowEventType) => {
      Log.info('window event type is: ' + eventType);
      storage.setOrCreate('permissionWindow', eventType);
    })
    Log.info('create and resize window success');
    return;
  }

  async createFloatingWindow(session: UIExtensionContentSession): Promise<void> {
    let config: window.Configuration = {
      name: 'PermissionFloatWindow' + Date(),
      windowType: window.WindowType.TYPE_FLOAT,
      ctx: this.context
    }
    let promise: Promise<window.Window> | undefined = window.createWindow(config);
    await promise.then((floatWindow: window.Window) => {
      this.subWindowForHost = floatWindow;
      session.loadContent('');
      session.setWindowBackgroundColor('#00000000');
    }).catch((err: BusinessError) => {
      Log.error('create floating window error:' + err.message + ' ' + err.code);
      // if modal already exist , return
      if (err.code === Constants.CREATE_WINDOW_REPEATED) {
        Log.error('try to create subwindow repeatedly');
        terminating = true;
        PermissionDialogException(Constants.ERR_MODAL_ALREADY_EXIST, session);
        this.context.terminateSelf();
      }
    });
    if (!this.subWindowForHost) {
      Log.error('create floating fail');
      return;
    }
    Log.info('create floating window success');
  }

  showWindow(): void {
    this.subWindowForHost?.showWindow((err) => {
      if (err && err.code !== 0) {
        Log.error(`failed to showWindow for subWindow, ${JSON.stringify(err)}`);
        return;
      }
      this.subWindowForHost?.hideNonSystemFloatingWindows(true);
      Log.info('show window and set non floating success');
    })
  }
}
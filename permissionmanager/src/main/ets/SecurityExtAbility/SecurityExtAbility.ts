/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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

import extension from '@ohos.app.ability.ServiceExtensionAbility';
import window from '@ohos.window';
import display from '@ohos.display';
import { GlobalContext } from '../common/utils/globalContext';

const TAG = 'PermissionManager_Log:';
const BG_COLOR = '#00000000';
const DELAY = 100;

export default class SecurityExtensionAbility extends extension {
  /**
   * Lifecycle function, called back when a service extension is started for initialization.
   */
  onCreate(want): void {
    console.info(TAG + 'SecurityExtensionAbility onCreate, ability name is ' + want.abilityName);
    globalThis.windowNum = 0;
    console.info(TAG + 'Set windowNum = 0');
  }

  /**
   * Lifecycle function, called back when a service extension is started or recall.
   */
  onRequest(want, startId): void {
    console.info(TAG + 'SecurityExtensionAbility onRequest. start id is ' + startId);
    console.info(TAG + 'want: ' + JSON.stringify(want));

    try {
      let dis = display.getDefaultDisplaySync();
      let navigationBarRect = {
        left: 0,
        top: 0,
        width: dis.width,
        height: dis.height
      };
      this.createWindow('SecurityDialog' + startId, window.WindowType.TYPE_DIALOG, navigationBarRect, want);
    } catch (exception) {
      console.error(TAG + 'Failed to obtain the default display object. Code: ' + JSON.stringify(exception));
    };
  }

  /**
   * Lifecycle function, called back before a service extension is destroyed.
   */
  onDestroy(): void {
    console.info(TAG + 'SecurityExtensionAbility onDestroy.');
    try {
      // 如果通过on注册多个callback，同时关闭所有callback监听
      display.off('foldStatusChange');
    } catch (exception) {
      console.error('Failed to unregister callback. Code: ' + JSON.stringify(exception));
    }
  }

  private async createWindow(name: string, windowType, rect, want): Promise<void> {
    console.info(TAG + 'create securityWindow');
    let dialogSet: Set<string> = GlobalContext.load('dialogSet');
    if (!dialogSet) {
      dialogSet = new Set<string>();
      console.info(TAG + 'new dialogSet');
      GlobalContext.store('dialogSet', dialogSet);
    }
    let callerToken: string = want.parameters['ohos.aafwk.param.callerBundleName'];
    if (dialogSet.has(callerToken)) {
      console.info(TAG + 'window already exists');
      return;
    }
    try {
      const win = await window.createWindow({ ctx: this.context, name, windowType });
      let storage: LocalStorage = new LocalStorage({ 'want': want, 'win': win });
      await win.bindDialogTarget(want.parameters['ohos.ability.params.token'].value, () => {
        win.destroyWindow();
        let dialogSet: Set<string> = GlobalContext.load('dialogSet');
        let callerToken: string = want.parameters['ohos.aafwk.param.callerBundleName'];
        dialogSet.delete(callerToken);
        GlobalContext.store('dialogSet', dialogSet);
        if (dialogSet.size === 0) {
          this.context.terminateSelf();
        }
      });
      await win.moveWindowTo(rect.left, rect.top);
      await win.resize(rect.width, rect.height);
      await win.loadContent('pages/securityDialog', storage);
      win.setWindowBackgroundColor(BG_COLOR);
      await win.showWindow();
      console.info(TAG + 'showWindow end.');
      dialogSet.add(callerToken);
      GlobalContext.store('dialogSet', dialogSet);
      this.monitorFold(win);
    } catch (err) {
      console.error(TAG + `window create failed! err: ${JSON.stringify(err)}`);
    }
  }

  private monitorFold(win: window.Window): void {
    try {
      let foldStatus = display.getFoldStatus();
      display.on('foldStatusChange', (data) => {
        if (data !== foldStatus) {
          console.info(TAG + `monitor foldStatusChange: ${JSON.stringify(data)}`);
          foldStatus = data;
          setTimeout(() => {
            let dis = display.getDefaultDisplaySync();
            win.resize(dis.width, dis.height);
            win.moveWindowTo(0, 0);
          }, DELAY);
        }
      });
    } catch (err) {
      console.error(TAG + `monitor foldStatusChange failed: ${JSON.stringify(err)}`);
    }
  }
};

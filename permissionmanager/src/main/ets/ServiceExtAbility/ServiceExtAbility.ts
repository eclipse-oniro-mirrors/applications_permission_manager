/*
 * Copyright (c) 2022 Huawei Device Co., Ltd.
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
import rpc from '@ohos.rpc';
import { GlobalContext } from '../common/utils/globalContext';
import dialogRequest from '@ohos.app.ability.dialogRequest';

const TAG = 'PermissionManager_Log: ';
const BG_COLOR = '#00000000';
const DEFAULT_CORNER_RADIUS_L = 16;
const RESULT_CODE_1 = 1;
const ACCESS_TOKEN = 'ohos.security.accesstoken.tokencallback';

export default class ServiceExtensionAbility extends extension {
  /**
  * Lifecycle function, called back when a service extension is started for initialization.
  */
  onCreate(want): void {
    console.info(TAG + 'ServiceExtensionAbility onCreate, ability name is ' + want.abilityName);

    globalThis.windowNum = 0;
  }

  /**
  * Lifecycle function, called back when a service extension is started or recall.
  */
  onRequest(want, startId): void {
    console.info(TAG + 'ServiceExtensionAbility onRequest. start id is ' + startId);
    console.info(TAG + 'want: ' + JSON.stringify(want));

    try {
      let dis = display.getDefaultDisplaySync();
      let navigationBarRect = {
        left: 0,
        top: 0,
        width: dis.width,
        height: dis.height
      };
      this.createWindow('permissionDialog' + startId, window.WindowType.TYPE_DIALOG, navigationBarRect, want);
    } catch (exception) {
      console.error(TAG + 'Failed to obtain the default display object. Code: ' + JSON.stringify(exception));
    };
  }

  /**
  * Lifecycle function, called back before a service extension is destroyed.
  */
  onDestroy(): void {
    console.info(TAG + 'ServiceExtensionAbility onDestroy.');
  }

  private async createWindow(name: string, windowType, rect, want): Promise<void> {
    let requestInfo: dialogRequest.RequestInfo;
    try {
      requestInfo = dialogRequest.getRequestInfo(want);
    } catch (err) {
      console.error(`getRequestInfo err= ${JSON.stringify(err)}`);
    }

    console.info(TAG + 'create window start, requestInfo: ' + JSON.stringify(requestInfo));
    let rectInfo = requestInfo ? requestInfo.windowRect : rect;
    rectInfo = rectInfo.width === 0 ? rect : rectInfo;
    try {
      const win = await window.createWindow({ ctx: this.context, name, windowType });
      console.info(TAG + 'createWindow end.');
      let storage: LocalStorage = new LocalStorage({ 'want': want, 'win': win });
      await this.BindDialogTarget(win, want);
      console.info(TAG + 'bindDialogTarget end.');
      await win.moveWindowTo(rectInfo.left, rectInfo.top);
      console.info(TAG + 'moveWindowTo end.');
      await win.resize(rectInfo.width, rectInfo.height);
      console.info(TAG + 'resize end.');
      await win.loadContent('pages/dialogPlus', storage);
      win.setWindowBackgroundColor(BG_COLOR);
      if (rectInfo.width < rect.width) {
        win.setCornerRadius(DEFAULT_CORNER_RADIUS_L);
      }
      await win.showWindow();
      console.info(TAG + 'showWindow end.');
      await win.setWindowLayoutFullScreen(true);
      console.info(TAG + 'setWindowLayoutFullScreen end.');
      globalThis.windowNum ++;
      GlobalContext.store('windowNum', globalThis.windowNum);
    } catch {
      console.info(TAG + 'window create failed!');
    }
  }
  private async BindDialogTarget(win, want): Promise<void> {
    let proxy = want.parameters['ohos.ability.params.callback'].value;
    let option = new rpc.MessageOption();
    let data = new rpc.MessageSequence();
    let reply = new rpc.MessageSequence();
    win.bindDialogTarget(want.parameters['ohos.ability.params.token'].value, () => {
      Promise.all([
        data.writeInterfaceToken(ACCESS_TOKEN),
      ]).then(() => {
        proxy.sendMessageRequest(RESULT_CODE_1, data, reply, option);
      }).catch(() => {
        console.error('write result failed!');
      });
      let windowNum = GlobalContext.load('windowNum');
      windowNum --;
      GlobalContext.store('windowNum', windowNum);
      win.destroyWindow();
      if (windowNum === 0) {
        this.context.terminateSelf();
      }
    });
  }
};
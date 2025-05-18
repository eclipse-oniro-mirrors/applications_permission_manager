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
import { GlobalContext } from '../common/utils/globalContext';
import { Configuration } from '@ohos.app.ability.Configuration';

const TAG = 'PermissionManager_Log:';
const BG_COLOR = '#00000000';

enum NotifyType {
  Toast = 1,
  Dialog = 0
}

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
      let width = want.parameters['ohos.display.width'] ?? 0;
      let height = want.parameters['ohos.display.height'] ?? 0;
      let top = want.parameters['ohos.display.top'] ?? 0;
      let navigationBarRect = {
        left: 0,
        top: top,
        width: width,
        height: height
      };
      let notifyType = want.parameters['ohos.ability.notify.type'] ?? 0;
      if (notifyType === NotifyType.Toast) {
        try {
          startId > 1 && window.findWindow(`SaveButtonTip${startId - 1}`).destroyWindow();
        } catch (exception) {
          console.error(`Failed to find the Window. Cause code: ${exception.code}, message: ${exception.message}`);
        }
        this.createToast('SaveButtonTip' + startId, window.WindowType.TYPE_SYSTEM_TOAST, navigationBarRect, want);
      } else {
        this.createWindow('SecurityDialog' + startId, window.WindowType.TYPE_DIALOG, navigationBarRect, want);
      }
    } catch (exception) {
      console.error(TAG + 'Failed to obtain the default display object. Code: ' + JSON.stringify(exception));
    };
  }

  /**
   * Lifecycle function, called back before a service extension is destroyed.
   */
  onDestroy(): void {
    console.info(TAG + 'SecurityExtensionAbility onDestroy.');
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    console.info(TAG + 'onConfigurationUpdate: ' + JSON.stringify(newConfig));
  }

  private async createWindow(name: string, windowType, rect, want): Promise<void> {
    console.info(TAG + 'create securityWindow');
    let dialogSet: Set<String> = GlobalContext.load('dialogSet');
    if (!dialogSet) {
      dialogSet = new Set<String>();
      console.info(TAG + 'new dialogSet');
      GlobalContext.store('dialogSet', dialogSet);
    }
    let callerToken: number = want.parameters['ohos.caller.uid'];
    let windId: number = want.parameters['ohos.ability.params.windowId'];
    let token: String = String(callerToken) + '_' + String(windId);
    if (dialogSet.has(token)) {
      console.info(TAG + 'window already exists');
      return;
    }
    try {
      const win = await window.createWindow({ ctx: this.context, name, windowType });
      let storage: LocalStorage = new LocalStorage({ 'want': want, 'win': win });
      await win.bindDialogTarget(want.parameters['ohos.ability.params.token'].value, () => {
        win.destroyWindow();
        let dialogSet: Set<String> = GlobalContext.load('dialogSet');
        let callerToken: number = want.parameters['ohos.caller.uid'];
        let windId: number = want.parameters['ohos.ability.params.windowId'];
        let token: String = String(callerToken) + '_' + String(windId);
        dialogSet.delete(token);
        GlobalContext.store('dialogSet', dialogSet);
        if (dialogSet.size === 0) {
          this.context.terminateSelf();
        }
      });
      try {
        await win.setFollowParentWindowLayoutEnabled(true);
      } catch (error) {
        console.error(TAG + `setFollowParentWindowLayoutEnabled error: ${JSON.stringify(error)}.`);
        await win.moveWindowTo(rect.left, rect.top);
        await win.resize(rect.width, rect.height);
      };
      await win.loadContent('pages/securityDialog', storage);
      win.setWindowBackgroundColor(BG_COLOR);
      await win.showWindow();
      console.info(TAG + 'showWindow end.');
      dialogSet.add(token);
      GlobalContext.store('dialogSet', dialogSet);
    } catch (err) {
      console.error(TAG + `window create failed! err: ${JSON.stringify(err)}`);
    }
  }

  private async createToast(name: string, windowType, rect, want): Promise<void> {
    try {
      const win = await window.createWindow({ ctx: this.context, name, windowType });
      let property: Record<string, Object> = { 'want': want, 'win': win };
      let storage: LocalStorage = new LocalStorage(property);
      await win.moveWindowTo(rect.left, rect.top);
      await win.resize(rect.width, rect.height);
      try {
        await win.setSystemAvoidAreaEnabled(true);
      } catch (error) {
        console.error(TAG + `setSystemAvoidAreaEnabled error: ${JSON.stringify(error)}.`);
      };
      await win.loadContent('pages/securityToast', storage);
      win.setWindowBackgroundColor(BG_COLOR);
      await win.setWindowTouchable(false);
      await win.setWindowFocusable(false);
      await win.showWindow();
    } catch (error) {
      console.error(TAG + `window create failed! err: ${JSON.stringify(error)} `);
    }
  }
};

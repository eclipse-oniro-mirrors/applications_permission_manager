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
import Want from '@ohos.app.ability.Want';
import { Property, NavigationBarRect } from '../common/model/typedef';
import { Log, destruction } from '../common/utils/utils';
import { PermissionType } from '../common/model/definition';

const BG_COLOR = '#00000000';

export default class SecurityExtensionAbility extends extension {
  /**
   * Lifecycle function, called back when a service extension is started for initialization.
   */
  onCreate(want: Want): void {
    Log.info(`SecurityExtensionAbility onCreate, ability name is ${want.abilityName}.`);
    globalThis.windowNum = 0;
  }

  /**
   * Lifecycle function, called back when a service extension is started or recall.
   */
  onRequest(want: Want, startId: number): void {
    Log.info(`SecurityExtensionAbility onRequest. start id is ${startId}.`);

    try {
      let width = want.parameters?.['ohos.display.width'] as number ?? 0;
      let height = want.parameters?.['ohos.display.height'] as number ?? 0;
      let navigationBarRect: NavigationBarRect = {
        left: 0,
        top: 0,
        width: width,
        height: height
      };
      this.createWindow('SecurityDialog' + startId, window.WindowType.TYPE_DIALOG, navigationBarRect, want);
    } catch (exception) {
      Log.error(`Failed to obtain the default display object. Code: ${JSON.stringify(exception)}.`);
    };
  }

  /**
   * Lifecycle function, called back before a service extension is destroyed.
   */
  onDestroy(): void {
    Log.info('SecurityExtensionAbility onDestroy.');
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    Log.info(`onConfigurationUpdate: ${JSON.stringify(newConfig)}.`);
  }

  private async createWindow(name: string, windowType: window.WindowType, rect: NavigationBarRect,
    want: Want): Promise<void> {
    Log.info('create securityWindow.');
    let dialogSet: Set<String> = GlobalContext.load('dialogSet');
    if (!dialogSet) {
      dialogSet = new Set<String>();
      Log.info('new dialogSet.');
      GlobalContext.store('dialogSet', dialogSet);
    }
    let callerToken: number = want.parameters?.['ohos.caller.uid'] as number;
    let windId: number = want.parameters?.['ohos.ability.params.windowId'] as number;
    let token: String = String(callerToken) + '_' + String(windId);
    if (dialogSet.has(token)) {
      Log.info('window already exists.');
      return;
    }
    try {
      const win = await window.createWindow({ ctx: this.context, name, windowType });
      let property: Record<string, Object> = { 'want': want, 'win': win };
      let storage: LocalStorage = new LocalStorage(property);
      let tokenValue = want.parameters?.['ohos.ability.params.token'] as Property;
      await win.bindDialogTarget(tokenValue.value, () => {
        win.destroyWindow();
        let dialogSet: Set<String> = GlobalContext.load('dialogSet');
        let callerToken: number = want.parameters?.['ohos.caller.uid'] as number;
        let windId: number = want.parameters?.['ohos.ability.params.windowId'] as number;
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
        Log.error(`setFollowParentWindowLayoutEnabled error: ${JSON.stringify(error)}.`);
        await win.moveWindowTo(rect.left, rect.top);
        await win.resize(rect.width, rect.height);
      };
      await win.loadContent('pages/securityDialog', storage);
      win.setWindowBackgroundColor(BG_COLOR);
      await win.showWindow();
      Log.info('showWindow end.');
      dialogSet.add(token);
      GlobalContext.store('dialogSet', dialogSet);
    } catch (err) {
      Log.error(`window create failed! err: ${JSON.stringify(err)}.`);
      destruction(want, PermissionType.FAILED);
    };
  }
};

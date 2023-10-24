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
import { GlobalContext } from '../common/utils/globalContext';

const TAG = 'PermissionManager_Log:';
const BG_COLOR = '#00000000';

export default class GlobalExtensionAbility extends extension {
  /**
  * Lifecycle function, called back when a service extension is started for initialization.
  */
  onCreate(want): void {
    console.info(TAG + 'ServiceExtensionAbility onCreate, ability name is ' + want.abilityName);
    console.info(TAG + 'want: ' + JSON.stringify(want));

    GlobalContext.store('globalState', want.parameters['ohos.sensitive.resource']);
    GlobalContext.store('context', this.context);

    try {
      let dis = display.getDefaultDisplaySync();
      let navigationBarRect = {
        left: 0,
        top: 0,
        width: dis.width,
        height: dis.height
      };
      this.createWindow('globalDialog', window.WindowType.TYPE_VOICE_INTERACTION, navigationBarRect);
    } catch (exception) {
      console.error(TAG + 'Failed to obtain the default display object. Code: ' + JSON.stringify(exception));
    };
  }

  /**
  * Lifecycle function, called back when a service extension is started or recall.
  */
  onRequest(want, startId): void {
    console.info(TAG + 'ServiceExtensionAbility onRequest. start id is ' + startId);
  }

  /**
  * Lifecycle function, called back before a service extension is destroyed.
  */
  onDestroy(): void {
    console.info(TAG + 'ServiceExtensionAbility onDestroy.');
    let win = GlobalContext.load('globalWin');
    win.destroyWindow();
  }

  private async createWindow(name: string, windowType: number, rect): Promise<void> {
    console.info(TAG + 'create window');
    try {
      const win = await window.createWindow({ ctx: this.context, name, windowType });
      GlobalContext.store('globalWin', win);
      await win.moveWindowTo(rect.left, rect.top);
      await win.resize(rect.width, rect.height);
      await win.setUIContent('pages/globalSwitch');
      await win.setWindowBackgroundColor(BG_COLOR);
      await win.showWindow();
    } catch {
      console.info(TAG + 'window create failed!');
    }
  }
};
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
import { Want } from '@kit.AbilityKit';
import { Log } from '../common/utils/utils';
import { GlobalDialogModel } from './GlobalDialogModel';

let globalDialogModel: GlobalDialogModel = new GlobalDialogModel();
let globalWindow: window.Window | null;

export default class GlobalExtensionAbility extends extension {
  /**
  * Lifecycle function, called back when a service extension is started for initialization.
  */
  onCreate(want: Want): void {
    Log.info('ServiceExtensionAbility onCreate, ability name is ' + want.abilityName);

    if (!want.parameters) {
      return;
    }
    let resource: string = want.parameters['ohos.sensitive.resource'] as string ?? '';

    if (!globalDialogModel.permissionCheck()) {
      this.context?.terminateSelf();
      return;
    }

    if (!globalDialogModel.statusCheck(this.context, resource)) {
      this.context?.terminateSelf();
      return;
    }

    try {
      let dis = display.getDefaultDisplaySync();
      let navigationBarRect: display.Rect = {
        left: 0,
        top: 0,
        width: dis.width,
        height: dis.height
      };
      Log.info('want: ' + JSON.stringify(want));
      let property: Record<string, Object> = { 'globalState': resource };
      let storage: LocalStorage = new LocalStorage(property);
      globalDialogModel.createWindow(this.context, navigationBarRect, storage).then(window => {
        globalWindow = window;
      })
    } catch (exception) {
      Log.error('Failed to obtain the default display object. Code: ' + JSON.stringify(exception));
    };
  }

  /**
  * Lifecycle function, called back when a service extension is started or recall.
  */
  onRequest(want: Want, startId: number): void {
    Log.info('ServiceExtensionAbility onRequest. start id is ' + startId);
  }

  /**
  * Lifecycle function, called back before a service extension is destroyed.
  */
  onDestroy(): void {
    Log.info('ServiceExtensionAbility onDestroy.');
    globalWindow?.destroyWindow();
  }

};
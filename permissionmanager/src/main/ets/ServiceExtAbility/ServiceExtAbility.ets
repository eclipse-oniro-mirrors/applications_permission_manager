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
import display from '@ohos.display';
import deviceInfo from '@ohos.deviceInfo';
import { Want } from '@kit.AbilityKit';
import { Log } from '../common/utils/utils';
import { GrantDialogModel } from './GrantDialogModel';
import { GlobalContext } from '../common/utils/globalContext';

let grantDialogModel: GrantDialogModel = new GrantDialogModel();

export default class ServiceExtensionAbility extends extension {
  /**
  * Lifecycle function, called back when a service extension is started for initialization.
  */
  onCreate(want: Want): void {
    Log.info('ServiceExtensionAbility onCreate, ability name is ' + want.abilityName);
    GlobalContext.getContext().setAndGetWindowNum(0);
  }

  /**
  * Lifecycle function, called back when a service extension is started or recall.
  */
  onRequest(want: Want, startId: number): void {
    Log.info('ServiceExtensionAbility onRequest. start id is ' + startId);
    if (deviceInfo.deviceType === 'wearable') {
      this.context.terminateSelf();
      Log.info('ServiceExtensionAbility terminateSelf');
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
      grantDialogModel.createWindow(this.context, 'permissionDialog' + startId, navigationBarRect, want);
    } catch (exception) {
      Log.error('Failed to obtain the default display object. Code: ' + JSON.stringify(exception));
    };
  }

  /**
  * Lifecycle function, called back before a service extension is destroyed.
  */
  onDestroy(): void {
    Log.info('ServiceExtensionAbility onDestroy.');
  }

};
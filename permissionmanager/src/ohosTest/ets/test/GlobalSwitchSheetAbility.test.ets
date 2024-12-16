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

import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { Want } from '@kit.AbilityKit';
import { Log } from '../../../main/ets/common/utils/utils';
import GlobalSwitchSheetAbility from '../../../main/ets/PermissionSheet/GlobalSwitchSheetAbility';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';

let want: Want = {
  abilityName: '',
  parameters: {
    'ohos.sensitive.resource': 'microphone',
    'ohos.display.id': 0
  }
};

export default function GlobalSwitchSheetAbilityTest() {
  describe('GlobalSwitchSheetAbilityTest', () => {
    // Defines a test suite. Two parameters are supported: test suite name and test suite function.
    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
    })
    beforeEach(() => {
      // Presets an action, which is performed before each unit test case starts.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: preset action function.
    })
    afterEach(() => {
      // Presets a clear action, which is performed after each unit test case ends.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: clear action function.
    })
    afterAll(() => {
      // Presets a clear action, which is performed after all test cases of the test suite end.
      // This API supports only one parameter: clear action function.
    })

    it('GlobalSwitchSheetAbilityTest_000', 0, () => {
      Log.info(`GlobalSwitchSheetAbilityTest_000 begin`);
      let ability = new GlobalSwitchSheetAbility();
      let param: AbilityConstant.LaunchParam = {
        launchReason: 0,
        lastExitReason: 0,
        lastExitMessage: ''
      };
      ability.onCreate(param);
    })

    it('GlobalSwitchSheetAbilityTest_001', 0, () => {
      Log.info(`GlobalSwitchSheetAbilityTest_001 begin`);
      let ability = new GlobalSwitchSheetAbility();
      // let session = new UIExtensionContentSession();
      // ability.onSessionCreate(want, session);
    })

    it('GlobalSwitchSheetAbilityTest_002', 0, () => {
      Log.info(`GlobalSwitchSheetAbilityTest_002 begin`);
      let ability = new GlobalSwitchSheetAbility();
      ability.onForeground();
    })

    it('GlobalSwitchSheetAbilityTest_003', 0, () => {
      Log.info(`GlobalSwitchSheetAbilityTest_003 begin`);
      let ability = new GlobalSwitchSheetAbility();
      ability.onBackground();
    })

    it('GlobalSwitchSheetAbilityTest_004', 0, () => {
      Log.info(`GlobalSwitchSheetAbilityTest_004 begin`);
      let ability = new GlobalSwitchSheetAbility();
      ability.onSessionDestroy();
    })

    it('GlobalSwitchSheetAbilityTest_005', 0, () => {
      Log.info(`GlobalSwitchSheetAbilityTest_005 begin`);
      let ability = new GlobalSwitchSheetAbility();
      ability.onDestroy()
    })
  })
}
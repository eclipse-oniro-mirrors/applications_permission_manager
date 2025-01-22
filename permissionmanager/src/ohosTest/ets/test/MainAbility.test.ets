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

import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium'
import { Want } from '@kit.AbilityKit';
import { Log } from '../../../main/ets/common/utils/utils';
import MainAbility from '../../../main/ets/MainAbility/MainAbility';
import window from '@ohos.window';

let want: Want = {
  abilityName: '',
  parameters: {
    'ohos.sensitive.resource': 'microphone',
    'ohos.display.id': 0
  }
};

// let stage: window.WindowStage = window.createWindow();

export default function MainAbilityTest() {
  describe('MainAbilityTest', () => {
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

    it('MainAbilityTest_000', 0, () => {
      Log.info(`MainAbilityTest_000 begin`);
      let ability = new MainAbility();
      ability.onCreate(want, null);
    })

    it('MainAbilityTest_002', 0, () => {
      Log.info(`MainAbilityTest_002 begin`);
      let ability = new MainAbility();
      ability.onNewWant(want);
    })

    it('MainAbilityTest_003', 0, () => {
      Log.info(`MainAbilityTest_003 begin`);
      let ability = new MainAbility();
      ability.onForeground();
    })

    it('MainAbilityTest_004', 0, () => {
      Log.info(`MainAbilityTest_004 begin`);
      let ability = new MainAbility();
      ability.onBackground();
    })

    it('MainAbilityTest_005', 0, () => {
      Log.info(`MainAbilityTest_005 begin`);
      let ability = new MainAbility();
      ability.onWindowStageDestroy();
    })

    it('MainAbilityTest_006', 0, () => {
      Log.info(`MainAbilityTest_006 begin`);
      let ability = new MainAbility();
      ability.onDestroy();
    })
  })
}
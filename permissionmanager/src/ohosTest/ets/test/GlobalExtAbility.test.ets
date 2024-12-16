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
import GlobalExtensionAbility from '../../../main/ets/GlobalExtAbility/GlobalExtAbility';

let want1: Want = {
  abilityName: '',
  parameters: {
    'ohos.sensitive.resource': 'microphone'
  }
};

let want2: Want = {
  abilityName: '',
  parameters: {
    'ohos.sensitive.resource': 'camera'
  }
};

export default function GlobalExtAbilityTest() {
  describe('GlobalExtAbilityTest', () => {
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

    it('GlobalExtAbilityTest_000', 0, () => {
      Log.info(`GlobalExtAbilityTest_000 begin`);
      let ability = new GlobalExtensionAbility();
      ability.onCreate(want1);
    })

    it('GlobalExtAbilityTest_001', 0, () => {
      Log.info(`GlobalExtAbilityTest_001 begin`);
      let ability = new GlobalExtensionAbility();
      ability.onCreate(want2);
    })

    it('GlobalExtAbilityTest_002', 0, () => {
      Log.info(`GlobalExtAbilityTest_002 begin`);
      let ability = new GlobalExtensionAbility();
      ability.onRequest(want1, 1);
    })

    it('GlobalExtAbilityTest_003', 0, () => {
      Log.info(`GlobalExtAbilityTest_003 begin`);
      let ability = new GlobalExtensionAbility();
      ability.onDestroy();
    })
  })
}
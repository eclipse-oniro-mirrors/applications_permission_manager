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

import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect, TestType } from '@ohos/hypium';
import { Permission } from '../../../main/ets/common/model/definition';
import {
  Log,
  verifyAccessToken,
  titleTrim,
  getPermissionGroup,
  getPermissionGroupByName,
  checkPermissionGroup,
  getFontSizeScale
} from '../../../main/ets/common/utils/utils';
import { supportPermission } from '../../../main/ets/common/permissionGroupManager/bundlePermissionCollector';
import { abilityAccessCtrl, bundleManager } from '@kit.AbilityKit';

export default function utilsTest() {
  describe('utilsTest', () => {
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

    it('UtilsTest_000', TestType.FUNCTION, async () => {
      Log.info(`UtilsTest_000 begin`);
      let flag = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION;
      let bundleInfo = bundleManager.getBundleInfoForSelfSync(flag);
      let status = await verifyAccessToken(bundleInfo.appInfo.accessTokenId, 'ohos.permission.MICROPHONE');
      expect(status).assertEqual(abilityAccessCtrl.GrantStatus.PERMISSION_DENIED);
      let status1 = await verifyAccessToken(bundleInfo.appInfo.accessTokenId, 'ohos.permission.GET_BUNDLE_INFO');
      expect(status1).assertEqual(abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED);
    })

    it('UtilsTest_001', TestType.FUNCTION, () => {
      Log.info(`UtilsTest_001 begin`);
      let testUri = 'testTitle';
      let title = titleTrim(testUri);
      expect(title).assertEqual(testUri);
    })

    it('UtilsTest_005', TestType.FUNCTION, () => {
      Log.info(`UtilsTest_005 begin`);
      let testUri = Permission.MICROPHONE;
      let groupInfo = getPermissionGroup(testUri);
      expect(groupInfo.permissions).assertContain(testUri);
      let testUri1 = '';
      let groupInfo1 = getPermissionGroup(testUri1 as Permission);
      expect(groupInfo1.label).assertEqual('');
    })

    it('UtilsTest_006', TestType.FUNCTION, () => {
      Log.info(`UtilsTest_006 begin`);
      let testGroup = 'MICROPHONE';
      let groupInfo = getPermissionGroupByName(testGroup);
      expect(groupInfo?.name).assertEqual(testGroup);
      let testGroup1 = '';
      let groupInfo1 = getPermissionGroupByName(testGroup1);
      expect(groupInfo1).assertUndefined();
    })

    it('UtilsTest_010', TestType.FUNCTION, () => {
      Log.info(`UtilsTest_010 begin`);
      let testUri = [Permission.MICROPHONE];
      let groupName = checkPermissionGroup(testUri);
      expect(groupName).assertEqual('MICROPHONE');
      let testUri1 = [];
      let groupName1 = checkPermissionGroup(testUri1);
      expect(groupName1).assertEqual(null);
      let testUri2 = ['' as Permission];
      let groupName2 = checkPermissionGroup(testUri2);
      expect(groupName2).assertEqual(null);
    })

    it('UtilsTest_012', TestType.FUNCTION, () => {
      Log.info(`UtilsTest_012 begin`);
      let scale = getFontSizeScale();
      expect(scale).assertEqual(false);
    })

    it('UtilsTest_013', TestType.FUNCTION, () => {
      Log.info(`UtilsTest_013 begin`);
      let support = supportPermission();
      expect(support).assertContain(Permission.CAMERA);
    })

    // Screen capture group: CUSTOM_SCREEN_CAPTURE / ONSCREEN_AWARENESS / WINDOW_CAPTURE belong to one group.
    it('UtilsTest_014', TestType.FUNCTION, () => {
      Log.info(`UtilsTest_014 begin`);
      expect(checkPermissionGroup([Permission.WINDOW_CAPTURE])).assertEqual('CUSTOM_SCREEN_CAPTURE');
      expect(checkPermissionGroup([Permission.ONSCREEN_AWARENESS])).assertEqual('CUSTOM_SCREEN_CAPTURE');
      let groupInfo = getPermissionGroup(Permission.WINDOW_CAPTURE);
      expect(groupInfo.permissions).assertContain(Permission.CUSTOM_SCREEN_CAPTURE);
      expect(groupInfo.permissions).assertContain(Permission.ONSCREEN_AWARENESS);
      expect(groupInfo.permissions).assertContain(Permission.WINDOW_CAPTURE);
    })

    // Keyboard input assistance group: HOOK_KEY_EVENT / HOOK_INPUT_EVENT / INPUT_RECORDING belong to one group.
    it('UtilsTest_015', TestType.FUNCTION, () => {
      Log.info(`UtilsTest_015 begin`);
      expect(checkPermissionGroup([Permission.HOOK_INPUT_EVENT])).assertEqual('HOOK_INPUT_EVENT');
      expect(checkPermissionGroup([Permission.INPUT_RECORDING])).assertEqual('HOOK_INPUT_EVENT');
      let groupInfo = getPermissionGroup(Permission.INPUT_RECORDING);
      expect(groupInfo.permissions).assertContain(Permission.HOOK_KEY_EVENT);
      expect(groupInfo.permissions).assertContain(Permission.HOOK_INPUT_EVENT);
      expect(groupInfo.permissions).assertContain(Permission.INPUT_RECORDING);
    })
  })
}
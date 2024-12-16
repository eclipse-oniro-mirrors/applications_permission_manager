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
import { AppInfo } from '../../../main/ets/common/model/typedef';
import { Permission } from '../../../main/ets/common/model/definition';
import Constants from '../../../main/ets/common/utils/constant';
import {
  Log,
  verifyAccessToken,
  titleTrim,
  addLocalTag,
  getPermissionLabel,
  getPermissionGroup,
  getPermissionGroupByName,
  getGroupIdByPermission,
  checkPermissionGroup,
  getFontSizeScale
} from '../../../main/ets/common/utils/utils';
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
    })

    it('UtilsTest_001', TestType.FUNCTION, () => {
      Log.info(`UtilsTest_001 begin`);
      let testUri = 'testTitle';
      let title = titleTrim(testUri);
      expect(title).assertEqual(testUri);
    })

    it('UtilsTest_002', TestType.FUNCTION, async () => {
      Log.info(`UtilsTest_002 begin`);
      let flag = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION;
      let bundleInfo = bundleManager.getBundleInfoForSelfSync(flag);
      let reqPermissions: Array<Permission> = [];
      bundleInfo.reqPermissionDetails.forEach(item => {
        reqPermissions.push(item.name as Permission);
      });
      let info = new AppInfo(
        bundleInfo.name,
        bundleInfo.targetVersion,
        bundleInfo.appInfo.accessTokenId,
        '',
        bundleInfo.appInfo.iconId,
        bundleInfo.appInfo.iconResource,
        '',
        bundleInfo.appInfo.labelId,
        bundleInfo.appInfo.labelResource,
        reqPermissions,
        [],
        '',
        '',
        ''
      );
      addLocalTag(info);
    })

    it('UtilsTest_004', TestType.FUNCTION, () => {
      Log.info(`UtilsTest_004 begin`);
      let testUri = Permission.MICROPHONE;
      let label = getPermissionLabel(testUri);
      expect(JSON.stringify(label)).assertEqual(JSON.stringify($r('sys.string.ohos_lab_microphone')));
    })

    it('UtilsTest_005', TestType.FUNCTION, () => {
      Log.info(`UtilsTest_005 begin`);
      let testUri = Permission.MICROPHONE;
      let groupInfo = getPermissionGroup(testUri);
      expect(groupInfo.permissions).assertContain(testUri);
    })

    it('UtilsTest_006', TestType.FUNCTION, () => {
      Log.info(`UtilsTest_006 begin`);
      let testGroup = 'MICROPHONE';
      let groupInfo = getPermissionGroupByName(testGroup);
      expect(groupInfo.name).assertEqual(testGroup);
    })

    it('UtilsTest_007', TestType.FUNCTION, () => {
      Log.info(`UtilsTest_007 begin`);
      let testUri = Permission.MICROPHONE;
      let groupId = getGroupIdByPermission(testUri);
      expect(groupId).assertEqual(2);
    })

    it('UtilsTest_010', TestType.FUNCTION, () => {
      Log.info(`UtilsTest_010 begin`);
      let testUri = [Permission.MICROPHONE];
      let groupName = checkPermissionGroup(testUri);
      expect(groupName).assertEqual('MICROPHONE');
    })

    it('UtilsTest_012', TestType.FUNCTION, () => {
      Log.info(`UtilsTest_012 begin`);
      let scale = getFontSizeScale();
      expect(scale).assertEqual(false);
    })

    it('UtilsTest_013', TestType.FUNCTION, () => {
      Log.info(`UtilsTest_013 begin`);
      Log.warn(`UtilsTest_013 begin`);
      Log.debug(`UtilsTest_013 begin`);
      Log.error(`UtilsTest_013 begin`);
    })
  })
}
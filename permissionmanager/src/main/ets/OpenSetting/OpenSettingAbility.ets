/*
 * Copyright (c) 2026 Huawei Device Co., Ltd.
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
import UIExtensionAbility from '@ohos.app.ability.UIExtensionAbility';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import { BusinessError } from '@ohos.base';
import bundleManager from '@ohos.bundle.bundleManager';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import { DeviceUtil } from '../common/utils/deviceUtil';
import { Log } from '../common/utils/utils';
import Constants from '../common/utils/constant';
import { GlobalContext } from '../common/utils/globalContext';
import { AppInfo } from '../common/model/typedef';
import { Permission } from '../common/model/definition';
import { PermissionGroupManager } from '../common/permissionGroupManager/PermissionGroupManager';

/**
 * Get the target permission name from Want parameters by checking standard keys in priority order
 * and returning the first valid value.
 * @param want Want used to start the UIExtension, including permission request parameters
 * @returns The extracted target permission string, or an empty string if no valid permission is found
 */
function getTargetPermission(want: Want): string {
  // Prefer the standard system permission array and use the first permission.
  let permissions = want.parameters?.['ohos.user.setting.permission'] as string[] | undefined;
  if (permissions && permissions.length > 0) {
    return permissions[0];
  }
  // Then read the permission value from ohos.open.setting.permission.
  let openSettingPermission = want.parameters?.['ohos.open.setting.permission'] as string | undefined;
  if (openSettingPermission) {
    return openSettingPermission;
  }
  // Fall back to the custom permissionName parameter.
  let permissionName = want.parameters?.permissionName as string | undefined;
  if (permissionName) {
    return permissionName;
  }
  // Finally fall back to the custom permission parameter.
  let singlePermission = want.parameters?.permission as string | undefined;
  if (singlePermission) {
    return singlePermission;
  }
  // Return an empty string when no valid permission is found in any parameter.
  return '';
}

function returnManualSettingErrorCode(session: UIExtensionContentSession, code: number): void {
  session.terminateSelfWithResult({
    resultCode: code === Constants.MANUAL_SETTING_USER_OPENED ? 0 : -1,
    want: {
      parameters: {
        'ohos.open.setting.result_code': code,
        'ohos.user.setting.permission.result': [],
        // Distinguish permission results from error codes: result stores per-permission grant states
        // on success, while the legacy error_code remains for compatibility.
        'ohos.user.setting.error_code': code,
      }
    }
  });
}

export default class OpenSettingAbility extends UIExtensionAbility {
  onCreate(launchParam: AbilityConstant.LaunchParam): void {
    Log.info('OpenSettingAbility on create');
    if (DeviceUtil.isWearable()) {
      this.context.terminateSelf();
      Log.info('OpenSettingAbility terminateSelf');
    }
  }

  private async prepareSpecifiedApplication(bundleName: string): Promise<AppInfo | undefined> {
    const flag =
      bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION |
      bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_REQUESTED_PERMISSION;
    try {
      let bundleInfo = await bundleManager.getBundleInfo(bundleName, flag);
      let reqPermissions: Permission[] = [];
      bundleInfo.reqPermissionDetails.forEach(item => {
        reqPermissions.push(item.name as Permission);
      });
      return new AppInfo(
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
    } catch (error) {
      Log.error(`OpenSettingAbility prepareSpecifiedApplication failed: ${JSON.stringify(error)}`);
      return undefined;
    }
  }

  private async handleManualSettingRequest(want: Want, session: UIExtensionContentSession): Promise<void> {
    let callerBundleName = want.parameters?.['ohos.aafwk.param.callerBundleName'] as string ?? '';
    let targetPermission = getTargetPermission(want);
    Log.info(`OpenSettingAbility onSessionCreate bundleName=${callerBundleName}, targetPermission=${targetPermission}`);
    if (!targetPermission) {
      Log.error('OpenSettingAbility target permission is not declared');
      returnManualSettingErrorCode(session, Constants.MANUAL_SETTING_PERM_IS_NOT_DECLARED);
      return;
    }
    if (!callerBundleName) {
      Log.error('OpenSettingAbility caller bundle is not supported');
      returnManualSettingErrorCode(session, Constants.MANUAL_SETTING_PERM_IS_NOT_SUPPORTED);
      return;
    }
    let applicationInfo = await this.prepareSpecifiedApplication(callerBundleName);
    if (!applicationInfo) {
      returnManualSettingErrorCode(session, Constants.MANUAL_SETTING_PERM_IS_NOT_SUPPORTED);
      return;
    }
    let reqPermissions = applicationInfo.permissions as Permission[];
    let targetPermissionValue = targetPermission as Permissions;
    if (!reqPermissions.includes(targetPermissionValue as Permission)) {
      Log.error(`OpenSettingAbility target permission is not declared by bundle: ${targetPermission}`);
      returnManualSettingErrorCode(session, Constants.MANUAL_SETTING_PERM_IS_NOT_DECLARED);
      return;
    }
    if (!PermissionGroupManager.getInstance().isPermissionSupported(targetPermissionValue as Permission)) {
      Log.error(`OpenSettingAbility target permission is not supported on current device: ${targetPermission}`);
      returnManualSettingErrorCode(session, Constants.MANUAL_SETTING_PERM_IS_NOT_SUPPORTED);
      return;
    }
    let tokenId = applicationInfo.tokenId;
    let grantStatus = abilityAccessCtrl.createAtManager().verifyAccessTokenSync(tokenId, targetPermissionValue);
    if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
      Log.info(`OpenSettingAbility target permission is already granted: ${targetPermission}`);
      returnManualSettingErrorCode(session, Constants.MANUAL_SETTING_ALREADY_GRANTED);
      return;
    }
    GlobalContext.store('bundleName', callerBundleName);
    GlobalContext.store('manualSettingTargetPermission', targetPermission);
    GlobalContext.store('applicationInfo', applicationInfo);
    // Store the session under a dedicated key instead of globalThis.windowStage:
    // MainAbility of this process shares globalThis, and overwriting windowStage
    // would break its onNewWant routing (UIExtensionContentSession has no setUIContent).
    globalThis.openSettingSession = session;
    try {
      session.setWindowBackgroundColor('#00000000');
      await session.loadContent('pages/manual-setting-confirm');
    } catch (error) {
      let businessError = error as BusinessError;
      Log.error(`OpenSettingAbility load manual setting confirm failed: ${businessError.code} ${businessError.message}`);
      returnManualSettingErrorCode(session, Constants.MANUAL_SETTING_USER_REJECTED);
    }
  }

  onSessionCreate(want: Want, session: UIExtensionContentSession): void {
    this.handleManualSettingRequest(want, session).catch((error: BusinessError) => {
      Log.error(`OpenSettingAbility handle manual setting request failed: ${error.code} ${error.message}`);
      returnManualSettingErrorCode(session, Constants.MANUAL_SETTING_PERM_IS_NOT_SUPPORTED);
    });
  }

  onSessionDestroy(): void {
    Log.info('OpenSettingAbility onSessionDestroy');
  }

  onForeground(): void {
    Log.info('OpenSettingAbility onForeground');
  }

  onBackground(): void {
    Log.info('OpenSettingAbility onBackground');
  }

  onDestroy(): void | Promise<void> {
    Log.info('OpenSettingAbility onDestroy');
  }
}

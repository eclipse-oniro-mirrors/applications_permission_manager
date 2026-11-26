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
import window from '@ohos.window';
import display from '@ohos.display';
import uiExtensionHost from '@ohos.uiExtensionHost';
import { DeviceUtil } from '../common/utils/deviceUtil';
import { Log } from '../common/utils/utils';
import Constants from '../common/utils/constant';
import { GlobalContext } from '../common/utils/globalContext';
import { AppInfo } from '../common/model/typedef';
import { Permission } from '../common/model/definition';
import { PermissionGroupManager } from '../common/permissionGroupManager/PermissionGroupManager';

const CARRIER_WINDOW_TRANSPARENT_BG: string = '#00000000';

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
    resultCode: code === Constants.MANUAL_SETTING_USER_OPENED ||
      code === Constants.MANUAL_SETTING_ALREADY_GRANTED ? 1 : 0,
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
  private carrierWindow: window.Window | null = null;

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
    let grantStatus: number;
    try {
      grantStatus = abilityAccessCtrl.createAtManager().verifyAccessTokenSync(tokenId, targetPermissionValue);
    } catch (error) {
      let businessError = error as BusinessError;
      Log.error(`OpenSettingAbility verifyAccessToken failed, code: ${businessError.code}, message: ${businessError.message}`);
      grantStatus = abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;
    }
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
    // Safety hook so the page can destroy the carrier window even when the session
    // fails to terminate (prevents a leaked full-screen float window).
    globalThis.manualSettingDestroyCarrier = (): void => this.destroyCarrierWindow();
    // The session window is not always composited inside the caller's main window
    // (the same-layer splice may fail, in which case the fullscreen session window
    // displaces the caller's window and its transparent background exposes the
    // desktop). Load the confirm page into a carrier window bound to the caller's
    // window tree instead: host sub window first, then float window fallback,
    // following the proven pattern of PermissionStateSheetAbility.
    const carrierWindow = await this.createCarrierWindow(session);
    if (carrierWindow === null) {
      Log.error('OpenSettingAbility create carrier window failed');
      returnManualSettingErrorCode(session, Constants.MANUAL_SETTING_PERM_IS_NOT_SUPPORTED);
      this.context.terminateSelf();
      return;
    }
    this.carrierWindow = carrierWindow;
    try {
      await carrierWindow.loadContent('pages/manual-setting-confirm');
    } catch (error) {
      let businessError = error as BusinessError;
      Log.error(`OpenSettingAbility load manual setting confirm failed: ${businessError.code} ${businessError.message}`);
      returnManualSettingErrorCode(session, Constants.MANUAL_SETTING_USER_REJECTED);
      this.context.terminateSelf();
      return;
    }
    try {
      carrierWindow.setWindowBackgroundColor(CARRIER_WINDOW_TRANSPARENT_BG);
    } catch (error) {
      let businessError = error as BusinessError;
      Log.error(`OpenSettingAbility set window background failed, code: ${businessError.code}, message: ${businessError.message}`);
    }
    try {
      carrierWindow.setBackdropBlurStyle(window.BlurStyle.THICK);
    } catch (error) {
      let businessError = error as BusinessError;
      Log.error(
        `OpenSettingAbility set backdrop blur failed, code: ${businessError.code}, ` +
        `message: ${businessError.message}`
      );
    }
    await carrierWindow.showWindow();
  }

  /**
   * Create the window that actually carries the confirm page.
   * Prefer a modal sub window of the caller's main window (via the session host
   * window proxy); fall back to a full-screen float window when the sub window
   * creation is unavailable, so the transparent dialog always composites over
   * the caller's page instead of the desktop.
   */
  private async createCarrierWindow(session: UIExtensionContentSession): Promise<window.Window | null> {
    let carrierWindow = await this.createHostSubWindow(session);
    if (carrierWindow === null) {
      carrierWindow = await this.createFloatWindow(session);
    }
    if (carrierWindow === null) {
      return null;
    }
    try {
      let dis = display.getDefaultDisplaySync();
      await carrierWindow.resize(dis.width, dis.height);
    } catch (error) {
      let businessError = error as BusinessError;
      Log.error(
        `OpenSettingAbility resize carrier window failed, code: ${businessError.code}, ` +
        `message: ${businessError.message}`
      );
    }
    return carrierWindow;
  }

  /**
   * Create a modal sub window under the caller's main window.
   */
  private async createHostSubWindow(session: UIExtensionContentSession): Promise<window.Window | null> {
    try {
      let extensionWinProxy: uiExtensionHost.UIExtensionHostWindowProxy | undefined =
        session?.getUIExtensionHostWindowProxy();
      if (!extensionWinProxy) {
        Log.error('OpenSettingAbility extensionWinProxy is nullptr!');
        return null;
      }
      let subWindowOpts: window.SubWindowOptions = {
        title: '', decorEnabled: false, isModal: true,
      };
      let subWindow = await extensionWinProxy.createSubWindowWithOptions(
        'manualSettingSubWindowForHost' + Date(), subWindowOpts
      );
      Log.info('OpenSettingAbility create sub window success');
      return subWindow;
    } catch (error) {
      let businessError = error as BusinessError;
      Log.error(
        `OpenSettingAbility create sub window failed, code: ${businessError.code}, ` +
        `message: ${businessError.message}`
      );
      return null;
    }
  }

  /**
   * Fall back to a full-screen float window. The session window stays empty and
   * transparent so it never covers the float window content.
   */
  private async createFloatWindow(session: UIExtensionContentSession): Promise<window.Window | null> {
    try {
      let config: window.Configuration = {
        name: 'ManualSettingFloatWindow' + Date(),
        windowType: window.WindowType.TYPE_FLOAT,
        ctx: this.context
      };
      let floatWindow = await window.createWindow(config);
      session.loadContent('');
      session.setWindowBackgroundColor(CARRIER_WINDOW_TRANSPARENT_BG);
      Log.info('OpenSettingAbility create float window success');
      return floatWindow;
    } catch (error) {
      let businessError = error as BusinessError;
      Log.error(
        `OpenSettingAbility create float window failed, code: ${businessError.code}, ` +
        `message: ${businessError.message}`
      );
      return null;
    }
  }

  private destroyCarrierWindow(): void {
    try {
      this.carrierWindow?.destroyWindow();
    } catch (error) {
      let businessError = error as BusinessError;
      Log.error(
        `OpenSettingAbility destroy carrier window failed, code: ${businessError.code}, ` +
        `message: ${businessError.message}`
      );
    }
    this.carrierWindow = null;
  }

  onSessionCreate(want: Want, session: UIExtensionContentSession): void {
    this.handleManualSettingRequest(want, session).catch((error: BusinessError) => {
      Log.error(`OpenSettingAbility handle manual setting request failed: ${error.code} ${error.message}`);
      returnManualSettingErrorCode(session, Constants.MANUAL_SETTING_PERM_IS_NOT_SUPPORTED);
    });
  }

  onSessionDestroy(): void {
    Log.info('OpenSettingAbility onSessionDestroy');
    this.destroyCarrierWindow();
  }

  onForeground(): void {
    Log.info('OpenSettingAbility onForeground');
    this.carrierWindow?.showWindow();
  }

  onBackground(): void {
    Log.info('OpenSettingAbility onBackground');
    this.carrierWindow?.hide();
  }

  onDestroy(): void | Promise<void> {
    Log.info('OpenSettingAbility onDestroy');
    this.destroyCarrierWindow();
  }
}

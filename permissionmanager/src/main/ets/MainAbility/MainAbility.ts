/*
 * Copyright (c) 2021-2022 Huawei Device Co., Ltd.
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

import UIAbility from '@ohos.app.ability.UIAbility';
import bundleMonitor from '@ohos.bundle.bundleMonitor';
import account_osAccount from '@ohos.account.osAccount';
import { BundleInfoUtils, GlobalContext } from '../common/utils/globalContext';
import { abilityAccessCtrl, bundleManager, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

const TAG = 'PermissionManager_Log:';
const USER_ID = 100;
let callerBundleName: string;

export default class MainAbility extends UIAbility {
  // Window stage owned by this ability only. Never read globalThis.windowStage here:
  // UIExtension sessions of this process (e.g. OpenSettingAbility) may overwrite it,
  // and UIExtensionContentSession has no setUIContent API, which breaks routing.
  private winStage: window.WindowStage | undefined;
  /**
   * Update launch parameters by extracting and storing key configuration from the start want.
   * 1. Parse the caller bundle name and save it to the global variable.
   * 2. Store the bundle name in the global context for other pages.
   * 3. Store the target permission for the application permission page to navigate to.
   * @param want Want used to start the UIAbility, including launch parameters
   */
  private updateLaunchParams(want: Want): void {
    callerBundleName = want.parameters?.bundleName as string ?? '';
    GlobalContext.store('bundleName', callerBundleName);
    let targetPermission = callerBundleName ? want.parameters?.targetPermission as string ?? '' : '';
    GlobalContext.store('targetPermission', targetPermission);
  }

  /**
   * Load a page into the main window. WindowStage provides loadContent only
   * (setUIContent does not exist on it), and failures are logged instead of
   * being silently swallowed.
   */
  private loadPage(path: string): void {
    if (!this.winStage) {
      console.error(TAG + `loadPage ${path} failed: window stage is not ready`);
      return;
    }
    this.winStage.loadContent(path).catch((error) => {
      console.error(TAG + `loadContent ${path} failed: ` + JSON.stringify(error));
    });
  }

  onCreate(want, launchParam): void {
    console.log(TAG + 'MainAbility onCreate, ability name is ' + want.abilityName + '.');
    this.updateLaunchParams(want as Want);
  }

  onWindowStageCreate(windowStage): void {
    // Main window is created, set main page for this ability
    console.log(TAG + 'MainAbility onWindowStageCreate.');
    this.winStage = windowStage;
    globalThis.windowStage = windowStage;
    globalThis.isUIExtensionMode = false;
    globalThis.refresh = false;
    if (!this.permissionCheck()) {
      windowStage.loadContent('pages/transition');
      this.context.terminateSelf();
      return;
    }

    if (callerBundleName) {
      globalThis.currentApp = callerBundleName;
      this.getSpecifiedApplication(callerBundleName);
    } else {
      globalThis.currentApp = 'all';
      this.getAllApplications();
    }

    try {
      bundleMonitor.on('add', (bundleChangeInfo) => {
        console.log(`${TAG} bundleMonitor.add: ${JSON.stringify(bundleChangeInfo)}`);
        if (globalThis.currentApp === 'all') {
          this.getAllApplications();
          globalThis.refresh = true;
        }
      });
      bundleMonitor.on('remove', (bundleChangeInfo) => {
        console.log(`${TAG} bundleMonitor.remove: ${JSON.stringify(bundleChangeInfo)}`);
        if (globalThis.currentApp === 'all') {
          this.getAllApplications();
          globalThis.refresh = true;
        }
      });
      bundleMonitor.on('update', (bundleChangeInfo) => {
        console.log(`${TAG} bundleMonitor.update: ${JSON.stringify(bundleChangeInfo)}`);
        if (globalThis.currentApp === 'all') {
          this.getAllApplications();
          globalThis.refresh = true;
        }
      });
    } catch (error) {
      console.error(TAG + 'bundleMonitor failed.');
    }

  }

  onNewWant(want): void {
    console.log(TAG + 'MainAbility onNewWant. want: ' + JSON.stringify(want));
    // This ability is coming to the foreground, so its pages are not hosted by a UIExtension session.
    globalThis.isUIExtensionMode = false;

    let bundleName = want.parameters?.bundleName ? want.parameters.bundleName : 'all';
    this.updateLaunchParams(want as Want);
    if (globalThis.currentApp === 'all') {
      if (globalThis.currentApp !== bundleName) {
        console.log(TAG + 'MainAbility onNewWant. all -> app');
        this.loadPage('pages/transition');
        globalThis.currentApp = bundleName;
        GlobalContext.store('bundleName', bundleName);
        this.getSpecifiedApplication(bundleName);
      } else {
        if (globalThis.refresh === true) {
          this.loadPage('pages/transition');
          this.getAllApplications();
          globalThis.refresh = false;
        }
      }
    } else {
      if (bundleName === 'all') {
        console.log(TAG + 'MainAbility onNewWant. app -> all');
        this.loadPage('pages/transition');
        globalThis.currentApp = 'all';
        this.getAllApplications();
      } else {
        if (globalThis.currentApp !== bundleName) {
          console.log(TAG + 'MainAbility onNewWant. app -> app');
          this.loadPage('pages/transition');
          globalThis.currentApp = bundleName;
          GlobalContext.store('bundleName', bundleName);
          this.getSpecifiedApplication(bundleName);
        } else if (GlobalContext.load<string>('targetPermission')) {
          console.log(TAG + 'MainAbility onNewWant. app -> app permission detail');
          this.loadPage('pages/transition');
          this.getSpecifiedApplication(bundleName);
        }
      }
    }

  }

  onWindowStageDestroy(): void {
    try {
      bundleMonitor.off('add');
      bundleMonitor.off('remove');
      bundleMonitor.off('update');
      console.log(TAG + 'MainAbility onWindowStageDestroy.');
    } catch (err) {
      console.log(`errData is errCode:${err.code}  message:${err.message}`);
    }
  }

  onBackground(): void {
    console.log(TAG + ' onBackground.');
  }

  onDestroy(): void {
    console.log(TAG + ' onDestroy.');
  }

  onForeground(): void {
    console.log(TAG + ' onForeground.');
  }

  private permissionCheck(): boolean {
    try {
      let flag = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION;
      let bundleInfo = bundleManager.getBundleInfoForSelfSync(flag);
      let atManager = abilityAccessCtrl.createAtManager();
      let status =
        atManager.verifyAccessTokenSync(bundleInfo.appInfo.accessTokenId, 'ohos.permission.GET_INSTALLED_BUNDLE_LIST');
      if (status === abilityAccessCtrl.GrantStatus.PERMISSION_DENIED) {
        console.log(TAG + 'permission status is denied.');
        return false;
      }
      return true;
    } catch (err) {
      console.error(TAG + 'verifyAccessTokenSync failed.');
      return false;
    }
  }

  getAllApplications(): void {
    const flag =
      bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION |
      bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_REQUESTED_PERMISSION;
    let accountManager = account_osAccount.getAccountManager();
    try {
      accountManager.getActivatedOsAccountLocalIds((err, idArray: number[])=>{
        console.log(TAG + 'getActivatedOsAccountLocalIds err:' + JSON.stringify(err));
        console.log(TAG + 'getActivatedOsAccountLocalIds idArray: ' + JSON.stringify(idArray));
        let userId = idArray[0];
        bundleManager.getAllBundleInfo(flag, userId || USER_ID).then(async(bundleInfos) => {
          if (bundleInfos.length <= 0) {
            console.info(TAG + 'bundle.getAllBundleInfo result.length less than or equal to zero');
            this.context.terminateSelf();
            return;
          }
          let initialGroups = await BundleInfoUtils.filterBundleInfos(bundleInfos);
          let storage: LocalStorage = new LocalStorage({ 'initialGroups': initialGroups });
          this.winStage?.loadContent('pages/authority-management', storage);
        }).catch((error) => {
          console.error(TAG + 'bundle.getAllBundleInfo failed. Cause: ' + JSON.stringify(error));
          this.context.terminateSelf();
        });
      });
    } catch (e) {
      console.error(TAG + 'getActivatedOsAccountLocalIds exception: ' + JSON.stringify(e));
      this.context.terminateSelf();
    }
  }

  private async prepareSpecifiedApplication(bundleName: string): Promise<boolean> {
    const flag =
      bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION |
      bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_REQUESTED_PERMISSION;
    try {
      let bundleInfo;
      try {
        bundleInfo = await bundleManager.getBundleInfo(bundleName, flag);
      } catch (error) {
        console.error(TAG + 'Special branch getBundleInfo failed:' + JSON.stringify(error));
        return false;
      }
      let reqPermissions: Array<string> = [];
      bundleInfo.reqPermissionDetails.forEach(item => {
        reqPermissions.push(item.name);
      });
      let info = {
        'bundleName': bundleInfo.name,
        'api': bundleInfo.targetVersion,
        'tokenId': bundleInfo.appInfo.accessTokenId,
        'icon': '',
        'iconId': bundleInfo.appInfo.iconId,
        'iconResource': bundleInfo.appInfo.iconResource,
        'label': '',
        'labelId': bundleInfo.appInfo.labelId,
        'labelResource': bundleInfo.appInfo.labelResource,
        'permissions': reqPermissions,
        'groupId': [],
        'zhTag': '',
        'indexTag': '',
        'language': ''
      };
      GlobalContext.store('applicationInfo', info);
      return true;
    } catch (error) {
      console.error(TAG + 'Special branch failed: ' + JSON.stringify(error));
      return false;
    }
  }

  async getSpecifiedApplication(bundleName): Promise<void> {
    let result = await this.prepareSpecifiedApplication(bundleName);
    if (!result) {
      this.context.terminateSelf();
      return;
    }
    this.loadPage('pages/application-secondary');
  }
};

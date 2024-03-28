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
import bundleManager from '@ohos.bundle.bundleManager';
import bundleMonitor from '@ohos.bundle.bundleMonitor';
import account_osAccount from '@ohos.account.osAccount';
import { GlobalContext } from '../common/utils/globalContext';

const TAG = 'PermissionManager_Log:';
const USER_ID = 100;

export default class MainAbility extends UIAbility {
  onCreate(want, launchParam): void {
    console.log(TAG + 'MainAbility onCreate, ability name is ' + want.abilityName + '.');

    globalThis.bundleName = want.parameters.bundleName;
    GlobalContext.store('bundleName', want.parameters.bundleName);
    GlobalContext.store('context', this.context);
  }

  onWindowStageCreate(windowStage): void {
    // Main window is created, set main page for this ability
    console.log(TAG + 'MainAbility onWindowStageCreate.');
    globalThis.windowStage = windowStage;
    globalThis.refresh = false;

    if (globalThis.bundleName) {
      globalThis.currentApp = globalThis.bundleName;
      this.getSperifiedApplication(globalThis.bundleName);
    } else {
      globalThis.currentApp = 'all';
      this.getAllApplications();
    }
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
  }

  onNewWant(want): void {
    console.log(TAG + 'MainAbility onNewWant. want: ' + JSON.stringify(want));
    console.log(TAG + 'MainAbility onNewWant. bundleName: ' + JSON.stringify(want.parameters.bundleName));

    let bundleName = want.parameters.bundleName ? want.parameters.bundleName : 'all';
    if (globalThis.currentApp === 'all') {
      if (globalThis.currentApp !== bundleName) {
        console.log(TAG + 'MainAbility onNewWant. all -> app');
        globalThis.windowStage.setUIContent(this.context, 'pages/transition', null);
        globalThis.currentApp = bundleName;
        GlobalContext.store('bundleName', bundleName);
        this.getSperifiedApplication(bundleName);
      } else {
        if (globalThis.refresh === true) {
          globalThis.windowStage.setUIContent(this.context, 'pages/transition', null);
          this.getAllApplications();
          globalThis.refresh = false;
        }
      }
    } else {
      if (bundleName === 'all') {
        console.log(TAG + 'MainAbility onNewWant. app -> all');
        globalThis.windowStage.setUIContent(this.context, 'pages/transition', null);
        globalThis.currentApp = 'all';
        this.getAllApplications();
      } else {
        if (globalThis.currentApp !== bundleName) {
          console.log(TAG + 'MainAbility onNewWant. app -> app');
          globalThis.windowStage.setUIContent(this.context, 'pages/transition', null);
          globalThis.currentApp = bundleName;
          GlobalContext.store('bundleName', bundleName);
          this.getSperifiedApplication(bundleName);
        }
      }
    }

  }

  onWindowStageDestroy(): void {
    bundleMonitor.off('add');
    bundleMonitor.off('remove');
    console.log(TAG + 'MainAbility onWindowStageDestroy.');
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
            return;
          }
          let initialGroups = [];
          for (let i = 0; i < bundleInfos.length; i++) {
            let info = bundleInfos[i];
            // Filter blank icon icon and text label resources
            try {
              await bundleManager.queryAbilityInfo({
                bundleName: info.name,
                action: 'action.system.home',
                entities: ['entity.system.home']
              }, bundleManager.AbilityFlag.GET_ABILITY_INFO_WITH_APPLICATION);
            } catch (error) {
              console.error(
                TAG + 'queryAbilityByWant catch app: ' + JSON.stringify(info.name) + 'err: ' + JSON.stringify(error)
              );
              continue;
            }

            initialGroups.push(info);
          }
          let storage: LocalStorage = new LocalStorage({ 'initialGroups': initialGroups });
          globalThis.windowStage.loadContent('pages/authority-management', storage);
        }).catch((error) => {
          console.error(TAG + 'bundle.getAllBundleInfo failed. Cause: ' + JSON.stringify(error));
        });
      });
    } catch (e) {
      console.error(TAG + 'getActivatedOsAccountLocalIds exception: ' + JSON.stringify(e));
    }
  }

  getSperifiedApplication(bundleName): void {
    const flag =
      bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION |
      bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_REQUESTED_PERMISSION;
    bundleManager.getBundleInfo(bundleName, flag).then(bundleInfo => {
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
      globalThis.windowStage.setUIContent(this.context, 'pages/application-secondary', null);
    }).catch(() => {
      console.log(TAG + 'MainAbility getSperifiedApplication failed.');
      this.context.terminateSelf();
    });
  }
};

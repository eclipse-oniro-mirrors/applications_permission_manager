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
import account_osAccount from '@ohos.account.osAccount';

const TAG = 'PermissionManager_MainAbility:';
const USER_ID = 100;

export default class MainAbility extends UIAbility {
  onCreate(want, launchParam): void {
    console.log(TAG + 'MainAbility onCreate, ability name is ' + want.abilityName + '.');
  }

  onWindowStageCreate(windowStage): void {
    // Main window is created, set main page for this ability
    console.log(TAG + 'MainAbility onWindowStageCreate.');

    const flag = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION | bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_REQUESTED_PERMISSION;
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
              console.error(TAG + 'queryAbilityByWant catch app: ' + JSON.stringify(info.name) + 'err: ' + JSON.stringify(error));
              continue;
            }

            initialGroups.push(info);
          }
          let storage: LocalStorage = new LocalStorage({ 'initialGroups': initialGroups });
          windowStage.loadContent('pages/authority-management', storage);
        }).catch((error) => {
          console.error(TAG + 'bundle.getAllBundleInfo failed. Cause: ' + JSON.stringify(error));
        })
      });
    } catch (e) {
      console.error(TAG + 'getActivatedOsAccountLocalIds exception: ' + JSON.stringify(e));
    }
  }

  onForeground(): void {
    // Ability has brought to foreground
    console.log(TAG + 'MainAbility onForeground.');
  }

  onBackground(): void {
    // Ability has back to background
    console.log(TAG + 'MainAbility onBackground.');
  }

  onDestroy(): void {
    console.log(TAG + 'MainAbility onDestroy.');
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    console.log(TAG + 'MainAbility onWindowStageDestroy.');
  }
};

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

import UIAbility from '@ohos.app.ability.UIAbility'
import bundle from "@ohos.bundle";

var TAG = "PermissionManager_MainAbility:";
const PARMETER_BUNDLE_FLAG = 16;
const USERID = 100;
const noNeedDisplayApp: string[] = [
    "com.ohos.launcher"
]

export default class MainAbility extends UIAbility {
    onCreate(want, launchParam) {
        console.log(TAG + "MainAbility onCreate, ability name is " + want.abilityName + ".");
        globalThis.context = this.context;
        globalThis.allBundleInfo = [];
        globalThis.allUserPermissions = []
        globalThis.allGroups = []
        globalThis.permissionLabels = {}
        globalThis.initialGroups = []
    }

    onWindowStageCreate(windowStage) {
        // Main window is created, set main page for this ability
        console.log(TAG + "MainAbility onWindowStageCreate.");

        bundle.getAllBundleInfo(PARMETER_BUNDLE_FLAG).then(async(bundleInfos) => {
            if (bundleInfos.length <= 0) {
                console.info(TAG + 'bundle.getAllBundleInfo result.length less than or equal to zero');
                return;
            }
            for (let i = 0; i < bundleInfos.length; i++) {
                var info = bundleInfos[i];
                // Filter blank icon icon and text label resources
                try {
                    await bundle.queryAbilityByWant({
                        bundleName: info.name,
                        action: "action.system.home",
                        entities: ["entity.system.home"]
                    }, bundle.BundleFlag.GET_ABILITY_INFO_WITH_APPLICATION, USERID);
                } catch(e) {
                    console.log(TAG + 'queryAbilityByWant catch error: ' + JSON.stringify(e))
                    continue;
                }

                if (noNeedDisplayApp.indexOf(info.name) != -1) {
                    continue;
                }
                globalThis.initialGroups.push(info)
            }
            windowStage.setUIContent(this.context, "pages/authority-management", null);
        }).catch((error) => {
            console.error(TAG + 'bundle.getAllBundleInfo failed. Cause: ' + JSON.stringify(error));
        })
    }

    onForeground() {
        // Ability has brought to foreground
        console.log(TAG + "MainAbility onForeground.");
    }

    onBackground() {
        // Ability has back to background
        console.log(TAG + "MainAbility onBackground.");
    }

    onDestroy() {
        console.log(TAG + "MainAbility onDestroy.");
    }

    onWindowStageDestroy() {
        // Main window is destroyed, release UI related resources
        console.log(TAG + "MainAbility onWindowStageDestroy.");
    }
};

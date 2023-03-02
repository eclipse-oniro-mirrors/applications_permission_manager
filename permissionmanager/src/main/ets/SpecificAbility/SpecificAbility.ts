import hilog from '@ohos.hilog';
import UIAbility from '@ohos.app.ability.UIAbility'
import bundle from "@ohos.bundle"

const PARAMETER_BUNDLE_FLAG = 16;

export default class SpecificAbility extends UIAbility {
    onCreate(want, launchParam) {
        hilog.info(0x0000, 'SpecificAbility', '%{public}s', 'Ability onCreate');
        hilog.info(0x0000, 'SpecificAbility', '%{public}s', 'want param:' + JSON.stringify(want) ?? '');
        hilog.info(0x0000, 'SpecificAbility', '%{public}s', 'launchParam:' + JSON.stringify(launchParam) ?? '');

        globalThis.context = this.context;
        globalThis.permissionLabels = {}
        globalThis.bundleName = want.parameters['bundleName']
        globalThis.applicationInfo = {}
    }

    onDestroy() {
        hilog.info(0x0000, 'SpecificAbility', '%{public}s', 'Ability onDestroy');
    }

    onWindowStageCreate(windowStage) {
        // Main window is created, set main page for this ability
        hilog.info(0x0000, 'SpecificAbility', '%{public}s', 'Ability onWindowStageCreate');

        bundle.getBundleInfo(globalThis.bundleName, PARAMETER_BUNDLE_FLAG).then(bundleInfo => {
            let info = {
                'bundleName': bundleInfo.name,
                'api': bundleInfo.targetVersion,
                'tokenId': bundleInfo.appInfo.accessTokenId,
                'iconId': bundleInfo.appInfo.iconId,
                'labelId': bundleInfo.appInfo.labelId,
                'permissions': bundleInfo.reqPermissions,
                'groupId': [],
            }
            globalThis.applicationInfo = info
            windowStage.setUIContent(this.context, "pages/application-secondary", null);
        }).catch(() => {
            this.context.terminateSelf()
        })
    }

    onWindowStageDestroy() {
        // Main window is destroyed, release UI related resources
        hilog.info(0x0000, 'SpecificAbility', '%{public}s', 'Ability onWindowStageDestroy');
    }

    onForeground() {
        // Ability has brought to foreground
        hilog.info(0x0000, 'SpecificAbility', '%{public}s', 'Ability onForeground');
    }

    onBackground() {
        // Ability has back to background
        hilog.info(0x0000, 'SpecificAbility', '%{public}s', 'Ability onBackground');
    }
}

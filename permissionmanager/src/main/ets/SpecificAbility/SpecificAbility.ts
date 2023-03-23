import UIAbility from '@ohos.app.ability.UIAbility';
import bundle from '@ohos.bundle';

const PARAMETER_BUNDLE_FLAG = 16;

export default class SpecificAbility extends UIAbility {
  onCreate(want, launchParam): void {
    globalThis.context = this.context;
    globalThis.permissionLabels = {};
    globalThis.bundleName = want.parameters.bundleName;
    globalThis.applicationInfo = {};
  }

  onDestroy(): void {}

  onWindowStageCreate(windowStage): void {
    // Main window is created, set main page for this ability

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
      globalThis.applicationInfo = info;
      windowStage.setUIContent(this.context, "pages/application-secondary", null);
    }).catch(() => {
      this.context.terminateSelf();
    })
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
  }

  onForeground(): void {
    // Ability has brought to foreground
  }

  onBackground(): void {
    // Ability has back to background
  }
}

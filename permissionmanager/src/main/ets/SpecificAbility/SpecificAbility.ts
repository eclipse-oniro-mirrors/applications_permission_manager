import UIAbility from '@ohos.app.ability.UIAbility';
import bundle from '@ohos.bundle.bundleManager';
import { GlobalContext } from '../common/utils/globalContext';

export default class SpecificAbility extends UIAbility {
  onCreate(want): void {
    globalThis.bundleName = want.parameters.bundleName;
    GlobalContext.store('bundleName', want.parameters.bundleName);
  }

  onDestroy(): void {}

  onWindowStageCreate(windowStage): void {
    // Main window is created, set main page for this ability

    const flag = bundle.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION | bundle.BundleFlag.GET_BUNDLE_INFO_WITH_REQUESTED_PERMISSION;
    bundle.getBundleInfo(globalThis.bundleName, flag).then(bundleInfo => {
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
        'label': '',
        'labelId': bundleInfo.appInfo.labelId,
        'permissions': reqPermissions,
        'groupId': [],
        'zhTag': '',
        'indexTag': '',
        'language': ''
      };
      GlobalContext.store('applicationInfo', info);
      windowStage.setUIContent(this.context, 'pages/application-secondary', null);
    }).catch(() => {
      this.context.terminateSelf();
    });
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

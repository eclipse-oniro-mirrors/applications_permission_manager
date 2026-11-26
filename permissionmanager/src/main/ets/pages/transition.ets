/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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

import Constants from '../common/utils/constant';
import common from '@ohos.app.ability.common';
import window from '@ohos.window';
import bundleManager from '@ohos.bundle.bundleManager';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import { GlobalContext } from '../common/utils/globalContext';
import { Permission } from '../common/model/definition';
import { RouterParams3, AppInfo } from '../common/model/typedef';
import { getPermissionGroup, addLocalTag, Log } from '../common/utils/utils';
import {
  getRequestedPermissions,
  buildAppInfoFromBundleInfo
} from '../common/permissionGroupManager/bundlePermissionCollector';
import { resolveAppLabel, resolveAppIcon } from '../common/utils/resourceDisplayUtils';

const ICON_SIZE = 150;

@Entry
@Component
struct Transition {
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;

  aboutToAppear(): void {
    let targetPermission = GlobalContext.load<string>('targetPermission');
    if (!targetPermission) {
      return;
    }
    GlobalContext.store('targetPermission', '');
    this.buildApplicationDetailPage(targetPermission);
  }

  /**
   * Build the application data of the target permission and load the application
   * permission detail page directly, so only one page transition is visible.
   */
  private async buildApplicationDetailPage(targetPermission: string): Promise<void> {
    const flag =
      bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION |
      bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_REQUESTED_PERMISSION;
    let bundleName: string = GlobalContext.load<string>('bundleName');
    try {
      let displayPermission: Permission = targetPermission as Permission;
      let group = getPermissionGroup(displayPermission);
      let bundleInfo = await bundleManager.getBundleInfo(bundleName, flag);
      let reqPermissions: Permission[] = getRequestedPermissions(bundleInfo);
      let matched: Permission[] = reqPermissions.filter((permission: Permission) => permission === displayPermission);
      if (!matched.length) {
        Log.error(`Transition target permission is not declared by bundle: ${targetPermission}`);
        this.context.terminateSelf();
        return;
      }
      let info: AppInfo = buildAppInfoFromBundleInfo(bundleInfo, matched);
      info.label = await resolveAppLabel(this.context, info);
      info.icon = resolveAppIcon(this.context, info);
      addLocalTag(info);
      let status: number = Constants.PERMISSION_BAN;
      try {
        let grantStatus = abilityAccessCtrl.createAtManager().verifyAccessTokenSync(
          info.tokenId, displayPermission as Permissions
        );
        status = grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED ?
          Constants.PERMISSION_ALLOW : Constants.PERMISSION_BAN;
      } catch (error) {
        Log.error(`Transition verifyAccessToken failed: ${JSON.stringify(error)}`);
      }
      GlobalContext.store('applicationInfo', info);
      GlobalContext.store('currentPermissionGroup', group.name);
      GlobalContext.store('applicationTertiaryParams',
        new RouterParams3(bundleName, group.groupName, matched, status, info.tokenId));
      let winStage = globalThis.windowStage as window.WindowStage;
      winStage.loadContent('pages/application-tertiary').catch((error: Error) => {
        Log.error(`Transition loadContent failed: ${JSON.stringify(error)}`);
        this.context.terminateSelf();
      });
    } catch (error) {
      Log.error(`Transition buildApplicationDetailPage failed: ${JSON.stringify(error)}`);
      this.context.terminateSelf();
    }
  }

  build() {
    Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
      Image($r('app.media.app_icon'))
        .width(ICON_SIZE)
    }
    .width(Constants.FULL_WIDTH)
    .height(Constants.FULL_HEIGHT)
  }
}

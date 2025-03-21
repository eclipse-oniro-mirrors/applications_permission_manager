/*
 * Copyright (c) 2025 Huawei Device Co., Ltd.
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

import { BasePermissionStrategy } from '../base/BasePermissionStrategy';
import { PermissionUtils } from '../utils/permissionUtils';
import { Permission, PermissionGroup, PermissionOption } from '../model/definition';
import { PermissionGroupConfig, PermissionWithOption } from '../model/typedef';
import Constants from '../utils/constant';

const groupConfig: PermissionGroupConfig = new PermissionGroupConfig({
  groupName: PermissionGroup.ADS,
  permissions: [Permission.APP_TRACKING_CONSENT],
  icon: $r('app.media.track'),
  title: '',
  reason: '',
  buttonList: []
})

export class AdsStrategy extends BasePermissionStrategy {
  public override getPermissionGroupConfig(): PermissionGroupConfig {
    return groupConfig;
  }

  public override getGroupTitle(appName: string, locationFlag: number): ResourceStr {
    return $r('app.string.group_label_ADS', appName);
  }

  public override async preProcessingPermission(
    permission: Permission, tokenId: number
  ): Promise<PermissionWithOption[]> {
    let permissionWithOptionList: PermissionWithOption[] = [];
    if (!groupConfig.permissions.includes(permission)) {
      return [];
    }
    let isPermissionQueryEnabled = await PermissionUtils.isPermissionQueryEnabled(permission);
    if (!isPermissionQueryEnabled) {
      await PermissionUtils.grantPermissionWithResult(permission, Constants.PERMISSION_FLAG, tokenId);
      permissionWithOptionList.push({ permission, permissionOption: PermissionOption.GRANT });
    }
    return permissionWithOptionList;
  }
}
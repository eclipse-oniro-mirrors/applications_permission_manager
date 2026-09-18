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
import { Permission, PermissionGroup, ButtonStatus, PermissionOption } from '../model/definition';
import { CallerAppInfo, PermissionGroupConfig, PermissionWithOption } from '../model/typedef';
import common from '@ohos.app.ability.common';
import Constants from '../utils/constant';
import { DeviceUtil } from '../utils/deviceUtil';
import { PermissionUtils } from '../utils/permissionUtils';

const groupConfig: PermissionGroupConfig = new PermissionGroupConfig({
  groupName: PermissionGroup.PASTEBOARD,
  permissions: [Permission.READ_PASTEBOARD],
  icon: $r('app.media.ic_clipboard'),
  title: '',
  reason: '',
  buttonList: []
})

export class PasteboardStrategy extends BasePermissionStrategy {
  public override getPermissionGroupConfig(): PermissionGroupConfig {
    return groupConfig;
  }

  public override getGroupTitle(appName: string, locationFlag: number): ResourceStr {
    return $r('app.string.group_label_pasteboard', appName);
  }

  public override getButtonList(): ButtonStatus[] {
    return [ButtonStatus.THIS_TIME_ONLY, ButtonStatus.ALWAYS_ALLOW, ButtonStatus.DENY];
  }

  public override async preProcessingPermission(
    permission: Permission, tokenId: number
  ): Promise<PermissionWithOption[]> {
    if (!DeviceUtil.isPC() || !groupConfig.permissions.includes(permission)) {
      return [];
    }
    let result = await PermissionUtils.grantPermissionWithResult(permission, Constants.PERMISSION_FLAG, tokenId);
    if (result.operationResult !== Constants.RESULT_SUCCESS) {
      return [];
    }
    return [{ permission, permissionOption: PermissionOption.GRANT }];
  }

  public override getReasonByPermission(
    groupToPermissions: Permission[],
    permissions: Set<Permission>,
    context: common.ServiceExtensionContext,
    callerAppInfo: CallerAppInfo,
    pasteBoardName: string
  ): ResourceStr {
    if (pasteBoardName) {
      return $r('app.string.paste_board_app', pasteBoardName);
    } else {
      return $r('app.string.paste_board_desc');
    }
  }

}

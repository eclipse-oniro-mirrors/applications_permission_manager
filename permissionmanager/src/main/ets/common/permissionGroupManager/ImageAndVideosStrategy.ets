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
import { CallerAppInfo, PermissionGroupConfig } from '../model/typedef';
import { DeviceUtil } from '../utils/deviceUtil';

export class ImageAndVideosStrategy extends BasePermissionStrategy {
  public override getPermissionGroupConfig(): PermissionGroupConfig {
    return new PermissionGroupConfig({
      groupName: PermissionGroup.IMAGE_AND_VIDEOS,
      permissions: [Permission.READ_IMAGEVIDEO, Permission.WRITE_IMAGEVIDEO, Permission.MEDIA_LOCATION],
      icon: $r('app.media.ic_public_picture'),
      title: '',
      reason: '',
      buttonList: []
    });
  }

  public override getGroupTitle(appName: string, locationFlag: number): ResourceStr {
    return $r('app.string.group_label_image_and_videos', appName);
  }

  public override isSupport(permission: Permission): boolean {
    return DeviceUtil.isPhone() || DeviceUtil.isTablet() || DeviceUtil.isPC() || DeviceUtil.isTv();
  }

  public override grantHandle(
    permission: Permission, callerAppInfo: CallerAppInfo, locationFlag: number, buttonStatus: ButtonStatus
  ): PermissionOption {
    return this.isPermissionPendingGrant(permission, callerAppInfo) ? PermissionOption.GRANT : PermissionOption.SKIP;
  }

  public override denyHandle(
    permission: Permission, callerAppInfo: CallerAppInfo, locationFlag: number, buttonStatus: ButtonStatus
  ): PermissionOption {
    return this.isPermissionPendingGrant(permission, callerAppInfo) ? PermissionOption.REVOKE : PermissionOption.SKIP;
  }
}

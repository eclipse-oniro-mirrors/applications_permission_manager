/*
 * Copyright (c) 2026 Huawei Device Co., Ltd.
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
import { Permission, PermissionGroup } from '../model/definition';
import { PermissionGroupConfig } from '../model/typedef';
import { DeviceUtil } from '../utils/deviceUtil';

const groupConfig: PermissionGroupConfig = new PermissionGroupConfig({
  groupName: PermissionGroup.FOLDER,
  permissions: [
    Permission.READ_WRITE_DOWNLOAD_DIRECTORY,
    Permission.READ_WRITE_DESKTOP_DIRECTORY,
    Permission.READ_WRITE_DOCUMENTS_DIRECTORY,
    Permission.ACCESS_USER_FULL_DISK
  ],
  icon: $r('app.media.ic_public_folder'),
  title: '',
  reason: '',
  buttonList: []
})

export class FolderStrategy extends BasePermissionStrategy {
  public override getPermissionGroupConfig(): PermissionGroupConfig {
    return groupConfig;
  }

  public override getGroupTitle(appName: string, locationFlag: number): ResourceStr {
    return $r('app.string.group_label_folder', appName);
  }

  public override isSupport(permission: Permission): boolean {
    if (permission === Permission.ACCESS_USER_FULL_DISK) {
      return DeviceUtil.isPC();
    }
    return DeviceUtil.isPC() || DeviceUtil.isTablet();
  }
}

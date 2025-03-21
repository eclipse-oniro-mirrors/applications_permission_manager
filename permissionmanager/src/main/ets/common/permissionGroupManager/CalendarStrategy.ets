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
import { ButtonStatus, Permission, PermissionGroup, PermissionOption } from '../model/definition';
import { CallerAppInfo, PermissionGroupConfig } from '../model/typedef';

const groupConfig: PermissionGroupConfig = new PermissionGroupConfig({
  groupName: PermissionGroup.CALENDAR,
  permissions: [Permission.READ_CALENDAR, Permission.WRITE_CALENDAR, Permission.READ_WHOLE_CALENDAR, Permission.WRITE_WHOLE_CALENDAR],
  icon: $r('app.media.ic_public_calendar'),
  title: '',
  reason: '',
  buttonList: []
})

export class CalendarStrategy extends BasePermissionStrategy {
  public override getPermissionGroupConfig(): PermissionGroupConfig {
    return groupConfig;
  }

  public override getGroupTitle(appName: string, locationFlag: number): ResourceStr {
    return $r('app.string.group_label_calendar', appName);
  }

  public override getReadAndWrite(permissions: Set<Permission>): ResourceStr {
    let message: ResourceStr = '';
    let isRead: boolean = permissions.has(Permission.READ_CALENDAR);
    let isWrite: boolean = permissions.has(Permission.WRITE_CALENDAR);

    if (isRead) {
      message = $r('sys.string.ohos_lab_read_calendar');
    }
    if (isWrite) {
      message = $r('sys.string.ohos_lab_write_calendar');
    }
    if (isRead && isWrite) {
      message = '';
    }
    return message;
  }

  public override grantHandle(
    permission: Permission, callerAppInfo: CallerAppInfo, locationFlag: number, buttonStatus: ButtonStatus
  ): PermissionOption {
    if (this.isPermissionPendingGrant(permission, callerAppInfo)) {
      return PermissionOption.GRANT;
    }
    return PermissionOption.SKIP;
  }

  public override denyHandle(
    permission: Permission, callerAppInfo: CallerAppInfo, locationFlag: number, buttonStatus: ButtonStatus
  ): PermissionOption {
    if (this.isPermissionPendingGrant(permission, callerAppInfo)) {
      return PermissionOption.REVOKE;
    }
    return PermissionOption.SKIP;
  }
}
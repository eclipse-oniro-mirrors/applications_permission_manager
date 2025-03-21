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
import { Permission, PermissionGroup, ButtonStatus } from '../model/definition';
import { CallerAppInfo, PermissionGroupConfig } from '../model/typedef';
import common from '@ohos.app.ability.common';

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
    return [ButtonStatus.DENY, ButtonStatus.THIS_TIME_ONLY];
  }

  public override getReasonByPermission(
    groupToPermissions: Permission[],
    permissions: Set<Permission>,
    context: common.ServiceExtensionContext,
    callerAppInfo: CallerAppInfo,
    pasteBoardName: string
  ): ResourceStr {
    if (pasteBoardName) {
      return $r('app.string.pasteBoard_app', pasteBoardName);
    } else {
      return $r('app.string.pasteBoard_desc');
    }
  }
}
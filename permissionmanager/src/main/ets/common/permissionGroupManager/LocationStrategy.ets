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
import Constants from '../utils/constant';

const fuzzyMarks = [Constants.LOCATION_FUZZY, Constants.LOCATION_BOTH_FUZZY, Constants.LOCATION_BOTH_PRECISE];
const preciseMarks = [Constants.LOCATION_UPGRADE, Constants.LOCATION_BOTH_PRECISE];
const groupConfig: PermissionGroupConfig = new PermissionGroupConfig({
  groupName: PermissionGroup.LOCATION,
  permissions: [Permission.LOCATION_IN_BACKGROUND, Permission.APPROXIMATELY_LOCATION, Permission.LOCATION],
  icon: $r('app.media.ic_public_gps'),
  title: '',
  reason: '',
  buttonList: []
})

export class LocationStrategy extends BasePermissionStrategy {
  public override getPermissionGroupConfig(): PermissionGroupConfig {
    return groupConfig;
  }

  public override getGroupTitle(appName: string, locationFlag: number): ResourceStr {
    if (locationFlag == Constants.LOCATION_FUZZY) {
      return $r('app.string.access_general_location', appName);
    }
    if (locationFlag == Constants.LOCATION_UPGRADE) {
      return $r('app.string.fuzzy_to_exact', appName);
    }
    return $r('app.string.group_label_location', appName);
  }

  public override getButtonList(): ButtonStatus[] {
    return [ButtonStatus.ALLOW_ONLY_DURING_USE, ButtonStatus.ALLOW_THIS_TIME, ButtonStatus.CANCEL];
  }

  public override grantHandle(
    permission: Permission, callerAppInfo: CallerAppInfo, locationFlag: number, buttonStatus: ButtonStatus
  ): PermissionOption {
    let opt: PermissionOption = PermissionOption.SKIP;
    if (permission === Permission.APPROXIMATELY_LOCATION) {
      opt = this.handleFuzzyLocationGrant(callerAppInfo, locationFlag, buttonStatus);
    } else if (permission === Permission.LOCATION) {
      opt = this.handlePreciseLocationGrant(callerAppInfo, locationFlag, buttonStatus);
    } else {
      opt = PermissionOption.SKIP;
    }
    return opt;
  }

  public override denyHandle(
    permission: Permission, callerAppInfo: CallerAppInfo, locationFlag: number, buttonStatus: ButtonStatus
  ): PermissionOption {
    let opt: PermissionOption = PermissionOption.REVOKE;
    if ((locationFlag === Constants.LOCATION_UPGRADE) && (permission !== Permission.LOCATION)) {
      opt = PermissionOption.SKIP;
    }
    return opt;
  }

  private handleFuzzyLocationGrant(
    callerAppInfo: CallerAppInfo, locationFlag: number, buttonStatus: ButtonStatus
  ): PermissionOption {
    if (fuzzyMarks.includes(locationFlag)) {
      return PermissionOption.GRANT;
    } else {
      return PermissionOption.SKIP;
    }
  }

  private handlePreciseLocationGrant(
    callerAppInfo: CallerAppInfo, locationFlag: number, buttonStatus: ButtonStatus
  ): PermissionOption {
    if (preciseMarks.includes(locationFlag)) {
      return PermissionOption.GRANT;
    } else {
      return PermissionOption.SKIP;
    }
  }

}
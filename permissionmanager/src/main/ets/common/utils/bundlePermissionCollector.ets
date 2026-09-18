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

import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import bundleManager from '@ohos.bundle.bundleManager';
import { AppInfo } from '../model/typedef';
import { Permission } from '../model/definition';
import { userGrantPermissions } from '../model/permissionGroup';
import Constants from './constant';
import { getGroupIdByPermission, Log } from './utils';
import { PermissionGroupManager } from '../permissionGroupManager/PermissionGroupManager';

/**
 * Get the permissions that are supported for user management on the current device.
 * Kept here (not in utils.ets) to avoid a circular dependency between utils and PermissionGroupManager.
 */
export function supportPermission(): Permission[] {
  let permissionGroupManager = PermissionGroupManager.getInstance();
  return userGrantPermissions.filter(permission => {
    return permissionGroupManager.isPermissionSupported(permission);
  });
}

/**
 * Extract the raw declared permission list from BundleInfo.
 */
export function getRequestedPermissions(info: bundleManager.BundleInfo): Permission[] {
  let reqPermissions: Permission[] = [];
  info.reqPermissionDetails.forEach(item => {
    reqPermissions.push(item.name as Permission);
  });
  return reqPermissions;
}

/**
 * Determine whether a permission should be included in the user-manageable permission set.
 * @param supportPermissions Pre-computed supported permission list to avoid repeated filtering in loops
 */
export async function shouldCollectUserPermission(
  tokenId: number,
  permission: Permission,
  supportPermissions?: Permission[]
): Promise<boolean> {
  let supported = supportPermissions ?? supportPermission();
  if (supported.indexOf(permission) === -1) {
    return false;
  }
  try {
    let flag = await abilityAccessCtrl.createAtManager().getPermissionFlags(tokenId, permission);
    // Include the permission only when it is not granted with the system-fixed flag.
    return (flag & Constants.PERMISSION_SYSTEM_FIXED) === 0;
  } catch (err) {
    Log.error('GetPermissionFlags error: ' + JSON.stringify(err));
    return false;
  }
}

/**
 * Filter supported and user-manageable permissions for the app, optionally skipping precise location
 * when approximate location is not declared.
 */
export async function collectSupportedUserPermissions(
  tokenId: number,
  permissions: Permission[],
  skipLocationWithoutApprox: boolean = false
): Promise<Permission[]> {
  let reqUserPermissions: Permission[] = [];
  let supportPermissions = supportPermission();
  for (const permission of permissions) {
    if (
      skipLocationWithoutApprox &&
      permission === Permission.LOCATION &&
      !permissions.includes(Permission.APPROXIMATELY_LOCATION)
    ) {
      continue;
    }
    if (await shouldCollectUserPermission(tokenId, permission, supportPermissions)) {
      reqUserPermissions.push(permission);
    }
  }
  return reqUserPermissions;
}

/**
 * Build a deduplicated permission group ID array from the permission list.
 */
export function buildGroupIds(permissions: Permission[]): number[] {
  let groupIds: number[] = [];
  for (const permission of permissions) {
    let groupId = getGroupIdByPermission(permission);
    if (groupIds.indexOf(groupId) === -1) {
      groupIds.push(groupId);
    }
  }
  return groupIds;
}

/**
 * Build the AppInfo object used by the page from BundleInfo and the filtered permission set.
 */
export function buildAppInfoFromBundleInfo(
  info: bundleManager.BundleInfo,
  reqUserPermissions: Permission[]
): AppInfo {
  return new AppInfo(
    info.name,
    info.targetVersion,
    info.appInfo.accessTokenId,
    '',
    info.appInfo.iconId,
    info.appInfo.iconResource,
    info.appInfo.label,
    info.appInfo.labelId,
    info.appInfo.labelResource,
    reqUserPermissions,
    buildGroupIds(reqUserPermissions),
    '',
    '',
    ''
  );
}

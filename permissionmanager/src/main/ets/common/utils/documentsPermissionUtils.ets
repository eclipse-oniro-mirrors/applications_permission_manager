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
import { CheckboxInfo } from '../model/typedef';
import { Permission } from '../model/definition';
import Constants from './constant';
import { DeviceUtil } from './deviceUtil';

/**
 * Determine whether a document permission belongs to the "media only" branch.
 */
export function isDocumentsMediaPermission(permission: Permission): boolean {
  return permission === Permission.READ_MEDIA || permission === Permission.WRITE_MEDIA;
}

/**
 * Determine whether the permission belongs to the document access set.
 */
export function isDocumentsPermission(permission: Permission): boolean {
  return permission === Permission.READ_DOCUMENT ||
    permission === Permission.WRITE_DOCUMENT ||
    permission === Permission.READ_MEDIA ||
    permission === Permission.WRITE_MEDIA;
}

/**
 * Determine whether the permission belongs to the folder access set.
 */
export function isFolderPermission(permission: Permission): boolean {
  return permission === Permission.READ_WRITE_DOWNLOAD_DIRECTORY ||
    permission === Permission.READ_WRITE_DESKTOP_DIRECTORY ||
    permission === Permission.READ_WRITE_DOCUMENTS_DIRECTORY ||
    permission === Permission.ACCESS_USER_FULL_DISK;
}

/**
 * Determine whether the permission falls into the merged "documents and folders" display scope.
 */
export function isDocumentsOrFolderPermission(permission: Permission): boolean {
  if (isDocumentsPermission(permission)) {
    return true;
  }
  return shouldShowFolderPermissionSection() && isFolderPermission(permission);
}

/**
 * Filter document access permissions from the permission set.
 */
export function getDocumentsPermissions(permissions: Permission[]): Permission[] {
  return permissions.filter((permission) => isDocumentsPermission(permission));
}

/**
 * Determine whether the current permission set includes document-scope entries beyond media-only.
 */
export function hasDocumentAllFilesPermission(permissions: Permission[]): boolean {
  return getDocumentsPermissions(permissions).some((permission) => !isDocumentsMediaPermission(permission));
}

/**
 * Filter folder access permissions from the permission set.
 */
export function getFolderPermissions(permissions: Permission[]): Permission[] {
  return permissions.filter((permission) => isFolderPermission(permission));
}

/**
 * Determine whether the current device should show the PC/tablet folder detail control section.
 */
export function shouldShowFolderPermissionSection(): boolean {
  return DeviceUtil.isPC() || DeviceUtil.isTablet();
}

/**
 * Update the folder selection state array based on the granted permission result.
 */
export function updateFolderStatusByPermission(folderStatus: boolean[], permission: Permission): void {
  switch (permission) {
    case Permission.READ_WRITE_DOWNLOAD_DIRECTORY:
      folderStatus[0] = true;
      break;
    case Permission.READ_WRITE_DESKTOP_DIRECTORY:
      folderStatus[1] = true;
      break;
    case Permission.READ_WRITE_DOCUMENTS_DIRECTORY:
      folderStatus[2] = true;
      break;
    case Permission.ACCESS_USER_FULL_DISK:
      folderStatus[3] = true;
      break;
  }
}

/**
 * Compute the current document permission status and distinguish among all files, media only,
 * and denied.
 */
export function getDocumentsPermissionStatus(tokenId: number, permissions: Permission[]): number {
  let atManager = abilityAccessCtrl.createAtManager();
  let hasDocumentAllFiles = hasDocumentAllFilesPermission(permissions);
  let hasGrantedDocument = false;
  let hasGrantedMedia = false;
  for (const permission of permissions) {
    let access = atManager.verifyAccessTokenSync(tokenId, permission);
    if (access !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
      continue;
    }
    if (isDocumentsMediaPermission(permission)) {
      hasGrantedMedia = true;
    } else {
      hasGrantedDocument = true;
    }
  }
  if (hasGrantedDocument) {
    return Constants.PERMISSION_ALLOW;
  }
  if (!hasDocumentAllFiles && hasGrantedMedia) {
    return Constants.PERMISSION_ALLOW;
  }
  if (hasGrantedMedia) {
    return Constants.PERMISSION_DOCUMENT_MEDIA_ONLY;
  }
  return Constants.PERMISSION_BAN;
}

/**
 * Compute the two-state status used by the merged "documents and folders" entry on the list page.
 */
export function getMergedDocumentsAndFolderStatus(tokenId: number, permissions: Permission[]): number {
  let atManager = abilityAccessCtrl.createAtManager();
  for (const permission of permissions) {
    let access = atManager.verifyAccessTokenSync(tokenId, permission);
    if (access === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
      return Constants.PERMISSION_ALLOW;
    }
  }
  return Constants.PERMISSION_BAN;
}

/**
 * Compute the two-state status of the document access radio group on the merged detail page.
 */
export function getMergedDocumentsStatus(tokenId: number, permissions: Permission[]): number {
  let atManager = abilityAccessCtrl.createAtManager();
  for (const permission of getDocumentsPermissions(permissions)) {
    let access = atManager.verifyAccessTokenSync(tokenId, permission);
    if (access === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
      return Constants.PERMISSION_ALLOW;
    }
  }
  return Constants.PERMISSION_BAN;
}

/**
 * Map folder permissions to the label and index information required by the page checkboxes.
 */
export function getFolderCheckboxInfo(permission: Permission): CheckboxInfo {
  switch (permission) {
    case Permission.READ_WRITE_DOWNLOAD_DIRECTORY:
      return new CheckboxInfo($r('app.string.download_folder'), 0);
    case Permission.READ_WRITE_DESKTOP_DIRECTORY:
      return new CheckboxInfo($r('app.string.desktop_folder'), 1);
    case Permission.READ_WRITE_DOCUMENTS_DIRECTORY:
      return new CheckboxInfo($r('app.string.document_folder'), 2);
    case Permission.ACCESS_USER_FULL_DISK:
      return new CheckboxInfo($r('app.string.full_disk_folder'), 3);
    default:
      return new CheckboxInfo($r('app.string.download_folder'), 0);
  }
}

/**
 * Compute the displayed folder permission group status from the folder permission set and current
 * selection state.
 */
export function getFolderGroupStatus(permissions: Permission[], folderStatus: boolean[]): number {
  if (permissions.length === 0) {
    return Constants.PERMISSION_BAN;
  }
  if (permissions.includes(Permission.ACCESS_USER_FULL_DISK) && folderStatus[3]) {
    return Constants.PERMISSION_ALLOW;
  }
  let hasGrantedMedia = permissions.some((permission) => {
    switch (permission) {
      case Permission.READ_WRITE_DOWNLOAD_DIRECTORY:
        return folderStatus[0];
      case Permission.READ_WRITE_DESKTOP_DIRECTORY:
        return folderStatus[1];
      case Permission.READ_WRITE_DOCUMENTS_DIRECTORY:
        return folderStatus[2];
      default:
        return false;
    }
  });
  return hasGrantedMedia ? Constants.PERMISSION_FOLDER_MEDIA_ONLY : Constants.PERMISSION_BAN;
}

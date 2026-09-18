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

import { Permission, PermissionGroup } from '../model/definition';

const READ_WRITE_GROUPS: PermissionGroup[] = [
  PermissionGroup.CONTACTS,
  PermissionGroup.CALENDAR,
  PermissionGroup.IMAGE_AND_VIDEOS,
  PermissionGroup.AUDIOS
];

/**
 * Determine whether the current permission group uses separated read/write permissions.
 */
export function isReadWriteGroup(group: string | PermissionGroup): boolean {
  return READ_WRITE_GROUPS.includes(group as PermissionGroup);
}

/**
 * Determine whether the specified permission is a read permission in the current permission group.
 */
export function isReadPermission(group: string | PermissionGroup, permission: Permission): boolean {
  switch (group) {
    case PermissionGroup.CONTACTS:
      return permission === Permission.READ_CONTACTS;
    case PermissionGroup.CALENDAR:
      return permission === Permission.READ_CALENDAR || permission === Permission.READ_WHOLE_CALENDAR;
    case PermissionGroup.IMAGE_AND_VIDEOS:
      return permission === Permission.READ_IMAGEVIDEO || permission === Permission.MEDIA_LOCATION;
    case PermissionGroup.AUDIOS:
      return permission === Permission.READ_AUDIO;
    default:
      return false;
  }
}

/**
 * Determine whether the specified permission is a write permission in the current permission group.
 */
export function isWritePermission(group: string | PermissionGroup, permission: Permission): boolean {
  switch (group) {
    case PermissionGroup.CONTACTS:
      return permission === Permission.WRITE_CONTACTS;
    case PermissionGroup.CALENDAR:
      return permission === Permission.WRITE_CALENDAR || permission === Permission.WRITE_WHOLE_CALENDAR;
    case PermissionGroup.IMAGE_AND_VIDEOS:
      return permission === Permission.WRITE_IMAGEVIDEO;
    case PermissionGroup.AUDIOS:
      return permission === Permission.WRITE_AUDIO;
    default:
      return false;
  }
}

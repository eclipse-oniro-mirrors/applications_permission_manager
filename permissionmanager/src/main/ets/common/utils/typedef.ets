/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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
import { Permissions } from '@ohos.abilityAccessCtrl';

export class appInfo {
  bundleName: string
  api: number
  tokenId: number
  icon: ResourceStr | PixelMap
  iconId: number
  iconResource: Resource
  label: string
  labelId: number
  labelResource: Resource
  permissions: Permissions[]
  groupId: number[]
  zhTag: string
  indexTag: string
  language: string

  constructor(bundleName: string, api: number, tokenId: number, icon: ResourceStr | PixelMap, iconId: number, iconResource: Resource, label: string, labelId: number, labelResource: Resource, permissions: Permissions[], groupId: number[], zhTag: string, indexTag: string, language: string) {
    this.bundleName = bundleName
    this.api = api
    this.tokenId = tokenId
    this.icon = icon
    this.iconId = iconId
    this.iconResource = iconResource
    this.label = label
    this.labelId = labelId
    this.labelResource = labelResource
    this.permissions = permissions
    this.groupId = groupId
    this.zhTag = zhTag
    this.indexTag = indexTag
    this.language = language
  }
};

export class permissionApplications {
  permission: Permissions
  groupName: string
  bundleNames: string[]
  icon: ResourceStr

  constructor(permission: Permissions, groupName: string, bundleNames: string[], icon: ResourceStr) {
    this.permission = permission
    this.groupName = groupName
    this.bundleNames = bundleNames
    this.icon = icon
  }
};

export class groupPermission {
  group: string
  permissions: string[]
  groupName: ResourceStr
  icon: ResourceStr
  isShow:boolean

  constructor(group: string, permissions: string[], groupName: ResourceStr, icon: ResourceStr, isShow:boolean) {
    this.group = group
    this.permissions = permissions
    this.groupName = groupName
    this.icon = icon
    this.isShow = isShow
  }
};

export class ApplicationObj {
  label: string
  icon: ResourceStr | PixelMap
  index: number
  accessTokenId: number
  permission: Permissions
  zhTag: string
  indexTag: string
  language: string
  bundleName?: string
  constructor(label: string, icon: ResourceStr | PixelMap, index: number, accessTokenId: number, permission: Permissions, zhTag: string, indexTag: string, language: string, bundleName?: string,) {
    this.label = label
    this.icon = icon
    this.index = index
    this.accessTokenId = accessTokenId
    this.permission = permission
    this.zhTag = zhTag
    this.indexTag = indexTag
    this.language = language
    this.bundleName = bundleName
  }
}

export class CalendarObj {
  permissionName: string
  groupName: string
  label: ResourceStr
  index: number
  constructor(permissionName: string, groupName: string, label: ResourceStr, index: number) {
    this.permissionName = permissionName
    this.groupName = groupName
    this.label = label
    this.index = index
  }
}

export class MediaDocObj {
  name: Resource
  permissions: Array<Permissions>
  index: number
  constructor(name: Resource, permissions: Array<Permissions>, index: number) {
    this.name = name
    this.permissions = permissions
    this.index = index
  }
}

export class permissionObj {
  groupName: ResourceStr;
  permission: string[];
  group: string;
  constructor(groupName: ResourceStr, permission: string[], group: string) {
    this.groupName = groupName;
    this.permission = permission;
    this.group = group
  }
}

export class StringObj {
  morning: string
  afternoon: string
  constructor(morning: string, afternoon: string) {
    this.morning = morning
    this.afternoon = afternoon
  }
}

export class appInfoSimple {
  bundleName: string
  api: number
  tokenId: number
  icon: ResourceStr | PixelMap
  label: ResourceStr
  permissions: Array<string>
  groupId: Array<number>

  constructor(bundleName: string, api: number, tokenId: number, icon: ResourceStr | PixelMap, label: ResourceStr, permissions: Array<string>, groupId: Array<number>) {
    this.bundleName = bundleName
    this.api = api
    this.tokenId = tokenId
    this.icon = icon
    this.label = label
    this.permissions = permissions
    this.groupId = groupId
  }
}

export class param {
  icon: Resource
  label: Resource

  constructor(icon: Resource, label: Resource) {
    this.icon = icon
    this.label = label
  }
};

export class otherPermission {
  permissionLabel: ResourceStr
  permission: string

  constructor(permissionLabel: ResourceStr, permission: string) {
    this.permissionLabel = permissionLabel
    this.permission = permission
  }
}

export class PermissionInfo {
  permissionName: string
  groupName: string
  label: ResourceStr
  groupId: number
  enable_description_start?: ResourceStr
  enable_description_end?: ResourceStr
  forbidden_description?: ResourceStr

  constructor(permissionName: string, groupName: string, label: ResourceStr, groupId: number, enable_description_start?: ResourceStr, enable_description_end?: ResourceStr, forbidden_description?: ResourceStr,) {
    this.permissionName = permissionName;
    this.groupName = groupName;
    this.label = label;
    this.groupId = groupId;
    this.enable_description_start = enable_description_start;
    this.enable_description_end = enable_description_end;
    this.forbidden_description = forbidden_description;
  }
}

export class GroupInfo {
  name: string
  groupName: ResourceStr
  label: ResourceStr
  icon: ResourceStr
  description: Array<ResourceStr>
  reason: string
  permissions: Array<Permissions>
  isShow: boolean
  enable_description_start?: ResourceStr
  enable_description_end?: ResourceStr
  forbidden_description?: ResourceStr

  constructor(name: string, groupName: ResourceStr, label: ResourceStr, icon: ResourceStr, description: Array<ResourceStr>, reason: string, permissions: Array<Permissions>, isShow: boolean, enable_description_start?: ResourceStr, enable_description_end?: ResourceStr, forbidden_description?: ResourceStr) {
    this.name = name;
    this.groupName = groupName;
    this.label = label;
    this.icon = icon;
    this.description = description;
    this.reason = reason;
    this.permissions = permissions;
    this.isShow = isShow;
    this.enable_description_start = enable_description_start;
    this.enable_description_end = enable_description_end;
    this.forbidden_description = forbidden_description;
  }
}

export class appRecordInfo {
  groupName: ResourceStr
  icon: ResourceStr | PixelMap
  name: string
  api: number
  accessTokenId: number
  reqUserPermissions: string[]
  permissions: appGroupRecordInfo[]
  groupNames: ResourceStr[]
  groupIds: number[]
  appLastTime: number

  constructor(groupName: ResourceStr, icon: ResourceStr | PixelMap, name: string, api: number, accessTokenId: number, reqUserPermissions: string[], permissions: appGroupRecordInfo[], groupNames: ResourceStr[], groupIds: number[], appLastTime: number) {
    this.groupName = groupName
    this.icon = icon
    this.name = name
    this.api = api
    this.accessTokenId = accessTokenId
    this.reqUserPermissions = reqUserPermissions
    this.permissions = permissions
    this.groupNames = groupNames
    this.groupIds = groupIds
    this.appLastTime = appLastTime
  }
}

export class GroupRecordInfo {
  name: string
  groupName: ResourceStr
  label: ResourceStr
  icon: ResourceStr
  permissions: Array<Permissions>
  sum: number
  recentVisit: number

  constructor(name: string, groupName: ResourceStr, label: ResourceStr, icon: ResourceStr, permissions: Array<Permissions>, sum: number, recentVisit: number) {
    this.name = name;
    this.groupName = groupName;
    this.label = label;
    this.icon = icon;
    this.permissions = permissions;
    this.sum = sum;
    this.recentVisit = recentVisit;
  }
}

export class appGroupRecordInfo {
  name: string
  groupName: ResourceStr
  label: ResourceStr
  icon: ResourceStr
  count: number
  lastTime: number

  constructor(name: string, groupName: ResourceStr, label: ResourceStr, icon: ResourceStr, count: number, lastTime: number) {
    this.name = name;
    this.groupName = groupName;
    this.label = label;
    this.icon = icon;
    this.count = count;
    this.lastTime = lastTime;
  }
}

export class routerParams_1 {
  list: permissionApplications[]
  backTitle: ResourceStr
  group: string
  globalIsOn: boolean

  constructor(list: permissionApplications[], backTitle: ResourceStr, group: string, globalIsOn: boolean) {
    this.list = list
    this.backTitle = backTitle
    this.group = group
    this.globalIsOn = globalIsOn
  }
}

export class routerParams_2 {
  list: permissionApplications[]
  backTitle: ResourceStr
  permissionName: string

  constructor(list: permissionApplications[], backTitle: ResourceStr, permissionName: string) {
    this.list = list
    this.backTitle = backTitle
    this.permissionName = permissionName
  }
}

export class routerParams_3 {
  bundleName: string
  backTitle: ResourceStr
  permission: Permissions[]
  status: number
  tokenId: number

  constructor(bundleName: string, backTitle: ResourceStr, permission: Permissions[], status: number, tokenId: number) {
    this.bundleName = bundleName
    this.backTitle = backTitle
    this.permission = permission
    this.status = status
    this.tokenId = tokenId
  }
}

export class wantInfo {
  parameters: Object[]

  constructor(parameters: Object[]) {
    this.parameters = parameters
  }
}
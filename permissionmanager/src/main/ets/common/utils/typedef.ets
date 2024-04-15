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

export class AppInfo {
  public bundleName: string
  public api: number
  public tokenId: number
  public icon: ResourceStr | PixelMap
  public iconId: number
  public iconResource: Resource
  public label: string
  public labelId: number
  public labelResource: Resource
  public permissions: Permissions[]
  public groupId: number[]
  public zhTag: string
  public indexTag: string
  public language: string

  constructor(
    bundleName: string,
    api: number,
    tokenId: number,
    icon: ResourceStr | PixelMap,
    iconId: number,
    iconResource: Resource,
    label: string,
    labelId: number,
    labelResource: Resource,
    permissions: Permissions[],
    groupId: number[],
    zhTag: string,
    indexTag: string,
    language: string
  ) {
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

export class PermissionApplications {
  public permission: Permissions
  public groupName: string
  public bundleNames: string[]
  public icon: ResourceStr

  constructor(permission: Permissions, groupName: string, bundleNames: string[], icon: ResourceStr) {
    this.permission = permission
    this.groupName = groupName
    this.bundleNames = bundleNames
    this.icon = icon
  }
};

export class GroupPermission {
  public group: string
  public permissions: string[]
  public groupName: ResourceStr
  public icon: ResourceStr
  public isShow:boolean

  constructor(group: string, permissions: string[], groupName: ResourceStr, icon: ResourceStr, isShow:boolean) {
    this.group = group
    this.permissions = permissions
    this.groupName = groupName
    this.icon = icon
    this.isShow = isShow
  }
};

export class ApplicationObj {
  public label: string
  public icon: ResourceStr | PixelMap
  public index: number
  public accessTokenId: number
  public permission: Permissions
  public zhTag: string
  public indexTag: string
  public language: string
  public bundleName?: string

  constructor(
    label: string,
    icon: ResourceStr | PixelMap,
    index: number,
    accessTokenId: number,
    permission: Permissions,
    zhTag: string,
    indexTag: string,
    language: string,
    bundleName?: string
  ) {
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
  public permissionName: string
  public groupName: string
  public label: ResourceStr
  public index: number

  constructor(permissionName: string, groupName: string, label: ResourceStr, index: number) {
    this.permissionName = permissionName
    this.groupName = groupName
    this.label = label
    this.index = index
  }
}

export class MediaDocObj {
  public name: Resource
  public permissions: Array<Permissions>
  public index: number

  constructor(name: Resource, permissions: Array<Permissions>, index: number) {
    this.name = name
    this.permissions = permissions
    this.index = index
  }
}

export class PermissionObj {
  public groupName: ResourceStr;
  public permission: string[];
  public group: string;

  constructor(groupName: ResourceStr, permission: string[], group: string) {
    this.groupName = groupName;
    this.permission = permission;
    this.group = group
  }
}

export class StringObj {
  public morning: string
  public afternoon: string
  constructor(morning: string, afternoon: string) {
    this.morning = morning
    this.afternoon = afternoon
  }
}

export class AppInfoSimple {
  public bundleName: string
  public api: number
  public tokenId: number
  public icon: ResourceStr | PixelMap
  public label: ResourceStr
  public permissions: Array<string>
  public groupId: Array<number>

  constructor(
    bundleName: string,
    api: number,
    tokenId: number,
    icon: ResourceStr | PixelMap,
    label: ResourceStr,
    permissions: Array<string>,
    groupId: Array<number>
  ) {
    this.bundleName = bundleName
    this.api = api
    this.tokenId = tokenId
    this.icon = icon
    this.label = label
    this.permissions = permissions
    this.groupId = groupId
  }
}

export class Param {
  public icon: Resource
  public label: Resource
  public description: string

  constructor(icon: Resource, label: Resource, description: string) {
    this.icon = icon
    this.label = label
    this.description = description
  }
};

export class OtherPermission {
  public permissionLabel: ResourceStr
  public permission: string

  constructor(permissionLabel: ResourceStr, permission: string) {
    this.permissionLabel = permissionLabel
    this.permission = permission
  }
}

export class PermissionInfo {
  public permissionName: string
  public groupName: string
  public label: ResourceStr
  public groupId: number
  public enableDescription?: string
  public forbiddenDescription?: ResourceStr

  constructor(
    permissionName: string,
    groupName: string,
    label: ResourceStr,
    groupId: number,
    enableDescription?: string,
    forbiddenDescription?: ResourceStr
  ) {
    this.permissionName = permissionName;
    this.groupName = groupName;
    this.label = label;
    this.groupId = groupId;
    this.enableDescription = enableDescription;
    this.forbiddenDescription = forbiddenDescription;
  }
}

export class GroupInfo {
  public name: string
  public groupName: ResourceStr
  public label: ResourceStr
  public icon: ResourceStr
  public description: Array<ResourceStr>
  public reason: string
  public permissions: Array<Permissions>
  public isShow: boolean
  public enableDescription?: string
  public forbiddenDescription?: ResourceStr

  constructor(
    name: string,
    groupName: ResourceStr,
    label: ResourceStr,
    icon: ResourceStr,
    description: Array<ResourceStr>,
    reason: string,
    permissions: Array<Permissions>,
    isShow: boolean,
    enableDescription?: string,
    forbiddenDescription?: ResourceStr
  ) {
    this.name = name;
    this.groupName = groupName;
    this.label = label;
    this.icon = icon;
    this.description = description;
    this.reason = reason;
    this.permissions = permissions;
    this.isShow = isShow;
    this.enableDescription = enableDescription;
    this.forbiddenDescription = forbiddenDescription;
  }
}

export class AppRecordInfo {
  public groupName: ResourceStr
  public icon: ResourceStr | PixelMap
  public name: string
  public api: number
  public accessTokenId: number
  public reqUserPermissions: string[]
  public permissions: AppGroupRecordInfo[]
  public groupNames: ResourceStr[]
  public groupIds: number[]
  public appLastTime: number

  constructor(
    groupName: ResourceStr,
    icon: ResourceStr | PixelMap,
    name: string, api: number,
    accessTokenId: number,
    reqUserPermissions: string[],
    permissions: AppGroupRecordInfo[],
    groupNames: ResourceStr[],
    groupIds: number[],
    appLastTime: number
  ) {
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
  public name: string
  public groupName: ResourceStr
  public label: ResourceStr
  public icon: ResourceStr
  public permissions: Array<Permissions>
  public sum: number
  public recentVisit: number

  constructor(
    name: string,
    groupName: ResourceStr,
    label: ResourceStr,
    icon: ResourceStr,
    permissions: Array<Permissions>,
    sum: number,
    recentVisit: number
  ) {
    this.name = name;
    this.groupName = groupName;
    this.label = label;
    this.icon = icon;
    this.permissions = permissions;
    this.sum = sum;
    this.recentVisit = recentVisit;
  }
}

export class AppGroupRecordInfo {
  public name: string
  public groupName: ResourceStr
  public label: ResourceStr
  public icon: ResourceStr
  public count: number
  public lastTime: number

  constructor(
    name: string,
    groupName: ResourceStr,
    label: ResourceStr,
    icon: ResourceStr,
    count: number,
    lastTime: number
  ) {
    this.name = name;
    this.groupName = groupName;
    this.label = label;
    this.icon = icon;
    this.count = count;
    this.lastTime = lastTime;
  }
}

export class RouterParams1 {
  public list: PermissionApplications[]
  public backTitle: ResourceStr
  public group: string
  public globalIsOn: boolean

  constructor(list: PermissionApplications[], backTitle: ResourceStr, group: string, globalIsOn: boolean) {
    this.list = list
    this.backTitle = backTitle
    this.group = group
    this.globalIsOn = globalIsOn
  }
}

export class RouterParams2 {
  public list: PermissionApplications[]
  public backTitle: ResourceStr
  public permissionName: string

  constructor(list: PermissionApplications[], backTitle: ResourceStr, permissionName: string) {
    this.list = list
    this.backTitle = backTitle
    this.permissionName = permissionName
  }
}

export class RouterParams3 {
  public bundleName: string
  public backTitle: ResourceStr
  public permission: Permissions[]
  public status: number
  public tokenId: number

  constructor(bundleName: string, backTitle: ResourceStr, permission: Permissions[], status: number, tokenId: number) {
    this.bundleName = bundleName
    this.backTitle = backTitle
    this.permission = permission
    this.status = status
    this.tokenId = tokenId
  }
}

export class WantInfo {
  public parameters: Object[]

  constructor(parameters: Object[]) {
    this.parameters = parameters
  }
}

export class CheckboxInfo {
  public label: Resource
  public index: number

  constructor(label: Resource, index: number) {
    this.label = label
    this.index = index
  }
}
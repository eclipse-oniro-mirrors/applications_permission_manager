/*
 * Copyright (c) 2021-2023 Huawei Device Co., Ltd.
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

import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import i18n from '@ohos.i18n';
import hilog from '@ohos.hilog';
import { permissionGroups, groups } from '../model/permissionGroup';
import Constants from '../utils/constant';
import { BundleInfoUtils } from './bundleInfoUtils';
import { CommonUtils } from './commonUtils';
import { GroupInfo, AppInfo, ApplicationObj, PermissionInfo } from './typedef';
import systemParameterEnhance from '@ohos.systemParameterEnhance';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import uiExtensionHost from '@ohos.uiExtensionHost';
import window from '@ohos.window';
import { GlobalContext } from './globalContext';

const TAG = 'PermissionManager_Log '

/**
 * verify permission
 * @param {Number} accessTokenId
 * @param {String} permission permission name
 */
export function verifyAccessToken(accessTokenId: number, permission: Permissions) {
  return new Promise<number>((resolve) => {
    let atManager = abilityAccessCtrl.createAtManager();
    let data = atManager.verifyAccessTokenSync(accessTokenId, permission);
    if (data == abilityAccessCtrl.GrantStatus.PERMISSION_DENIED) {
      resolve(data);
    } else {
      try {
        atManager.getPermissionFlags(accessTokenId, permission).then((flag: number) => {
          if (flag == Constants.PERMISSION_COMPONENT_SET) {
            resolve(abilityAccessCtrl.GrantStatus.PERMISSION_DENIED);
          } else {
            resolve(data);
          }
        })
      } catch (err) {
        Log.error('getPermissionFlags error: ' + JSON.stringify(err));
        resolve(data);
      }
    }
  })
}

/**
 * Omit display when application name is too long
 * @param {String} Application name
 */
export function titleTrim(title: string): string {
  const length: number = title.length;
  if (length > Constants.MAXIMUM_HEADER_LENGTH) {
    let str = '';
    str = title.substring(0, Constants.MAXIMUM_HEADER_LENGTH) + '...';
    return str;
  } else {
    return title;
  }
}

export const indexValue: string[] = [
  '#',
  'A',
  'B',
  'C',
  'D',
  'E',
  'F',
  'G',
  'H',
  'I',
  'J',
  'K',
  'L',
  'M',
  'N',
  'O',
  'P',
  'Q',
  'R',
  'S',
  'T',
  'U',
  'V',
  'W',
  'X',
  'Y',
  'Z'
]; // Array of alphabetically indexed names

export function addLocalTag(info: AppInfo) {
  let isZh = i18n.System.getSystemLanguage().indexOf('zh') >= 0;
  let appName: string = info.label;
  let upperCase = CommonUtils.isEmpty(appName) ? '' : appName[0].toLocaleUpperCase();
  let regexEn: RegExp = new RegExp('[A-Z]');
  let regexNm: RegExp = new RegExp('[0-9]');

  if (isZh) {
    if (upperCase.match(regexEn)) {
      info.zhTag = BundleInfoUtils.getStringZh(appName);
      info.indexTag = upperCase;
      info.language = 'EN';
    } else {
      info.zhTag = appName;
      info.language = 'CN';
      if (upperCase.match(regexNm)) {
        info.indexTag = '#';
      } else {
        info.indexTag = BundleInfoUtils.findZhIndex(upperCase);
      }
    }
  } else {
    if (upperCase.match(regexEn)) {
      info.zhTag = appName;
      info.indexTag = upperCase;
      info.language = 'EN';
    } else {
      info.zhTag = appName;
      info.indexTag = '#';
      info.language = 'CN';
    }
  }
}

let enComparator = new Intl.Collator('en');
let zhComparator = new Intl.Collator('zh-Hans-CN');

export function sortByName(appArray: Array<AppInfo | ApplicationObj>): Array<AppInfo | ApplicationObj> {
  return appArray.sort((item1: AppInfo | ApplicationObj, item2: AppInfo | ApplicationObj) => {
    if (item1.indexTag !== item2.indexTag) {
      return enComparator.compare(item1.indexTag, item2.indexTag);
    }

    let isEn1 = item1.language === 'EN';
    let isEn2 = item2.language === 'EN';

    if (isEn1 && isEn2) {
      return enComparator.compare(item1.label, item2.label);
    } else if (isEn1 && !isEn2) {
      return 1;
    } else if (!isEn1 && isEn2) {
      return -1;
    } else {
      return zhComparator.compare(item1.zhTag, item2.zhTag);
    }
  })
}

/**
 * Get permission label
 * @param {String} permission name
 */
export function getPermissionLabel(permission: string): ResourceStr {
  for (let i = 0; i < permissionGroups.length; i++) {
    if (permissionGroups[i].permissionName == permission) {
      return permissionGroups[i].label
    }
  }
  return '';
}

/**
 * Get the corresponding permission group id according to the permission
 * @param {String} permission app name id
 * @return {GroupInfo} group
 */
export function getPermissionGroup(permission: string): GroupInfo {
  for (let i = 0; i < permissionGroups.length; i++) {
    if (permissionGroups[i].permissionName == permission) {
      return groups[permissionGroups[i].groupId];
    }
  }
  return groups[0];
}

/**
 * Obtain a permission group by its name
 * @param {String} group name
 * @return {GroupInfo} group
 */
export function getPermissionGroupByName(name: string): GroupInfo {
  for (let i = 0; i < groups.length; i++) {
    if (groups[i].name === name) {
      return groups[i];
    }
  }
  return groups[0];
}

/**
 * Obtain the permission group ID by permission name
 * @param {String} permission name
 * @return {number} groupId
 */
export function getGroupIdByPermission(permission: string): number {
  for (let i = 0; i < permissionGroups.length; i++) {
    if (permissionGroups[i].permissionName === permission) {
      return permissionGroups[i].groupId;
    }
  }
  return 0;
}

export function PermissionDialogException(code: number, session: UIExtensionContentSession): void {
  session.terminateSelfWithResult({
    resultCode: -1,
    want: {
      parameters: {
        'ohos.user.setting.permission.result': [],
        'ohos.user.setting.error_code': code,
      }
    }
  })
}

export function PermissionDialogReturn(resultArray: Array<number>, session: UIExtensionContentSession): void {
  session.terminateSelfWithResult({
    resultCode: 0,
    want: {
      parameters: {
        'ohos.user.setting.permission.result': resultArray,
        'ohos.user.setting.error_code': 0
      }
    }
  })
}

// check if the permissions provided are in the same group
export function checkPermissionGroup(appPermissions: Permissions[]): string | null {
  if (appPermissions.length == 0) {
    return null;
  }
  let groupName = '' // index of group in permissionGroup
  // check if permission is a valid permission
  for (const permission of appPermissions) {
    let idx = permissionGroups.findIndex(
      (item) => {return item.permissionName === permission}
    );
    // if permission not found in known permissions , return false
    if (idx == -1) {
      Log.error(TAG + 'unknown info ' + permission)
      return null;
    }
    // if groupName not set , set groupName
    if (groupName == '') {
      groupName = permissionGroups[idx].groupName;
    }
    // if current groupName is not the same to the previous , not the same group
    if (permissionGroups[idx].groupName != groupName) {
      Log.error(TAG + 'permission ' + permission + ' is not in current group ' + groupName)
      return null
    }
  }
  return groupName;
}

export function  setAvoidArea(proxy: uiExtensionHost.UIExtensionHostWindowProxy) {
  let avoidArea = proxy.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
  let btmAvoidHeight: string = avoidArea.bottomRect.height.toString();
  Log.info(TAG + 'avoid area height: ' + btmAvoidHeight + 'px'); // assure unit in pixels
  GlobalContext.store('avoidAreaHeight', btmAvoidHeight + 'px');
}

export function getFontSizeScale(): number {
  const FONT_SIZE_SCALE_PARAM = 'persist.sys.font_scale_for_user0';
  let fontSizeScale = Number.parseFloat(systemParameterEnhance.getSync(FONT_SIZE_SCALE_PARAM, '1'));
  return fontSizeScale;
}

export function getLimitFontSize(
    fontSizeScale: number, maxScale: number, resMin: Resource, resMax: Resource
): number | string {
  if (fontSizeScale <= 1) {
    return px2vp(getContext().resourceManager.getNumber(resMin.id));
  }
  let fontSize = px2vp(getContext().resourceManager.getNumber(resMax.id));
  return fontSizeScale > maxScale ? `${fontSize * maxScale}vp` : fontSize;
}


export class Log {
  public static domain: number = 0x8214;
  public static tag: string = 'PermissionManager_Log';

  public static debug(message: string): void {
    hilog.debug(Log.domain, Log.tag, message);
  }

  public static info(message: string): void {
    hilog.info(Log.domain, Log.tag, message);
  }

  public static warn(message: string): void {
    hilog.warn(Log.domain, Log.tag, message);
  }

  public static error(message: string): void {
    hilog.error(Log.domain, Log.tag, message);
  }
}
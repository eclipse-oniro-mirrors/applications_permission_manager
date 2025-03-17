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

import { Permission, ButtonStatus, PermissionOption } from '../model/definition';
import { PermissionGroupConfig, CallerAppInfo, PermissionWithOption } from '../model/typedef';
import { Log } from '../utils/utils';
import common from '@ohos.app.ability.common';

export abstract class BasePermissionStrategy {
  /**
   * 获取权限组配置
   * return 权限组配置
   */
  public abstract getPermissionGroupConfig(): PermissionGroupConfig;

  /**
   * 获取权限组标题
   * @param appName 应用名
   * @param locationFlag 位置权限状态
   * return 标题
   */
  public abstract getGroupTitle(appName: string, locationFlag: number): ResourceStr;

  /**
   * 获取读写信息
   * @param permissions 授权权限
   * return 按钮列表
   */
  public getReadAndWrite(permissions: Set<Permission>): ResourceStr {
    return '';
  }

  /**
   * 根据待申请的权限获取授权理由
   * @param groupToPermissions 权限组内所有权限
   * @param permissions 授权权限
   * @param context 上下文信息
   * @param callerAppInfo 调用方信息
   * @param pasteBoardName 剪贴板信息
   * return reason
   */
  public getReasonByPermission(
    groupToPermissions: Permission[],
    permissions: Set<Permission>,
    context: common.ServiceExtensionContext,
    callerAppInfo: CallerAppInfo,
    pasteBoardName: string
  ): ResourceStr {
    let reason: string = '';
    groupToPermissions.forEach(perm => {
      if (!permissions.has(perm)) {
        return;
      }
      let permissionDetail = callerAppInfo.reqPermsDetails.find(item => item.name === perm);
      if (permissionDetail === undefined) {
        return;
      }
      try {
        let moduleContext: Context = context.createModuleContext(callerAppInfo.bundleName, permissionDetail.moduleName);
        let value = moduleContext.resourceManager.getStringSync(permissionDetail.reasonId);
        if (value && reason === '') {
          reason = value;
          return;
        }
      } catch (error) {
        Log.error(`get reason faild, code: ${error.code}, message: ${error.message}.`);
      }
    })
    return reason || '';
  }

  /**
   * 获取权限组按钮列表
   * return 按钮列表
   */
  public getButtonList(): ButtonStatus[] {
    return [ButtonStatus.DENY, ButtonStatus.ALLOW];
  }

  /**
   * 区分设备是否支持
   * @param permission 权限
   * return
   */
  public isSupport(permission: Permission): boolean {
    return true;
  }

  /**
   * 授权操作
   * @param permission 权限
   * @param callerAppInfo 调用方信息
   * @param locationFlag 位置权限组flag
   * @param buttonStatus
   * return
   */
  public grantHandle(
    permission: Permission, callerAppInfo: CallerAppInfo, locationFlag: number, buttonStatus: ButtonStatus
  ): PermissionOption {
    return PermissionOption.GRANT;
  }

  /**
   * 禁止操作
   * @param permission 权限
   * @param callerAppInfo 调用方信息
   * @param locationFlag 位置权限组flag
   * @param buttonStatus
   * return
   */
  public denyHandle(
    permission: Permission, callerAppInfo: CallerAppInfo, locationFlag: number, buttonStatus: ButtonStatus
  ): PermissionOption {
    return PermissionOption.REVOKE;
  }

  /**
   * 判断当前权限是否为申请权限
   * @param permission 权限
   * @param callerAppInfo 调用方信息
   * return
   */
  public isPermissionPendingGrant(permission: Permission, callerAppInfo: CallerAppInfo): boolean {
    let isPendingPermission: boolean = false;
    if (callerAppInfo.reqPerms.includes(permission)) {
      isPendingPermission = true;
    }
    return isPendingPermission;
  }

  /**
   * 预处理权限
   * @param permission 权限
   * @param tokenId 应用token
   * return
   */
  public async preProcessingPermission(permission: Permission, tokenId: number): Promise<PermissionWithOption[]> {
    return [];
  }

}
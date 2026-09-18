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

import { Permission } from '../model/definition';
import { optionAndState } from '../model/typedef';
import { Log } from '../utils/utils';
import Constants from '../utils/constant';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';

export class PermissionUtils {
  /**
   * 获取权限的弹窗开关状态
   * @param permission 权限
   * return
   */
  public static async isPermissionQueryEnabled(permission: Permission): Promise<boolean> {
    let atManager = abilityAccessCtrl.createAtManager();
    try {
      let result = await atManager.getPermissionRequestToggleStatus(permission);
      Log.info(`permissionRequestToggleStatus is ${result}.`);
      return result === abilityAccessCtrl.PermissionRequestToggleStatus.OPEN;
    } catch (error) {
      Log.error(`getPermissionRequestToggleStatus failed, code: ${error.code}, message: ${error.message}.`);
      return false;
    }
  }

  /**
   * 设置权限的弹窗开关状态
   * @param permission 权限
   * @param enabled true: 应用请求权限时弹框询问; false: 不弹框直接授权
   * return 设置是否成功
   */
  public static async setPermissionQueryEnabled(permission: Permission, enabled: boolean): Promise<boolean> {
    let atManager = abilityAccessCtrl.createAtManager();
    let status: abilityAccessCtrl.PermissionRequestToggleStatus =
      abilityAccessCtrl.PermissionRequestToggleStatus.OPEN;
    if (!enabled) {
      status = abilityAccessCtrl.PermissionRequestToggleStatus.CLOSED;
    }
    try {
      await atManager.setPermissionRequestToggleStatus(permission, status);
      Log.info(`SetPermissionRequestToggleStatus ${permission} to ${status} success.`);
      return true;
    } catch (error) {
      Log.error(`SetPermissionRequestToggleStatus failed, code: ${error.code}, message: ${error.message}.`);
      return false;
    }
  }

  private static getGrantedLinkedPermissions(permission: Permission): Permission[] {
    switch (permission) {
      case Permission.READ_WHOLE_CALENDAR:
        return [Permission.READ_CALENDAR];
      case Permission.WRITE_WHOLE_CALENDAR:
        return [Permission.WRITE_CALENDAR];
      default:
        return [];
    }
  }

  private static async grantLinkedPermissions(
    tokenId: number, linkedPermissions: Permission[], flag: number
  ): Promise<void> {
    if (!linkedPermissions.length) {
      return;
    }

    let atManager = abilityAccessCtrl.createAtManager();
    for (const linkedPermission of linkedPermissions) {
      try {
        await atManager.grantPermission(tokenId, linkedPermission, flag);
      } catch (error) {
        Log.error(
          `Grant linked permission failed, permission: ${linkedPermission}, ` +
          `code: ${error.code}, message: ${error.message}.`
        );
      }
    }
  }
  /**
   * 授予权限并返回操作结果
   * @param permission 操作权限
   * @param flag 授权flag
   * @param tokenId 应用token
   * return
   */
  public static async grantPermissionWithResult(
    permission: Permission, flag: number, tokenId: number
  ): Promise<optionAndState> {
    try {
      let atManager = abilityAccessCtrl.createAtManager();
      await atManager.grantPermission(tokenId, permission, flag);
      await PermissionUtils.grantLinkedPermissions(
        tokenId,
        PermissionUtils.getGrantedLinkedPermissions(permission),
        flag
      );
      Log.info(`grant permission success, permission: ${permission}.`);
      return {
        operationResult: Constants.RESULT_SUCCESS,
        permissionState: abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
      }
    } catch (error) {
      Log.error(
        `grant permission failed, permission: ${permission}, ` +
        `code: ${error.code}, message: ${error.message}.`
      );
      return {
        operationResult: Constants.RESULT_FAILURE,
        permissionState: abilityAccessCtrl.GrantStatus.PERMISSION_DENIED
      }
    }
  }

  /**
   * 撤销权限并返回操作结果
   * @param permission 操作权限
   * @param flag 授权flag
   * @param tokenId 应用token
   * return
   */
  public static async revokePermissionWithResult(
    permission: Permission, flag: number, tokenId: number
  ): Promise<optionAndState> {
    try {
      let atManager = abilityAccessCtrl.createAtManager();
      await atManager.revokePermission(tokenId, permission, flag, false);
      Log.info(`revoke permission success, permission: ${permission}.`);
      return {
        operationResult: Constants.RESULT_SUCCESS,
        permissionState: abilityAccessCtrl.GrantStatus.PERMISSION_DENIED
      }
    } catch (error) {
      Log.error(`revoke permission failed, permission: ${permission}, code: ${error.code}, message: ${error.message}.`);
      return {
        operationResult: Constants.RESULT_FAILURE,
        permissionState: abilityAccessCtrl.GrantStatus.PERMISSION_DENIED
      }
    }
  }

}

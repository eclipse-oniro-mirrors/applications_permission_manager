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
      Log.error(`getBundleResourceInfo faild, code: ${error.code}, message: ${error.message}.`);
      return false;
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
      await atManager.grantUserGrantedPermission(tokenId, permission, flag);
      Log.info(`grant permission success, permission: ${permission}.`);
      return {
        operationResult: Constants.RESULT_SUCCESS,
        permissionState: abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
      }
    } catch (error) {
      Log.error(`grant permission faild, permission: ${permission}, code: ${error.code}, message: ${error.message}.`);
      return {
        operationResult: Constants.RESULT_FAILURE,
        permissionState: abilityAccessCtrl.GrantStatus.PERMISSION_DENIED
      }
    }
  }

}
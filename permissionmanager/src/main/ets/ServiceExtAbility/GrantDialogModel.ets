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

import { BaseModel } from '../common/base/BaseModel';
import { Want } from '@kit.AbilityKit';
import { GlobalContext } from '../common/utils/globalContext';
import { Permission, PermissionGroup, ButtonStatus, PermissionOption } from '../common/model/definition';
import { Log, titleTrim, supportPermission } from '../common/utils/utils';
import {
  Property, CallerAppInfo, PermissionGroupConfig, PermissionWithOption, optionAndState
} from '../common/model/typedef';
import { PermissionGroupManager } from '../common/permissionGroupManager/PermissionGroupManager';
import rpc from '@ohos.rpc';
import window from '@ohos.window';
import display from '@ohos.display';
import pasteboard from '@ohos.pasteboard';
import common from '@ohos.app.ability.common';
import osAccount from '@ohos.account.osAccount';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import bundleManager from '@ohos.bundle.bundleManager';
import bundleResourceManager from '@ohos.bundle.bundleResourceManager';
import Constants from '../common/utils/constant';

const BG_COLOR = '#00000000';
const THIS_TIME_FLAG = [ButtonStatus.THIS_TIME_ONLY, ButtonStatus.ALLOW_THIS_TIME];
const DEFAULT_CALLER_APP_INFO: CallerAppInfo = {
  bundleName: '',
  tokenId: -1,
  reqPerms: [],
  reqPermsState: [],
  reqPermsDetails: [],
  proxy: {} as rpc.RemoteObject,
  grantResult: [],
  groupWithPermission: new Map<PermissionGroup, Set<Permission>>()
}

export class GrantDialogModel extends BaseModel {

  /**
   * 从want解析调用方信息和权限申请情况
   * @param want
   * return 应用包信息
   */
  public async getCallerAppInfo(want: Want): Promise<CallerAppInfo> {
    if (!want.parameters) {
      Log.error(`want.parameters is undefined!`);
      return DEFAULT_CALLER_APP_INFO;
    }
    let bundleName: string = want.parameters['ohos.aafwk.param.callerBundleName'] as string ?? '';
    let tokenId: number = want.parameters['ohos.aafwk.param.callerToken'] as number ?? -1;
    let reqPerms: Permission[] = [...(want.parameters['ohos.user.grant.permission'] as Permission[])] ?? [];
    let reqPermsState: number[] = [...(want.parameters['ohos.user.grant.permission.state'] as number[])] ?? [];
    let reqPermsDetails: bundleManager.ReqPermissionDetail[] = [];
    let callback: Property = want.parameters['ohos.ability.params.callback'] as Property;
    let proxy: rpc.RemoteObject = callback.value as rpc.RemoteObject;
    try {
      let userId: number = await this.getUserId();
      let flag: number = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_REQUESTED_PERMISSION;
      let bundleInfo: bundleManager.BundleInfo = bundleManager.getBundleInfoSync(bundleName, flag, userId);
      reqPermsDetails = bundleInfo.reqPermissionDetails ?? [];
    } catch (error) {
      Log.error(`getBundleInfo faild, code: ${error.code}, message: ${error.message}.`);
    }
    let grantResult: number[] = this.initGrantResult(reqPermsState);
    await this.preProcessPermission(reqPerms, reqPermsState, tokenId, grantResult);
    let callerAppInfo: CallerAppInfo = {
      bundleName,
      tokenId,
      reqPerms,
      reqPermsState,
      reqPermsDetails,
      proxy,
      grantResult,
      groupWithPermission: this.getGroupWithPermission(reqPerms, reqPermsState)
    }
    return callerAppInfo;
  }

  /**
   * 获取当前用户id
   * return 用户id
   */
  private async getUserId(): Promise<number> {
    let userId: number = 0;
    try {
      const accountManager: osAccount.AccountManager = osAccount.getAccountManager();
      userId = await accountManager.getForegroundOsAccountLocalId();
    } catch (error) {
      Log.error(`getForegroundOsAccountLocalId faild, code: ${error.code}, message: ${error.message}.`);
    }
    return userId;
  }

  /**
   * 初始化授权状态列表
   * @param reqPermsState 权限状态
   * return 授权状态列表
   */
  private initGrantResult(reqPermsState: number[]): number[] {
    let grantResult: number[] = new Array(reqPermsState.length).fill(abilityAccessCtrl.GrantStatus.PERMISSION_DENIED);
    reqPermsState.forEach((state, idx) => {
      if (state === Constants.PASS_OPER) {
        grantResult[idx] = abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
      }
    })
    return grantResult;
  }

  /**
   * 预处理待授权权限
   * @param reqPerms 授权权限
   * @param reqPermsState 权限状态
   * @param tokenId 应用token
   * @param grantResult 授权状态
   * return
   */
  private async preProcessPermission(
    reqPerms: Permission[], reqPermsState: number[], tokenId: number, grantResult: number[]
  ): Promise<void> {
    let allGroupConfigs: PermissionGroupConfig[] = PermissionGroupManager.getInstance().getAllGroupConfigs();
    for (let index = 0; index < reqPerms.length; index++) {
      if (!this.needHandlePermission(reqPerms[index], reqPermsState[index])) {
        continue;
      }
      let group = PermissionGroupManager.getInstance().getGroupNameByPermission(reqPerms[index], allGroupConfigs);
      let result = await PermissionGroupManager.getInstance().preProcessPermission(
        reqPerms[index], group as PermissionGroup, tokenId
      );
      this.preProcessState(reqPerms, reqPermsState, grantResult, result);
    }
  }

  /**
   * 初始化授权状态列表
   * @param reqPerms 授权权限
   * @param reqPermsState 权限状态
   * @param grantResult 授权状态
   * @param result 授权结果
   * return
   */
  private preProcessState(
    reqPerms: Permission[], reqPermsState: number[], grantResult: number[], result: PermissionWithOption[]
  ): void {
    result.forEach(permissionWithOption => {
      let needRefresh = reqPerms.find(perm => perm === permissionWithOption.permission);
      if (!needRefresh) {
        return;
      }
      for (let index = 0; index < reqPerms.length; index++) {
        if (reqPerms[index] === permissionWithOption.permission) {
          reqPermsState[index] = permissionWithOption.permissionOption === PermissionOption.GRANT ?
            Constants.PASS_OPER : Constants.SETTING_OPER;
          grantResult[index] = reqPermsState[index];
        }
      }
    })
  }

  /**
   * 获取待授权权限及其所属权限组
   * @param reqPerms 权限
   * @param reqPermsState 权限状态
   * return key：权限组，value：待授权权限
   */
  private getGroupWithPermission(
    reqPerms: Permission[], reqPermsState: number[]
  ): Map<PermissionGroup, Set<Permission>> {
    if (reqPerms.length !== reqPermsState.length) {
      return new Map<PermissionGroup, Set<Permission>>();
    }
    let groupWithPermission: Map<PermissionGroup, Set<Permission>> = new Map();
    let allGroupConfigs: PermissionGroupConfig[] = PermissionGroupManager.getInstance().getAllGroupConfigs();
    for (let index = 0; index < reqPerms.length; index++) {
      let perm = reqPerms[index];
      if (this.needHandlePermission(perm, reqPermsState[index])) {
        let groupName = PermissionGroupManager.getInstance().getGroupNameByPermission(perm, allGroupConfigs);
        if (!groupName) {
          continue;
        }
        if (!groupWithPermission.has(groupName)) {
          groupWithPermission.set(groupName, new Set([perm]));
        } else {
          groupWithPermission.get(groupName)?.add(perm);
        }
      }
    }
    return groupWithPermission;
  }

  /**
   * 判断权限是否为当前设备所支持权限 且状态为待授权
   * @param permission 权限
   * @param state 权限初始状态
   * return
   */
  private needHandlePermission(permission: Permission, state: number): boolean {
    let supportPermissions = supportPermission();
    if (supportPermissions.includes(permission) && state === Constants.DYNAMIC_OPER) {
      return true;
    } else {
      return false;
    }
  }

  /**
   * 创建模态窗口
   * @param context ServiceExtensionContext
   * @param name 窗口名
   * @param rect 窗口参数
   * @param want
   * return
   */
  public async createWindow(
    context: common.ServiceExtensionContext, name: string, rect: display.Rect, want: Want
  ): Promise<void> {
    try {
      let configuration: window.Configuration = {
        ctx: context,
        name,
        windowType: window.WindowType.TYPE_DIALOG
      }
      const win = await window.createWindow(configuration);
      Log.info('createWindow end.');
      let callerAppInfo: CallerAppInfo = await this.getCallerAppInfo(want);
      let property: Record<string, Object> = { 'win': win, 'callerAppInfo': callerAppInfo };
      let storage: LocalStorage = new LocalStorage(property);
      await this.BindDialogTarget(context, win, want);
      Log.info('bindDialogTarget end.');
      await win.moveWindowTo(rect.left, rect.top);
      Log.info('moveWindowTo end.');
      await win.resize(rect.width, rect.height);
      Log.info('resize end.');
      await win.loadContent('pages/dialogPlus', storage);
      win.setWindowBackgroundColor(BG_COLOR);
      await win.showWindow();
      Log.info('showWindow end.');
      let windowNum: number = GlobalContext.getContext().increaseAndGetWindowNum();
      Log.info(`global windowNum is: ${windowNum}.`);
    } catch (error) {
      Log.error(`window create faild, code: ${error.code}, message: ${error.message}.`);
    }
  }

  /**
   * 绑定模态窗口
   * @param context ServiceExtensionContext
   * @param win 窗口对象
   * @param want
   * return
   */
  private async BindDialogTarget(
    context: common.ServiceExtensionContext, win: window.Window, want: Want
  ): Promise<void> {
    let callback = want.parameters?.['ohos.ability.params.callback'] as Property;
    let proxy = callback.value as rpc.RemoteObject;
    let token = want.parameters?.['ohos.ability.params.token'] as Property;
    win.bindDialogTarget(token.value, () => {
      let option = new rpc.MessageOption();
      let data = new rpc.MessageSequence();
      let reply = new rpc.MessageSequence();
      try {
        data.writeInterfaceToken(Constants.ACCESS_TOKEN);
        proxy.sendMessageRequest(Constants.RESULT_CODE_1, data, reply, option);
      } catch (err) {
        Log.error(`write result failed: ${JSON.stringify(err)}`);
      } finally {
        data.reclaim();
        reply.reclaim();
      }
      let windowNum: number = GlobalContext.getContext().decreaseAndGetWindowNum();
      Log.info(`global windowNum is: ${windowNum}.`);
      win.destroyWindow();
      windowNum <= 0 ? context.terminateSelf() : null;
    });
  }

  /**
   * 获取剪贴板信息
   * return 剪贴板内容来源应用名
   */
  public getPasteBoardInfo(): string {
    let systemPasteboardDataSource: string = '';
    try {
      let systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
      let data = systemPasteboard.getDataSource();
      systemPasteboardDataSource = data || '';
    } catch (error) {
      Log.error(`getSystemPasteboard faild, code: ${error.code}, message: ${error.message}.`);
    }
    Log.info(`systemPasteboard dataSource: ${systemPasteboardDataSource}.`);
    return systemPasteboardDataSource;
  }

  /**
   * 获取应用名
   * @param bundleName 包名
   * return 应用名
   */
  public getAppName(bundleName: string): string {
    let resourceFlag: bundleResourceManager.ResourceFlag = bundleResourceManager.ResourceFlag.GET_RESOURCE_INFO_ALL;
    let appName: string = '';
    try {
      let resourceInfo: bundleResourceManager.BundleResourceInfo =
        bundleResourceManager.getBundleResourceInfo(bundleName, resourceFlag);
      appName = resourceInfo?.label || '';
    } catch (error) {
      Log.error(`getBundleResourceInfo faild, code: ${error.code}, message: ${error.message}.`);
      appName = 'Application';
    }
    Log.info(`appName: ${appName}.`);
    return titleTrim(appName);
  }

  /**
   * 初始化位置权限组授权信息
   * @param callerAppInfo 调用方信息
   * return flag: 0：不授权，1：只申请模糊权限，2：模糊升级为精确，3：模糊+精确，开启精确，4：模糊+精确，关闭精确
   */
  public initLocationFlag(callerAppInfo: CallerAppInfo): number {
    let locationFlag: number = Constants.LOCATION_NONE;
    let hasFuzz: boolean = callerAppInfo.reqPerms.includes(Permission.APPROXIMATELY_LOCATION);
    let hasPrecise: boolean = callerAppInfo.reqPerms.includes(Permission.LOCATION);

    if (hasFuzz) {
      locationFlag = Constants.LOCATION_FUZZY;
      if (hasPrecise) {
        locationFlag = Constants.LOCATION_BOTH_PRECISE;
        let fuzzyIndex = callerAppInfo.reqPerms.indexOf(Permission.APPROXIMATELY_LOCATION);
        if (callerAppInfo.reqPermsState[fuzzyIndex] === Constants.PASS_OPER) {
          locationFlag = Constants.LOCATION_UPGRADE;
        }
      }
    } else {
      if (hasPrecise) {
        locationFlag = Constants.LOCATION_UPGRADE;
      }
    }
    return locationFlag;
  }

  /**
   * 获取所有授权权限组
   * @param callerAppInfo 调用方信息
   * @param context 应用上下文
   * @param appName 应用名
   * @param locationFlag 位置权限组flag
   * @param pasteBoardName 剪贴板信息
   * return
   */
  public getGrantGroups(
    callerAppInfo: CallerAppInfo,
    context: common.ServiceExtensionContext,
    appName: string,
    locationFlag: number,
    pasteBoardName: string
  ): PermissionGroupConfig[] {
    return PermissionGroupManager.getInstance().getGroupConfigs(
      callerAppInfo, context, appName, locationFlag, pasteBoardName
    );
  }

  /**
   * 点击事件处理
   * @param groupConfig
   * @param callerAppInfo 调用方信息
   * @param locationFlag 位置权限组flag
   * @param buttonStatus 点击状态
   * return
   */
  public async clickHandle(
    groupConfig: PermissionGroupConfig, callerAppInfo: CallerAppInfo, locationFlag: number, buttonStatus: ButtonStatus
  ): Promise<void> {
    let flag: number =
      THIS_TIME_FLAG.includes(buttonStatus) ? Constants.PERMISSION_ALLOW_THIS_TIME : Constants.PERMISSION_FLAG;
    Log.info(`clickHandle, group: ${groupConfig.groupName}, buttonStatus: ${buttonStatus}.`);
    let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    let reportPermissions: Permission[] = [];
    let permissionWithOptionList: PermissionWithOption[] = [];

    for (let permission of groupConfig.permissions) {
      let result: optionAndState = {
        operationResult: Constants.RESULT_SUCCESS,
        permissionState: abilityAccessCtrl.GrantStatus.PERMISSION_DENIED
      };
      let permissionOption = PermissionGroupManager.getInstance().getPermissionOption(
        permission, groupConfig.groupName, callerAppInfo, locationFlag, buttonStatus
      );
      let permissionWithOption: PermissionWithOption = { permission, permissionOption };
      if (permissionOption !== PermissionOption.SKIP) {
        permissionWithOptionList.push(permissionWithOption);
      }
      if (permissionOption === PermissionOption.GRANT) {
        result = await this.grantPermissionWithResult(permission, flag, callerAppInfo.tokenId, atManager);
      }
      if (permissionOption === PermissionOption.REVOKE) {
        result = await this.revokePermissionWithResult(permission, flag, callerAppInfo.tokenId, atManager);
      }
      Log.info(`permission: ${permission}, opt: ${permissionOption}, result: ${result.operationResult}.`);
      if (result.operationResult === Constants.RESULT_SUCCESS && permissionOption !== PermissionOption.SKIP) {
        reportPermissions.push(permission);
        this.writeToGrantResult(permission, callerAppInfo, result.permissionState);
      }
    }
  }

  /**
   * 授予权限并返回操作结果
   * @param permission 操作权限
   * @param flag 授权flag
   * @param tokenId 应用token
   * @param atManager atManager对象
   * return
   */
  private async grantPermissionWithResult(
    permission: Permission, flag: number, tokenId: number, atManager: abilityAccessCtrl.AtManager
  ): Promise<optionAndState> {
    try {
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

  /**
   * 撤销权限并返回操作结果
   * @param permission 操作权限
   * @param flag 授权flag
   * @param tokenId 应用token
   * @param atManager atManager对象
   * return
   */
  private async revokePermissionWithResult(
    permission: Permission, flag: number, tokenId: number, atManager: abilityAccessCtrl.AtManager
  ): Promise<optionAndState> {
    try {
      await atManager.revokeUserGrantedPermission(tokenId, permission, flag);
      Log.info(`revoke permission success, permission: ${permission}.`);
      return {
        operationResult: Constants.RESULT_SUCCESS,
        permissionState: abilityAccessCtrl.GrantStatus.PERMISSION_DENIED
      }
    } catch (error) {
      Log.error(`revoke permission faild, permission: ${permission}, code: ${error.code}, message: ${error.message}.`);
      return {
        operationResult: Constants.RESULT_FAILURE,
        permissionState: abilityAccessCtrl.GrantStatus.PERMISSION_DENIED
      }
    }
  }

  /**
   * 授权或撤销成功后，将结果写入grantResult
   * @param permission 权限
   * @param callerAppInfo 调用方信息
   * @param state 权限状态
   * return
   */
  public writeToGrantResult(
    permission: Permission, callerAppInfo: CallerAppInfo, state: abilityAccessCtrl.GrantStatus
  ): void {
    callerAppInfo.reqPerms.forEach((reqPerm, index) => {
      if (reqPerm === permission) {
        callerAppInfo.grantResult[index] = state;
      }
    })
  }

  /**
   * 销毁模态窗口
   * @param context ServiceExtensionContext
   * @param win 窗口对象
   * @param callerAppInfo 调用方信息
   * return
   */
  public async terminateWithResult(
    context: common.ServiceExtensionContext, win: window.Window, callerAppInfo: CallerAppInfo
  ): Promise<void> {
    Log.info(`Perms: ${JSON.stringify(callerAppInfo.reqPerms)}, result: ${JSON.stringify(callerAppInfo.grantResult)}.`);
    let option = new rpc.MessageOption();
    let data = new rpc.MessageSequence();
    let reply = new rpc.MessageSequence();
    let setDialogData = new rpc.MessageSequence();
    try {
      data.writeInterfaceToken(Constants.ACCESS_TOKEN);
      data.writeStringArray(callerAppInfo.reqPerms);
      data.writeIntArray(callerAppInfo.grantResult);
      setDialogData.writeInterfaceToken(Constants.ACCESS_TOKEN);
      callerAppInfo.proxy.sendMessageRequest(Constants.RESULT_CODE, data, reply, option);
      callerAppInfo.proxy.sendMessageRequest(Constants.RESULT_CODE_1, setDialogData, reply, option);
    } catch (error) {
      Log.error(`terminateWithResult faild, code: ${error.code}, message: ${error.message}.`);
    } finally {
      data.reclaim();
      reply.reclaim();
      setDialogData.reclaim();
      let windowNum: number = GlobalContext.getContext().decreaseAndGetWindowNum();
      Log.info(`global windowNum is: ${windowNum}.`);
      win.destroyWindow();
      windowNum <= 0 ? context.terminateSelf() : null;
    }
  }

}
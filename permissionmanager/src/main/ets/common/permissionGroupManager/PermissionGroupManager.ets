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

import { BasePermissionStrategy } from '../base/BasePermissionStrategy';
import { LocationStrategy } from './LocationStrategy';
import { CameraStrategy } from './CameraStrategy';
import { MicrophoneStrategy } from './MicrophoneStrategy';
import { ContactsStrategy } from './ContactsStrategy';
import { CalendarStrategy } from './CalendarStrategy';
import { SportStrategy } from './SportStrategy';
import { HealthStrategy } from './HealthStrategy';
import { ImageAndVideosStrategy } from './ImageAndVideosStrategy';
import { AudioStrategy } from './AudiosStrategy';
import { DocumentsStrategy } from './DocumentsStrategy';
import { AdsStrategy } from './AdsStrategy';
import { GetInstalledBundleListStrategy } from './GetInstalledBundleListStrategy';
import { DistributedDatasyncStrategy } from './DistributedDatasyncStrategy';
import { BluetoothStrategy } from './BluetoothStrategy';
import { PasteboardStrategy } from './PasteboardStrategy';
import { DownloadDirectoryStrategy } from './DownloadDirectoryStrategy';
import { DesktopDirectoryStrategy } from './DesktopDirectoryStrategy';
import { DocumentsDirectoryStrategy } from './DocumentsDirectoryStrategy';
import { NearlinkStrategy } from './NearlinkStrategy';
import { ScreenCaptureStrategy } from './ScreenCaptureStrategy';
import { Permission, PermissionGroup, PermissionOption, ButtonStatus, ClickOption } from '../model/definition';
import { PermissionGroupConfig, CallerAppInfo, PermissionWithOption } from '../model/typedef';
import { Log } from '../utils/utils';
import common from '@ohos.app.ability.common';

export class PermissionGroupManager {
  private permissionStrategies: Map<PermissionGroup, BasePermissionStrategy> = new Map();
  private static instance: PermissionGroupManager;

  private constructor() {
    // 位置信息
    this.permissionStrategies.set(PermissionGroup.LOCATION, new LocationStrategy());
    // 相机
    this.permissionStrategies.set(PermissionGroup.CAMERA, new CameraStrategy());
    // 麦克风
    this.permissionStrategies.set(PermissionGroup.MICROPHONE, new MicrophoneStrategy());
    // 通讯录
    this.permissionStrategies.set(PermissionGroup.CONTACTS, new ContactsStrategy());
    // 日历
    this.permissionStrategies.set(PermissionGroup.CALENDAR, new CalendarStrategy());
    // 运动健身
    this.permissionStrategies.set(PermissionGroup.SPORT, new SportStrategy());
    // 身体传感器
    this.permissionStrategies.set(PermissionGroup.HEALTH, new HealthStrategy());
    // 图片和视频
    this.permissionStrategies.set(PermissionGroup.IMAGE_AND_VIDEOS, new ImageAndVideosStrategy());
    // 音频
    this.permissionStrategies.set(PermissionGroup.AUDIOS, new AudioStrategy());
    // 文件
    this.permissionStrategies.set(PermissionGroup.DOCUMENTS, new DocumentsStrategy());
    // 应用跟踪
    this.permissionStrategies.set(PermissionGroup.ADS, new AdsStrategy());
    // 读取已安装应用列表
    this.permissionStrategies.set(PermissionGroup.GET_INSTALLED_BUNDLE_LIST, new GetInstalledBundleListStrategy());
    // 附近设备
    this.permissionStrategies.set(PermissionGroup.DISTRIBUTED_DATASYNC, new DistributedDatasyncStrategy());
    // 蓝牙
    this.permissionStrategies.set(PermissionGroup.BLUETOOTH, new BluetoothStrategy());
    // 剪贴板
    this.permissionStrategies.set(PermissionGroup.PASTEBOARD, new PasteboardStrategy());
    // 文件夹
    this.permissionStrategies.set(PermissionGroup.DOWNLOAD_DIRECTORY, new DownloadDirectoryStrategy());
    this.permissionStrategies.set(PermissionGroup.DESKTOP_DIRECTORY, new DesktopDirectoryStrategy());
    this.permissionStrategies.set(PermissionGroup.DOCUMENTS_DIRECTORY, new DocumentsDirectoryStrategy());
    // 星闪
    this.permissionStrategies.set(PermissionGroup.NEARLINK, new NearlinkStrategy());
    // 截屏
    this.permissionStrategies.set(PermissionGroup.CUSTOM_SCREEN_CAPTURE, new ScreenCaptureStrategy());
  }

  public static getInstance(): PermissionGroupManager {
    if (!PermissionGroupManager.instance) {
      PermissionGroupManager.instance = new PermissionGroupManager();
    }
    return PermissionGroupManager.instance;
  }

  /**
   * 获取所有权限组config
   * return
   */
  public getAllGroupConfigs(): PermissionGroupConfig[] {
    let allConfig: PermissionGroupConfig[] = [];
    this.permissionStrategies.forEach((strategy, permissionGroup) => {
      allConfig.push(strategy.getPermissionGroupConfig());
    })
    return allConfig;
  }

  /**
   * 根据权限获取所在权限组名
   * @param permission 权限
   * @param allConfigs
   * return
   */
  public getGroupNameByPermission(
    permission: Permission, allConfigs: PermissionGroupConfig[]
  ): PermissionGroup | undefined {
    for (let index = 0; index < allConfigs.length; index++) {
      const element = allConfigs[index];
      if (element.permissions.includes(permission)) {
        return element.groupName;
      }
    }
    Log.error(`can not find permissionGroup, permission: ${permission}`);
    return undefined;
  }

  /**
   * 预处理待授权权限
   * @param permission 权限
   * @param groupName 权限组名
   * @param tokenId 应用token
   * return
   */
  public async preProcessPermission(
    permission: Permission, groupName: PermissionGroup, tokenId: number
  ): Promise<PermissionWithOption[]> {
    const groupHandle = this.permissionStrategies.get(groupName);
    if (groupHandle === undefined) {
      return [];
    }
    let result = await groupHandle.preProcessingPermission(permission, tokenId);
    return result;
  }

  /**
   * 根据带申请权限获取所有权限组列表
   * @param callerAppInfo 调用方信息
   * @param context 应用上下文
   * @param appName 应用名
   * @param locationFlag 位置权限组flag
   * @param pasteBoardName 剪贴板信息
   * return
   */
  public getGroupConfigs(
    callerAppInfo: CallerAppInfo,
    context: common.ServiceExtensionContext,
    appName: string,
    locationFlag: number,
    pasteBoardName: string
  ): PermissionGroupConfig[] {
    let groupConfigList: PermissionGroupConfig[] = [];
    callerAppInfo.groupWithPermission.forEach((permissions, permissionGroup) => {
      let groupHandle = this.permissionStrategies.get(permissionGroup);
      if (groupHandle === undefined || groupHandle === null) {
        Log.error(`get groupHandle faild, group: ${permissionGroup}.`);
        return;
      }
      let groupConfig: PermissionGroupConfig = groupHandle.getPermissionGroupConfig();
      let title: ResourceStr = groupHandle.getGroupTitle(appName, locationFlag);
      let readAndWrite: ResourceStr = groupHandle.getReadAndWrite(permissions);
      let reason: ResourceStr =
        groupHandle.getReasonByPermission(groupConfig.permissions, permissions, context, callerAppInfo, pasteBoardName);
      groupConfigList.push(new PermissionGroupConfig({
        groupName: groupConfig.groupName,
        permissions: groupConfig.permissions,
        icon: groupConfig.icon,
        title,
        readAndWrite,
        reason,
        buttonList: groupHandle.getButtonList()
      }))
    })
    return groupConfigList;
  }

  /**
   * 根据点击状态，返回当前权限对应的操作
   * @param permission 权限
   * @param groupName 权限组名
   * @param callerAppInfo 调用方信息
   * @param locationFlag 位置权限组flag
   * @param buttonStatus
   * return
   */
  public getPermissionOption(
    permission: Permission,
    groupName: PermissionGroup,
    callerAppInfo: CallerAppInfo,
    locationFlag: number,
    buttonStatus: ButtonStatus
  ): PermissionOption {
    const groupHandle = this.permissionStrategies.get(groupName);
    let situation: ClickOption = this.getClickSituation(buttonStatus);
    if (groupHandle) {
      if (situation === ClickOption.GRANT) {
        return groupHandle.grantHandle(permission, callerAppInfo, locationFlag, buttonStatus);
      } else if (situation === ClickOption.DENY) {
        return groupHandle.denyHandle(permission, callerAppInfo, locationFlag, buttonStatus);
      } else {
        return PermissionOption.SKIP;
      }
    }
    return PermissionOption.SKIP;
  }

  /**
   * 处理点击状态
   * @param buttonStatus
   * return
   */
  public getClickSituation(buttonStatus: ButtonStatus): ClickOption {
    switch (buttonStatus) {
      case ButtonStatus.ALLOW:
      case ButtonStatus.ALLOW_THIS_TIME:
      case ButtonStatus.THIS_TIME_ONLY:
      case ButtonStatus.ALLOW_ONLY_DURING_USE:
        return ClickOption.GRANT;
      case ButtonStatus.CANCEL:
        return ClickOption.CANCEL;
      default:
        return ClickOption.DENY;
    }
  }

}
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
import { audio } from '@kit.AudioKit';
import { camera } from '@kit.CameraKit';
import { abilityAccessCtrl, bundleManager } from '@kit.AbilityKit';
import { Log } from '../common/utils/utils';
import { PermissionGroup } from '../common/model/definition';
import { PermissionApplications } from '../common/model/typedef';
import { GlobalDialogViewState } from './GlobalDialogViewState';
import router from '@ohos.router';
import window from '@ohos.window';
import display from '@ohos.display';
import common from '@ohos.app.ability.common';

const BG_COLOR = '#00000000';
const CAMERA = 'camera';
const MICROPHONE = 'microphone';

export class GlobalDialogModel extends BaseModel {
  private static instance: GlobalDialogModel;

  public static getInstance(): GlobalDialogModel {
    if (!GlobalDialogModel.instance) {
      GlobalDialogModel.instance = new GlobalDialogModel();
    }
    return GlobalDialogModel.instance;
  }

  /**
   * 判断麦克风全局状态
   * return boolean
   */
  private microphoneStatus(): boolean {
    try {
      let audioManager = audio.getAudioManager();
      let audioVolumeManager = audioManager.getVolumeManager();
      let groupId = audio.DEFAULT_VOLUME_GROUP_ID;
      let audioVolumeGroupManager = audioVolumeManager.getVolumeGroupManagerSync(groupId);
      let muteState = audioVolumeGroupManager.isPersistentMicMute();
      Log.info(`microphoneStatus: ${muteState}.`);
      return muteState;
    } catch (err) {
      Log.error('Failed to obtain the microphone disabled status.');
      return false;
    }
  }

  /**
   * 判断相机全局状态
   * @param context ServiceExtensionContext
   * return boolean
   */
  private cameraStatus(context: Context): boolean {
    try {
      let cameraManager = camera.getCameraManager(context);
      let isMuteSupported = cameraManager.isCameraMuteSupported();
      if (!isMuteSupported) {
        Log.info('The current device does not support disabling the camera.');
        return false;
      }
      let muteState = cameraManager.isCameraMuted();
      Log.info(`cameraStatus: ${muteState}.`);
      return muteState;
    } catch (err) {
      Log.error('Failed to obtain the camera disabled status.');
      return false;
    }
  }

  /**
   * 判断弹窗申请权限的全局状态
   * @param context ServiceExtensionContext
   * @param resource 弹窗申请的权限
   * return boolean
   */
  public statusCheck(context: Context, resource: string): boolean {
    switch (resource) {
      case 'microphone':
        if (this.microphoneStatus()) {
          return true;
        } else {
          Log.info('The microphone is not disabled on this device.');
          return false;
        }
      case 'camera':
        if (this.cameraStatus(context)) {
          return true;
        } else {
          Log.info('The camera is not disabled on this device.');
          return false;
        }
      default:
        if (this.microphoneStatus() && this.cameraStatus(context)) {
          return true;
        } else {
          Log.info('The microphone and camera is not disabled on this device.');
          return false;
        }
    }
  }

  /**
   * 判断是否拥有控制全局开关的权限
   * return boolean
   */
  public permissionCheck(): boolean {
    try {
      let flag = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION;
      let bundleInfo = bundleManager.getBundleInfoForSelfSync(flag);
      let atManager = abilityAccessCtrl.createAtManager();
      let status =
        atManager.verifyAccessTokenSync(bundleInfo.appInfo.accessTokenId, 'ohos.permission.MICROPHONE_CONTROL');
      if (status === abilityAccessCtrl.GrantStatus.PERMISSION_DENIED) {
        Log.info('permission status is denied.');
        return false;
      }
      return true;
    } catch (err) {
      Log.error('verifyAccessTokenSync failed.');
      return false;
    }
  }

  /**
   * 创建全局弹窗
   * @param context ServiceExtensionContext
   * @param rect 窗口大小及位置
   * @param storage 数据管理
   * return 创建的窗口
   */
  public async createWindow(
    context: Context, rect: display.Rect, storage: LocalStorage
  ): Promise<window.Window | null> {
    try {
      Log.info('create window');
      let configuration: window.Configuration = {
        ctx: context,
        name: 'globalDialog',
        windowType: window.WindowType.TYPE_VOICE_INTERACTION
      }
      const win = await window.createWindow(configuration);
      await win.moveWindowTo(rect.left, rect.top);
      await win.resize(rect.width, rect.height);
      await win.loadContent('pages/globalSwitch', storage);
      win.setWindowBackgroundColor(BG_COLOR);
      await win.showWindow();
      return win;
    } catch (error) {
      Log.error(`window create failed, code: ${error.code}, message: ${error.message}.`);
      return null;
    }
  }

  public initViewState(type: string): GlobalDialogViewState {
    let viewState = new GlobalDialogViewState();
    if (type === MICROPHONE) {
      viewState.title = $r('app.string.global_title_microphone');
      viewState.text = $r('app.string.global_desc_microphone');
    } else if (type === CAMERA) {
      viewState.title = $r('app.string.global_title_camera');
      viewState.text = $r('app.string.global_desc_camera');
    } else {
      viewState.title = $r('app.string.global_title_camera_and_microphone');
      viewState.text = $r('app.string.global_desc_camera_and_microphone');
    }
    return viewState;
  }

  /**
   * 获取全局开关状态
   * @param context UIAbilityContext
   * @param type 全局开关类型
   * @param backTitle 标题
   * @param list 应用列表
   * return
   */
  public getMuteStateAndGoto(
    context: common.UIAbilityContext,
    type: PermissionGroup,
    backTitle: ResourceStr,
    list: PermissionApplications[]
  ): void {
    try {
      if (type == PermissionGroup.MICROPHONE) {
        let audioManager = audio.getAudioManager();
        let audioVolumeManager = audioManager.getVolumeManager();
        let audioVolumeGroupManager = audioVolumeManager.getVolumeGroupManagerSync(audio.DEFAULT_VOLUME_GROUP_ID);
        let muteState = audioVolumeGroupManager.isPersistentMicMute();
        Log.info(`get muteState success: ${muteState}.`);
        router.pushUrl({
          url: 'pages/authority-tertiary-groups',
          params: { list, backTitle, globalIsOn: !muteState, isMuteSupported: true }
        })
      } else {
        let cameraManager = camera.getCameraManager(context);
        let mute = cameraManager.isCameraMuted();
        let isCameraMuteSupported = cameraManager.isCameraMuteSupported();
        Log.info(`get muteState success: ${mute}.`);
        router.pushUrl({
          url: 'pages/authority-tertiary-groups',
          params: { list, backTitle, globalIsOn: !mute, isMuteSupported: isCameraMuteSupported }
        })
      }
    } catch (error) {
      Log.error(`getMuteStateAndGoto failed, code: ${error.code}, message: ${error.message}.`);
    }
  }

  /**
   * 设置麦克风全局开关
   * @param context ServiceExtensionContext | UIAbilityContext
   * @param flag 全局开关状态
   * @param isKill 是否销毁ability
   * return
   */
  private setMicrophoneMute(
    context: common.ServiceExtensionContext | common.UIAbilityContext, flag: boolean, isKill: boolean
  ): void {
    try {
      let audioManager = audio.getAudioManager();
      let audioVolumeManager = audioManager.getVolumeManager();
      let audioVolumeGroupManager = audioVolumeManager.getVolumeGroupManagerSync(audio.DEFAULT_VOLUME_GROUP_ID);
      audioVolumeGroupManager.setMicMutePersistent(flag, audio.PolicyType.PRIVACY).then(() => {
        Log.info(`setMicMutePersistent success, mute: ${flag}.`);
        isKill ? context.terminateSelf() : null;
      })
    } catch (error) {
      Log.error(`setMicrophoneMute failed, code: ${error.code}, message: ${error.message}.`);
    }
  }

  /**
   * 设置相机全局开关
   * @param context ServiceExtensionContext | UIAbilityContext
   * @param flag 全局开关状态
   * @param isKill 是否销毁ability
   * return
   */
  private setCameraMute(
    context: common.ServiceExtensionContext | common.UIAbilityContext, flag: boolean, isKill: boolean
  ): void {
    try {
      let cameraManager = camera.getCameraManager(context);
      cameraManager.muteCameraPersistent(flag, camera.PolicyType.PRIVACY);
      Log.info(`muteCameraPersistent success, mute: ${flag}.`);
      isKill ? context.terminateSelf() : null;
    } catch (error) {
      Log.error(`setCameraMute failed, code: ${error.code}, message: ${error.message}.`);
    }
  }

  /**
   * 设置全局开关状态
   * @param context ServiceExtensionContext | UIAbilityContext
   * @param type 全局开关类型
   * @param flag 全局开关状态
   * @param isKill 是否销毁ability
   * return
   */
  public setMuteState(
    context: common.ServiceExtensionContext | common.UIAbilityContext, type: string, flag: boolean, isKill: boolean
  ): void {
    if (type === MICROPHONE || type === PermissionGroup.MICROPHONE) {
      this.setMicrophoneMute(context, flag, isKill);
    } else if (type === CAMERA || type === PermissionGroup.CAMERA) {
      this.setCameraMute(context, flag, isKill);
    } else {
      this.setCameraMute(context, flag, false);
      this.setMicrophoneMute(context, flag, isKill);
    }
  }

}
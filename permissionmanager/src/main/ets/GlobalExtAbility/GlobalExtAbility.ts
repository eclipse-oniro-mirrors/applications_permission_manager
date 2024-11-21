/*
 * Copyright (c) 2022 Huawei Device Co., Ltd.
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

import extension from '@ohos.app.ability.ServiceExtensionAbility';
import window from '@ohos.window';
import display from '@ohos.display';
import { GlobalContext } from '../common/utils/globalContext';
import { abilityAccessCtrl, bundleManager } from '@kit.AbilityKit';
import { camera } from '@kit.CameraKit';
import { audio } from '@kit.AudioKit';

const TAG = 'PermissionManager_Log:';
const BG_COLOR = '#00000000';

export default class GlobalExtensionAbility extends extension {
  /**
  * Lifecycle function, called back when a service extension is started for initialization.
  */
  onCreate(want): void {
    console.info(TAG + 'ServiceExtensionAbility onCreate, ability name is ' + want.abilityName);
    console.info(TAG + 'want: ' + JSON.stringify(want));

    GlobalContext.store('globalState', want.parameters['ohos.sensitive.resource']);
    GlobalContext.store('context', this.context);

    if (!this.permissionCheck()) {
      this.context.terminateSelf();
      return;
    }

    if (!this.statusCheck(want.parameters['ohos.sensitive.resource'])) {
      this.context.terminateSelf();
      return;
    }

    try {
      let dis = display.getDefaultDisplaySync();
      let navigationBarRect = {
        left: 0,
        top: 0,
        width: dis.width,
        height: dis.height
      };
      this.createWindow('globalDialog', window.WindowType.TYPE_VOICE_INTERACTION, navigationBarRect);
    } catch (exception) {
      console.error(TAG + 'Failed to obtain the default display object. Code: ' + JSON.stringify(exception));
    };
  }

  /**
  * Lifecycle function, called back when a service extension is started or recall.
  */
  onRequest(want, startId): void {
    console.info(TAG + 'ServiceExtensionAbility onRequest. start id is ' + startId);
  }

  /**
  * Lifecycle function, called back before a service extension is destroyed.
  */
  onDestroy(): void {
    console.info(TAG + 'ServiceExtensionAbility onDestroy.');
    let win = GlobalContext.load('globalWin');
    win?.destroyWindow();
  }

  private permissionCheck(): boolean {
    try {
      let flag = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION;
      let bundleInfo = bundleManager.getBundleInfoForSelfSync(flag);
      let atManager = abilityAccessCtrl.createAtManager();
      let status =
        atManager.verifyAccessTokenSync(bundleInfo.appInfo.accessTokenId, 'ohos.permission.MICROPHONE_CONTROL');
      if (status === abilityAccessCtrl.GrantStatus.PERMISSION_DENIED) {
        console.log(TAG + 'permission status is denied.');
        return false;
      }
      return true;
    } catch (err) {
      console.error(TAG + 'verifyAccessTokenSync failed.');
      return false;
    }
  }

  private statusCheck(resource: string): boolean {
    switch (resource) {
      case 'microphone':
        if (this.microphoneStatus()) {
          return true;
        } else {
          console.log(TAG + 'The microphone is not disabled on this device.');
          return false;
        }
      case 'camera':
        if (this.cameraStatus()) {
          return true;
        } else {
          console.log(TAG + 'The camera is not disabled on this device.');
          return false;
        }
      default:
        if (this.microphoneStatus() && this.cameraStatus()) {
          return true;
        } else {
          console.log(TAG + 'The microphone and camera is not disabled on this device.');
          return false;
        }
    }
  }

  private microphoneStatus(): boolean {
    try {
      let audioManager = audio.getAudioManager();
      let audioVolumeManager = audioManager.getVolumeManager();
      let groupId = audio.DEFAULT_VOLUME_GROUP_ID;
      let audioVolumeGroupManager = audioVolumeManager.getVolumeGroupManagerSync(groupId);
      let muteState = audioVolumeGroupManager.isPersistentMicMute();
      console.log(TAG + 'microphoneStatus: ' + muteState);
      return muteState;
    } catch (err) {
      console.error(TAG + 'Failed to obtain the microphone disabled status.');
      return false;
    }
  }

  private cameraStatus(): boolean {
    try {
      let cameraManager = camera.getCameraManager(this.context);
      let isMuteSupported = cameraManager.isCameraMuteSupported();
      if (!isMuteSupported) {
        console.log(TAG + 'The current device does not support disabling the camera.');
        return false;
      }
      let muteState = cameraManager.isCameraMuted();
      console.log(TAG + 'cameraStatus: ' + muteState);
      return muteState;
    } catch (err) {
      console.error(TAG + 'Failed to obtain the camera disabled status.');
      return false;
    }
  }

  private async createWindow(name: string, windowType: number, rect): Promise<void> {
    console.info(TAG + 'create window');
    try {
      const win = await window.createWindow({ ctx: this.context, name, windowType });
      GlobalContext.store('globalWin', win);
      await win.moveWindowTo(rect.left, rect.top);
      await win.resize(rect.width, rect.height);
      await win.setUIContent('pages/globalSwitch');
      win.setWindowBackgroundColor(BG_COLOR);
      await win.showWindow();
    } catch {
      console.info(TAG + 'window create failed!');
    }
  }
};
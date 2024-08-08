/*
 * Copyright (c) 2022-2023 Huawei Device Co., Ltd.
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

import Constants from '../common/utils/constant';
import audio from '@ohos.multimedia.audio';
import camera from '@ohos.multimedia.camera';
import common from '@ohos.app.ability.common';
import { CustomContentDialog } from '@ohos.arkui.advanced.Dialog';
import { Log } from '../common/utils/utils';
import { GlobalContext } from '../common/utils/globalContext';

const MICROPHONE = 'microphone';
const CAMERA = 'camera';

@Entry
@Component
struct globalSwitch {
  private context = getContext(this) as common.ServiceExtensionContext;
  @State globalState: string = GlobalContext.load('globalState');

  dialogController: CustomDialogController | null = new CustomDialogController({
    builder: CustomContentDialog({
      contentBuilder: () => {
        this.buildContent();
      },
      contentAreaPadding: { left: Constants.PADDING_24, right: Constants.PADDING_24 },
      buttons: [
        {
          value: $r('app.string.cancel'),
          buttonStyle: ButtonStyleMode.TEXTUAL,
          action: () => {
            Log.info('global cancel');
            this.context.terminateSelf();
          }
        },
        {
          value: $r('app.string.open'),
          buttonStyle: ButtonStyleMode.TEXTUAL,
          action: () => {
            Log.info('global accept');
            if (this.globalState == MICROPHONE) {
              let audioManager = audio.getAudioManager();
              let audioVolumeManager = audioManager.getVolumeManager();
              audioVolumeManager.getVolumeGroupManager(audio.DEFAULT_VOLUME_GROUP_ID).then(audioVolumeGroupManager => {
                audioVolumeGroupManager.setMicMutePersistent(false, audio.PolicyType.PRIVACY).then(() => {
                  this.context.terminateSelf();
                })
              })
            } else if (this.globalState == CAMERA) {
              let cameraManager = camera.getCameraManager(GlobalContext.load('context'));
              cameraManager.muteCameraPersistent(false, camera.PolicyType.PRIVACY);
              this.context.terminateSelf();
            } else {
              let cameraManager = camera.getCameraManager(GlobalContext.load('context'));
              cameraManager.muteCameraPersistent(false, camera.PolicyType.PRIVACY);
              let audioManager = audio.getAudioManager();
              let audioVolumeManager = audioManager.getVolumeManager();
              audioVolumeManager.getVolumeGroupManager(audio.DEFAULT_VOLUME_GROUP_ID).then(audioVolumeGroupManager => {
                audioVolumeGroupManager.setMicMutePersistent(false, audio.PolicyType.PRIVACY).then(() => {
                  this.context.terminateSelf();
                })
              })
            }
          }
        }
      ],
    }),
    autoCancel: false,
    cancel: () => {
      this.context.terminateSelf();
    }
  });

  @Builder
  buildContent(): void {
    Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
      Column() {
        Text(this.globalState == MICROPHONE ? $r('app.string.global_title_microphone') :
          this.globalState == CAMERA ? $r('app.string.global_title_camera') :
          $r('app.string.global_title_camera_and_microphone'))
          .fontSize(Constants.TEXT_BIG_FONT_SIZE)
          .fontColor($r('sys.color.font_primary'))
          .fontWeight(FontWeight.Medium)
          .lineHeight(Constants.TEXT_BIG_LINE_HEIGHT)
          .width(Constants.FULL_WIDTH)
          .padding({ top: Constants.PADDING_14, bottom: Constants.PADDING_14 })
        Text(this.globalState == MICROPHONE ? $r('app.string.global_desc_microphone') :
          this.globalState == CAMERA ? $r('app.string.global_desc_camera') :
          $r('app.string.global_desc_camera_and_microphone'))
          .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
          .fontColor($r('sys.color.font_primary'))
          .lineHeight(Constants.TEXT_LINE_HEIGHT)
      }
      .clip(true)
    }
  }

  build() {}

  aboutToAppear() {
    Log.info('global aboutToAppear');
    this.dialogController?.open();
  }

  aboutToDisappear() {
    this.dialogController = null;
  }
}
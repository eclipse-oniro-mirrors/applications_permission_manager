/*
 * Copyright (c) 2021-2022 Huawei Device Co., Ltd.
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

import Constants from '../utils/constant';
import audio from '@ohos.multimedia.audio'
import camera from '@ohos.multimedia.camera'
import deviceInfo from '@ohos.deviceInfo'

@Extend(Button) function customizeButton() {
  .backgroundColor($r('app.color.default_background_color'))
  .fontColor($r('app.color.button_color'))
  .fontWeight(FontWeight.Medium)
  .height(Constants.BUTTON_HEIGHT)
  .width(Constants.BUTTON_WIDTH)
}

@CustomDialog
export struct authorizeDialog {
  controller: CustomDialogController;
  cancel: () => void;
  confirm: () => void;

  build() {
    Column() {
      Row() {
        Flex({ justifyContent: FlexAlign.Center }) {
          Text($r("app.string.Authorization_failed")).fontSize(Constants.DIALOG_TEXT_FONT_SIZE)
            .margin({
              top: Constants.DIALOG_TEXT_MARGIN_TOP
            })
        }
      }
    }
    .backgroundColor($r('app.color.default_background_color'))
    .borderRadius(Constants.DIALOG_BORDER_RADIUS)
    .height(Constants.DIALOG_HEIGHT)
    .width(Constants.DIALOG_WIDTH)
  }
}

@CustomDialog
export struct globalDialog {
  @Link globalIsOn: boolean
  controller: CustomDialogController;

  build() {
    Flex({ justifyContent: FlexAlign.Center, alignItems: ((deviceInfo.deviceType == Constants.DEFAULT_DEVICE_TYPE)
            || (deviceInfo.deviceType == Constants.PHONE_DEVICE_TYPE)) ? ItemAlign.End : ItemAlign.Center }) {
      Column() {
        Text(globalThis.currentPermissionGroup == 'CAMERA' ? $r('app.string.close_camera') : $r('app.string.close_microphone'))
          .fontSize(Constants.TEXT_BIG_FONT_SIZE)
          .fontColor($r('app.color.label_color'))
          .fontWeight(FontWeight.Medium)
          .lineHeight(Constants.TEXT_BIG_LINE_HEIGHT)
          .height(Constants.ROW_HEIGHT)
          .width(Constants.FULL_WIDTH)
          .padding({ left: Constants.DIALOG_DESP_MARGIN_LEFT, right: Constants.DIALOG_DESP_MARGIN_RIGHT })
        Text(globalThis.currentPermissionGroup == 'CAMERA' ? $r('app.string.close_camera_desc') : $r('app.string.close_microphone_desc'))
          .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
          .fontColor($r('app.color.label_color'))
          .lineHeight(Constants.TEXT_LINE_HEIGHT)
          .width(Constants.FULL_WIDTH)
          .padding({ left: Constants.DIALOG_DESP_MARGIN_LEFT, right: Constants.DIALOG_DESP_MARGIN_RIGHT })
          .margin({ bottom: Constants.DIALOG_DESP_MARGIN_BOTTOM })
        Row() {
          Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Start }) {
            Button($r('app.string.cancel'))
              .fontSize(Constants.BUTTON_FONT_SIZE)
              .onClick(() => {
                this.cancel()
              }).customizeButton().margin({ left: Constants.BUTTON_MARGIN_LEFT })
            Text('|').fontSize(Constants.BUTTON_DIVIDER_FONT_SIZE).fontColor($r('app.color.divider_color'))
              .margin({ top: Constants.BUTTON_MARGIN_TOP })
            Button($r('app.string.close'))
              .fontSize(Constants.BUTTON_FONT_SIZE)
              .onClick(() => {
                this.confirm()
              }).customizeButton().margin({ right: Constants.BUTTON_MARGIN_RIGHT })
          }.height(Constants.ROW_HEIGHT)
        }
      }
      .backgroundColor($r('app.color.default_background_color'))
      .borderRadius(Constants.DIALOG_PRIVACY_BORDER_RADIUS)
      .width(Constants.DIALOG_PRIVACY_WIDTH)
      .margin({ bottom: Constants.DIALOG_MARGIN_BOTTOM })
    }.width(Constants.FULL_WIDTH)
    .height(Constants.FULL_HEIGHT)
  }

  confirm() {
    if(globalThis.currentPermissionGroup == 'CAMERA') {
      camera.getCameraManager(globalThis.context).then(cameraManager => {
        cameraManager.muteCamera(true)
        this.globalIsOn = false
        this.controller.close()
      })
    }else {
      var audioManager = audio.getAudioManager();
      let audioVolumeManager = audioManager.getVolumeManager();
      let groupid = audio.DEFAULT_VOLUME_GROUP_ID;
      audioVolumeManager.getVolumeGroupManager(groupid).then(audioVolumeGroupManager => {
        audioVolumeGroupManager.setMicrophoneMute(true).then(() => {
          this.globalIsOn = false
          this.controller.close()
        })
      })
    }
  }

  cancel() {
    this.controller.close()
  }
}
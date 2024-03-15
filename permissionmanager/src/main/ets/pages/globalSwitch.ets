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
import display from '@ohos.display';
import deviceInfo from '@ohos.deviceInfo';
import { Log } from '../common/utils/utils';
import { GlobalContext } from '../common/utils/globalContext';

const MICROPHONE = 'microphone';
const CAMERA = 'camera';
let bottomPopoverTypes = ['default', 'phone'];

@Extend(Button)function customizeButton() {
  .backgroundColor($r('sys.color.ohos_id_color_dialog_bg'))
  .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
  .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
  .fontWeight(FontWeight.Medium)
  .height(Constants.BUTTON_HEIGHT)
  .width(Constants.HALF_LENGTH)
}

@Entry
@Component
struct globalSwitch {
  private context = getContext(this) as common.ServiceExtensionContext;

  privacyDialogController: CustomDialogController | null = new CustomDialogController({
    builder: globalDialog(),
    autoCancel: false,
    alignment: DialogAlignment.Center,
    customStyle: true,
    cancel: () => { this.context.terminateSelf() }
  })

  build() {}

  aboutToAppear() {
    if (this.privacyDialogController !== null) {
      this.privacyDialogController.open();
    }
  }

  aboutToDisappear() {
    this.privacyDialogController = null;
  }
}

@CustomDialog
struct globalDialog {
  private context = getContext(this) as common.ServiceExtensionContext;
  @State isBottomPopover: boolean = true;
  @State globalState: string = GlobalContext.load('globalState');
  controller?: CustomDialogController

  build() {
    GridRow({
      columns: {
        xs: Constants.XS_COLUMNS,
        sm: Constants.SM_COLUMNS,
        md: Constants.MD_COLUMNS,
        lg: Constants.LG_COLUMNS
      },
      gutter: Constants.DIALOG_GUTTER
    }) {
      GridCol({
        span: {
          xs: Constants.XS_SPAN,
          sm: Constants.SM_SPAN,
          md: Constants.DIALOG_MD_SPAN,
          lg: Constants.DIALOG_LG_SPAN
        },
        offset: {
          xs: Constants.XS_OFFSET,
          sm: Constants.SM_OFFSET,
          md: Constants.DIALOG_MD_OFFSET,
          lg: Constants.DIALOG_LG_OFFSET
        }
      }) {
        Flex({
          justifyContent: FlexAlign.Center,
          alignItems: this.isBottomPopover ? ItemAlign.End : ItemAlign.Center
        }) {
          Column() {
            Text(this.globalState == MICROPHONE ? $r('app.string.global_title_microphone') :
              this.globalState == CAMERA ? $r('app.string.global_title_camera') :
              $r('app.string.global_title_camera_and_microphone'))
              .fontSize(Constants.TEXT_BIG_FONT_SIZE)
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
              .fontWeight(FontWeight.Medium)
              .lineHeight(Constants.TEXT_BIG_LINE_HEIGHT)
              .width(Constants.FULL_WIDTH)
              .padding({ left: Constants.DIALOG_DESP_MARGIN_LEFT, right: Constants.DIALOG_DESP_MARGIN_RIGHT,
                          top: Constants.ROW_PADDING_TOP, bottom: Constants.ROW_PADDING_BOTTOM})
            Text(this.globalState == MICROPHONE ? $r('app.string.global_desc_microphone') :
              this.globalState == CAMERA ? $r('app.string.global_desc_camera') :
              $r('app.string.global_desc_camera_and_microphone'))
              .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
              .lineHeight(Constants.TEXT_LINE_HEIGHT)
              .width(Constants.FULL_WIDTH)
              .padding({ left: Constants.DIALOG_DESP_MARGIN_LEFT, right: Constants.DIALOG_DESP_MARGIN_RIGHT })
              .margin({ bottom: Constants.DIALOG_DESP_MARGIN_BOTTOM })
            Row() {
              Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Start }) {
                Button($r('app.string.cancel'))
                  .onClick(() => {
                    this.cancel()
                  }).customizeButton()
                Divider()
                  .color($r('sys.color.ohos_id_color_list_separator'))
                  .vertical(true)
                  .height(Constants.DIVIDER_HEIGHT)
                  .margin({ top: Constants.BUTTON_MARGIN_TOP })
                  .opacity(0.2)
                Button($r('app.string.open'))
                  .onClick(() => {
                    this.accept()
                  }).customizeButton()
              }.height(Constants.ROW_HEIGHT)
              .margin({ left: Constants.BUTTON_MARGIN_LEFT, right: Constants.BUTTON_MARGIN_RIGHT })
            }
          }
          .backgroundColor($r('sys.color.ohos_id_color_dialog_bg'))
          .borderRadius(Constants.DIALOG_PRIVACY_BORDER_RADIUS)
          .width(Constants.FULL_WIDTH)
          .margin({ bottom: $r('sys.float.ohos_id_dialog_margin_bottom') })
          .clip(true)
        }.width(Constants.FULL_WIDTH)
        .height(Constants.FULL_HEIGHT)
      }
    }.margin({ left: this.isBottomPopover ? Constants.DIALOG_MARGIN_VERTICAL : Constants.DIALOG_MARGIN,
      right: this.isBottomPopover ? Constants.DIALOG_MARGIN_VERTICAL : Constants.DIALOG_MARGIN })
  }

  accept() {
    Log.info('global accept');
    if (this.globalState == MICROPHONE) {
      let audioManager = audio.getAudioManager();
      let audioVolumeManager = audioManager.getVolumeManager();
      let groupid = audio.DEFAULT_VOLUME_GROUP_ID;
      audioVolumeManager.getVolumeGroupManager(groupid).then(audioVolumeGroupManager => {
        audioVolumeGroupManager.setMicMute(false).then(() => {
          this.context.terminateSelf();
        })
      })
    } else if (this.globalState == CAMERA) {
      let cameraManager = camera.getCameraManager(GlobalContext.load('context'));
      cameraManager.muteCamera(false);
      this.context.terminateSelf();
    } else {
      let cameraManager = camera.getCameraManager(GlobalContext.load('context'));
      cameraManager.muteCamera(false);
      let audioManager = audio.getAudioManager();
      let audioVolumeManager = audioManager.getVolumeManager();
      let groupid = audio.DEFAULT_VOLUME_GROUP_ID;
      audioVolumeManager.getVolumeGroupManager(groupid).then(audioVolumeGroupManager => {
        audioVolumeGroupManager.setMicMute(false).then(() => {
          this.context.terminateSelf();
        })
      })
    }

  }

  cancel() {
    Log.info('global cancel');
    this.context.terminateSelf();
  }

  aboutToAppear() {
    try {
      let dis = display.getDefaultDisplaySync();
      let isVertical = dis.width > dis.height ? false : true;
      this.isBottomPopover = (bottomPopoverTypes.includes(deviceInfo.deviceType) && isVertical) ? true : false;
    } catch (exception) {
      Log.error('Failed to obtain the default display object. Code: ' + JSON.stringify(exception));
    };
  }

}
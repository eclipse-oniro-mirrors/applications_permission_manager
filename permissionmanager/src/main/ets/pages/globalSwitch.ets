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

import Constants from '../common/utils/constant';
import audio from '@ohos.multimedia.audio'
import camera from '@ohos.multimedia.camera';
import bundle from '@ohos.bundle';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import { Log } from '../common/utils/utils'

const MICROPHONE = 'microphone'
const CAMERA = 'camera'

@Extend(Button) function customizeButton() {
  .backgroundColor($r('app.color.default_background_color'))
  .fontColor($r('app.color.button_color'))
  .fontWeight(FontWeight.Medium)
  .height(Constants.BUTTON_HEIGHT)
  .width(Constants.BUTTON_WIDTH)
}

@Entry
@Component
struct globalSwitch {
  privacyDialogController: CustomDialogController = new CustomDialogController({
    builder: globalDialog(),
    autoCancel: false,
    alignment: DialogAlignment.Center,
    customStyle: true
  })

  build() {}

  aboutToAppear() {
    this.privacyDialogController.open()
  }
}

@CustomDialog
struct globalDialog {
  controller: CustomDialogController

  build() {
    GridRow({ columns: { xs: Constants.XS_COLUMNS, sm: Constants.SM_COLUMNS, md: Constants.MD_COLUMNS, lg: Constants.LG_COLUMNS }, gutter: Constants.DIALOG_GUTTER }) {
      GridCol({ span: { xs: Constants.XS_SPAN, sm: Constants.SM_SPAN, md: Constants.DIALOG_MD_SPAN, lg: Constants.DIALOG_LG_SPAN },
        offset: {xs: Constants.XS_OFFSET, sm: Constants.SM_OFFSET, md: Constants.DIALOG_MD_OFFSET, lg: Constants.DIALOG_LG_OFFSET} }) {
        Flex({ justifyContent: FlexAlign.Center, alignItems: globalThis.isBottomPopover ? ItemAlign.End : ItemAlign.Center }) {
          Column() {
            Text(globalThis.globalState == MICROPHONE ? $r('app.string.global_title_microphone') :
                globalThis.globalState == CAMERA ? $r('app.string.global_title_camera') :
              $r('app.string.global_title_camera_and_microphone'))
              .fontSize(Constants.TEXT_BIG_FONT_SIZE)
              .fontColor($r('app.color.label_color'))
              .fontWeight(FontWeight.Medium)
              .lineHeight(Constants.TEXT_BIG_LINE_HEIGHT)
              .width(Constants.FULL_WIDTH)
              .padding({ left: Constants.DIALOG_DESP_MARGIN_LEFT, right: Constants.DIALOG_DESP_MARGIN_RIGHT,
                          top: Constants.ROW_PADDING_TOP, bottom: Constants.ROW_PADDING_BOTTOM})
            Text(globalThis.globalState == MICROPHONE ? $r('app.string.global_desc_microphone') :
                globalThis.globalState == CAMERA ? $r('app.string.global_desc_camera') :
              $r('app.string.global_desc_camera_and_microphone'))
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
                Button($r('app.string.open'))
                  .fontSize(Constants.BUTTON_FONT_SIZE)
                  .onClick(() => {
                    this.accept()
                  }).customizeButton().margin({ right: Constants.BUTTON_MARGIN_RIGHT })
              }.height(Constants.ROW_HEIGHT)
            }
          }
          .backgroundColor($r('app.color.default_background_color'))
          .borderRadius(Constants.DIALOG_PRIVACY_BORDER_RADIUS)
          .width(Constants.FULL_WIDTH)
          .margin({ bottom: Constants.DIALOG_MARGIN_BOTTOM })
        }.width(Constants.FULL_WIDTH)
        .height(Constants.FULL_HEIGHT)
      }
    }.margin({ left: globalThis.isBottomPopover ? Constants.DIALOG_MARGIN_VERTICAL : Constants.DIALOG_MARGIN,
      right: globalThis.isBottomPopover ? Constants.DIALOG_MARGIN_VERTICAL : Constants.DIALOG_MARGIN })
  }

  accept() {
    Log.info('global accept')
    if(globalThis.globalState == MICROPHONE) {
      var audioManager = audio.getAudioManager();
      audioManager.setMicrophoneMute(false).then(() => {
        globalThis.globalContext.terminateSelf()
      })
    }else if(globalThis.globalState == CAMERA) {
      let cameraManager = camera.getCameraManager(globalThis.globalContext);
      cameraManager.muteCamera(false);
      globalThis.globalContext.terminateSelf();
    }else {
      let cameraManager = camera.getCameraManager(globalThis.globalContext);
      cameraManager.muteCamera(false)
      var audioManager = audio.getAudioManager();
      audioManager.setMicrophoneMute(false).then(() => {
        globalThis.globalContext.terminateSelf()
      })
    }

  }

  cancel() {
    Log.info('global cancel')
    globalThis.globalContext.terminateSelf()
  }

  aboutToAppear() {
    setTimeout(function() {
      globalThis.globalContext.terminateSelf()
    }, 1000 * 60)
    var acManager = abilityAccessCtrl.createAtManager()
    bundle.getApplicationInfo(Constants.BUNDLE_NAME, 0).then(data => {
      acManager.grantUserGrantedPermission(data.accessTokenId, "ohos.permission.MICROPHONE", 2)
    })
  }

}
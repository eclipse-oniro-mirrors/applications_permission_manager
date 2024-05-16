/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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
import bundleManager from '@ohos.bundle.bundleManager';
import Constants from '../common/utils/constant';
import rpc from '@ohos.rpc';
import window from '@ohos.window';
import common from '@ohos.app.ability.common';
import { BusinessError } from '@ohos.base';
import { Log } from '../common/utils/utils';
import { Param, WantInfo } from '../common/utils/typedef';

let storage = LocalStorage.getShared();
let want: WantInfo;
let win: window.Window;

@Entry(storage)
@Component
struct SecurityDialog {
  private context = getContext(this) as common.ServiceExtensionContext;
  @LocalStorageLink('want') want: WantInfo = new WantInfo([]);
  @LocalStorageLink('win') win: window.Window = {} as window.Window;

  securityDialogController: CustomDialogController | null = new CustomDialogController({
    builder: CustomSecurityDialog(),
    alignment: DialogAlignment.Bottom,
    customStyle: true,
    cancel: () => {
      let option = new rpc.MessageOption();
      let data = new rpc.MessageSequence();
      let reply = new rpc.MessageSequence();
      Promise.all([data.writeInterfaceToken(Constants.SEC_COMP_DIALOG_CALLBACK),
        data.writeInt(0)
      ]).then(() => {
        let proxy = want.parameters['ohos.ability.params.callback'].value as rpc.RemoteObject;
        if (proxy != undefined) {
          proxy.sendMessageRequest(Constants.RESULT_CODE, data, reply, option);
        }
      }).catch(() => {
        Log.error('write result failed!');
      })
      win.destroyWindow();
      this.context.terminateSelf();
    }
  })

  build() {}

  aboutToAppear() {
    if (this.securityDialogController !== null) {
      this.securityDialogController.open();
    }
    want = this.want;
    win = this.win;
  }

  aboutToDisappear() {
    this.securityDialogController = null;
  }
}

@CustomDialog
struct CustomSecurityDialog {
  private context = getContext(this) as common.ServiceExtensionContext;
  controller?: CustomDialogController;
  descriptor: string = ''
  @State appName: string = 'ToBeInstead';
  @State index: number = 0;

  securityParams : Array<Param> = [
    new Param(
      $r('app.media.ic_location'), $r('app.string.SecurityTitle_location'), 'app.string.SecurityDescription_location'
    ),
    new Param(
      $r('app.media.file'), $r('app.string.SecurityTitle_mediaFiles'), 'app.string.SecurityDescription_mediaFiles'
    )
  ]

  GetAppName() {
    let bundleName: string = want.parameters['ohos.aafwk.param.callerBundleName'];
    bundleManager.getApplicationInfo(bundleName, bundleManager.ApplicationFlag.GET_APPLICATION_INFO_DEFAULT)
      .then(data => {
        this.context.resourceManager.getStringValue(data.labelResource)
          .then(data => {
            this.appName = data;
          })
          .catch((error: BusinessError) => {
            Log.error('getStringValue failed. err is ' + JSON.stringify(error));
          });
      })
      .catch((error: BusinessError) => {
        Log.error('getApplicationInfo failed. err is ' + JSON.stringify(error));
      });
  }

  destruction() {
    let option = new rpc.MessageOption();
    let data = new rpc.MessageSequence();
    let reply = new rpc.MessageSequence();
    Promise.all([data.writeInterfaceToken(Constants.SEC_COMP_DIALOG_CALLBACK),
      data.writeInt(0)
    ]).then(() => {
      let proxy = want.parameters['ohos.ability.params.callback'].value as rpc.RemoteObject;
      if (proxy != undefined) {
        proxy.sendMessageRequest(Constants.RESULT_CODE, data, reply, option);
      }
    }).catch(() => {
      Log.error('write result failed!');
    })
    win.destroyWindow();
    this.context.terminateSelf();
  }

  build() {
    GridRow({
      columns: {
        xs: Constants.XS_COLUMNS, sm: Constants.SM_COLUMNS, md: Constants.MD_COLUMNS, lg: Constants.LG_COLUMNS
      },
      gutter: Constants.DIALOG_GUTTER
    }) {
      GridCol({
        span: {
          xs: Constants.XS_SPAN, sm: Constants.SM_SPAN, md: Constants.DIALOG_MD_SPAN, lg: Constants.DIALOG_LG_SPAN
        },
        offset: {
          xs: Constants.XS_OFFSET,
          sm: Constants.SM_OFFSET,
          md: Constants.DIALOG_MD_OFFSET,
          lg: Constants.DIALOG_LG_OFFSET
        }
      }) {
        Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
          Row() {
            Column() {
              Column() {
                Image($r('app.media.ic_public_privacy')) // icon
                  .width(Constants.SECURITY_ICON_WIDTH)
                  .height(Constants.SECURITY_ICON_HEIGHT)
                  .fillColor($r('sys.color.ohos_id_color_component_activated'))
                  .border({
                    width: Constants.BORDER_WIDTH_1,
                    color: $r('sys.color.ohos_id_color_button_normal'),
                    radius: $r('sys.float.ohos_id_corner_radius_default_m')
                  })
                  .padding(Constants.PADDING_10)
                Image(this.securityParams[this.index].icon)
                  .width(Constants.IMAGE_LENGTH_20)
                  .height(Constants.IMAGE_LENGTH_20)
                  .position({ x: Constants.IMAGE_POSITION_28, y: Constants.IMAGE_POSITION_28 })
              }
              .backgroundColor($r('sys.color.ohos_id_color_background'))
              .margin({
                top: Constants.SECURITY_ICON_MARGIN_TOP,
                bottom: Constants.SECURITY_ICON_MARGIN_BOTTOM
              })
              Column() { // content
                Text(this.securityParams[this.index].label)
                  .textAlign(TextAlign.Center)
                  .fontColor($r('sys.color.ohos_id_color_text_primary'))
                  .fontSize($r('sys.float.ohos_id_text_size_headline8'))
                  .fontWeight(FontWeight.Medium)
                  .lineHeight(Constants.TEXT_LINE_HEIGHT_27)

                Text($r(this.securityParams[this.index].description, this.appName))
                  .textAlign(TextAlign.Center)
                  .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .lineHeight(Constants.TEXT_SMALL_LINE_HEIGHT)
                  .margin({
                    top: Constants.SECURITY_DESCRIPTOR_DEVIDER_MARGIN_TOP,
                  })
              }
              Column() {
                Row() {
                  Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
                    Button($r('app.string.cancel')) // button
                      .fontSize($r('sys.float.ohos_id_text_size_button1'))
                      .fontWeight(FontWeight.Medium)
                      .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
                      .backgroundColor($r('sys.color.ohos_id_color_dialog_bg'))
                      .height(Constants.SECURITY_BUTTON_HEIGHT)
                      .width(Constants.FULL_WIDTH)
                      .onClick(() => {
                        if (this.controller !== undefined) {
                          this.controller.close();
                        }
                        win.destroyWindow();
                        this.context.terminateSelf();
                      })
                    Divider()
                      .color($r('sys.color.ohos_id_color_list_separator'))
                      .vertical(true)
                      .strokeWidth(Constants.DIALOG_DIVIDER)
                      .height(Constants.DIVIDER_HEIGHT)
                      .opacity(0.2)
                    Button($r('app.string.ALLOW')) // button
                      .fontSize($r('sys.float.ohos_id_text_size_button1'))
                      .fontWeight(FontWeight.Medium)
                      .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
                      .backgroundColor($r('sys.color.ohos_id_color_dialog_bg'))
                      .height(Constants.SECURITY_BUTTON_HEIGHT)
                      .width(Constants.FULL_WIDTH)
                      .onClick(() => {
                        if (this.controller !== undefined) {
                          this.controller.close();
                        }
                        this.destruction(); // Confirm authorization
                      })
                  }.margin({ left: Constants.BUTTON_MARGIN_LEFT, right: Constants.BUTTON_MARGIN_RIGHT })
                }
              }
              .margin({ top: Constants.SECURITY_BUTTON_MARGIN_TOP })
              .height(Constants.SECURITY_BUTTON_ROW_HEIGHT)
            }.margin({ left: Constants.SECURITY_TOTAL_MARGIN_LEFT, right: Constants.SECURITY_TOTAL_MARGIN_RIGHT })
          }
          .margin({ bottom: $r('sys.float.ohos_id_dialog_margin_bottom') })
          .backgroundColor($r('sys.color.ohos_id_color_dialog_bg'))
          .borderRadius(Constants.DIALOG_PRIVACY_BORDER_RADIUS)
        }.width(Constants.FULL_WIDTH)
        .height(Constants.FULL_HEIGHT)
      }
    }.margin({ left: Constants.DIALOG_MARGIN, right: Constants.DIALOG_MARGIN })
  }

  aboutToAppear() {
    Log.info('onAboutToAppear.');
    this.GetAppName();
    this.index = want.parameters['ohos.user.security.type'];
  }
}


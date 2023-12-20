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
import window from '@ohos.window';
import common from '@ohos.app.ability.common';
import display from '@ohos.display';
import deviceInfo from '@ohos.deviceInfo';
import { BusinessError } from '@ohos.base';
import { Log } from '../common/utils/utils';
import { param, wantInfo } from '../common/utils/typedef';

let bottomPopoverTypes = ['default', 'phone'];
let storage = LocalStorage.getShared();
let want: wantInfo;
let win: window.Window;

@Entry(storage)
@Component
struct SecurityDialog {
  private context = getContext(this) as common.ServiceExtensionContext;
  @LocalStorageLink('want') want: wantInfo = new wantInfo([]);
  @LocalStorageLink('win') win: window.Window = {} as window.Window;

  securityDialogController: CustomDialogController = new CustomDialogController({
    builder: CustomSecurityDialog(),
    alignment: DialogAlignment.Bottom,
    customStyle: true,
    cancel: () => {
      win.destroyWindow();
      this.context.terminateSelf();
    }
  })

  build() {}

  aboutToAppear() {
    this.securityDialogController.open();
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
  @State isBottomPopover: boolean = true;
  controller?: CustomDialogController;
  descriptor: string = ''
  @State appName: string = 'ToBeInstead';
  @State index: number = 0;
  @State naviHeight: number = 0

  securityParams : Array<param> = [
    new param($r('app.media.ic_public_gps'), $r('app.string.location_desc')),
    new param($r('app.media.ic_public_folder'), $r('app.string.media_files_desc'))
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
    win.destroyWindow();
    this.context.terminateSelf();
  }

  getAvoidWindow() {
    let type = window.AvoidAreaType.TYPE_SYSTEM;
    try {
      let avoidArea = win.getWindowAvoidArea(type);
      Log.info('avoidArea: ' + JSON.stringify(avoidArea));
      this.naviHeight = avoidArea.bottomRect.height;
    } catch (exception) {
      Log.error('Failed to obtain the area. Cause:' + JSON.stringify(exception));
    }
  }

  getPopupPosition() {
    try {
      let dis = display.getDefaultDisplaySync();
      let isVertical = dis.width > dis.height ? false : true;
      this.isBottomPopover = (bottomPopoverTypes.includes(deviceInfo.deviceType) && isVertical) ? true : false;
    } catch (exception) {
      Log.error('Failed to obtain the default display object. Code: ' + JSON.stringify(exception));
    };
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
        Flex({
          justifyContent: FlexAlign.Center,
          alignItems: this.isBottomPopover ? ItemAlign.End : ItemAlign.Center
        }) {
          Row() {
            Column() {
              Image(this.securityParams[this.index].icon) // icon
                .width(Constants.SECURITY_ICON_WIDTH)
                .height(Constants.SECURITY_ICON_HEIGHT)
                .fillColor($r('sys.color.ohos_id_color_text_primary'))
                .margin({
                  top: Constants.SECURITY_ICON_MARGIN_TOP,
                  bottom: Constants.SECURITY_ICON_MARGIN_BOTTOM
                })
              Column() { // content
                Text() {
                  Span($r('app.string.Temporarily_authorize'))
                  Span(this.appName)
                  Span($r('app.string.To_access'))
                  Span(this.securityParams[this.index].label)
                }
                  .textAlign(TextAlign.Center)
                  .fontColor($r('sys.color.ohos_id_color_text_primary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight(FontWeight.Medium)

                Text() {
                  Span($r('app.string.location_button_desc'))
                  Span($r('app.string.only_can_desc'))
                  Span(this.securityParams[this.index].label)
                  Span($r('app.string.only_after_desc'))
                  Span($r('app.string.prevent_desc'))
                }
                  .textAlign(TextAlign.Center)
                  .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: Constants.SECURITY_DESCRIPTOR_DEVIDER_MARGIN_TOP,
                  })
              }
              Column() {
                Button($r('app.string.Got_it')) // button
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
                    this.destruction();
                  })
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
    }.margin({ left: this.isBottomPopover ? Constants.DIALOG_MARGIN_VERTICAL : Constants.DIALOG_MARGIN,
      right: this.isBottomPopover ? Constants.DIALOG_MARGIN_VERTICAL : Constants.DIALOG_MARGIN,
      bottom: this.isBottomPopover ? this.naviHeight : 0})
  }

  aboutToAppear() {
    Log.info('onAboutToAppear.');
    this.getAvoidWindow();
    this.GetAppName();
    this.index = want.parameters['ohos.user.security.type'];
    this.getPopupPosition();
  }
}


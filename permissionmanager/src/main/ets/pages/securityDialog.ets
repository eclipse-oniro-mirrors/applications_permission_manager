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
import { Log } from '../common/utils/utils';

let storage = LocalStorage.GetShared();
let want: any = '';
let win: any = '';

interface param {
  'icon': Resource,
  'label': Resource
};

@Entry(storage)
@Component
struct SecurityDialog {
  @LocalStorageLink('want') want: Object = {};
  @LocalStorageLink('win') win: Object = {};

  securityDialogController: CustomDialogController = new CustomDialogController({
    builder: CustomSecurityDialog(),
    alignment: DialogAlignment.Bottom,
    customStyle: true
  })

  build() {}

  aboutToAppear() {
    this.securityDialogController.open();
    want = this.want;
    win = this.win;
  }
}

@CustomDialog
struct CustomSecurityDialog {
  controller: CustomDialogController;
  descriptor: string = ''
  @State appName: string = 'ToBeInstead';
  @State index: number = 0;
  @State naviHeight: number = 0

  securityParams : Array<param> = [
    {
      'icon': $r('app.media.ic_public_gps'),
      'label': $r('app.string.location_desc'),
    },
    {
      'icon': $r('app.media.ic_public_folder'),
      'label': $r('app.string.media_files_desc')
    }
  ]

  GetAppName() {
    let bundleName: string = want.parameters['ohos.aafwk.param.callerBundleName'];
    bundleManager.getApplicationInfo(bundleName, bundleManager.ApplicationFlag.GET_APPLICATION_INFO_DEFAULT)
      .then(data => {
        globalThis.securityContext.resourceManager.getStringValue(data.labelResource)
          .then(data => {
            this.appName = data;
          })
          .catch(error => {
            Log.error('getStringValue failed. err is ' + JSON.stringify(error));
          });
      })
      .catch(error => {
        Log.error('getApplicationInfo failed. err is ' + JSON.stringify(error));
      });
  }

  destruction() {
    win.destroy();
    globalThis.windowNum --;
    if (globalThis.windowNum == 0) {
      globalThis.extensionContext.terminateSelf();
    }
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
          alignItems: globalThis.isBottomPopover ? ItemAlign.End : ItemAlign.Center
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
                Text($r('app.string.Temporarily_authorize') + this.appName + $r('app.string.To_access')
                + this.securityParams[this.index].label)
                  .textAlign(TextAlign.Center)
                  .lineHeight($r('sys.float.ohos_id_text_line_space_l'))
                  .fontColor($r('sys.color.ohos_id_color_text_primary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontWeight(FontWeight.Medium)
                Text($r('app.string.only_can_desc') + '' + this.securityParams[this.index].label
                + $r('app.string.only_after_desc') + '' + $r('app.string.prevent_desc'))
                  .textAlign(TextAlign.Center)
                  .lineHeight($r('sys.float.ohos_id_text_line_space_l'))
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
                    this.controller.close();
                    this.destruction();
                  })
              }
              .margin({ top: Constants.SECURITY_BUTTON_MARGIN_TOP })
              .height(Constants.SECURITY_BUTTON_ROW_HEIGHT)
            }.margin({ left: Constants.SECURITY_TOTAL_MARGIN_LEFT, right: Constants.SECURITY_TOTAL_MARGIN_RIGHT })
          }
          .margin({ bottom: Constants.DIALOG_MARGIN_BOTTOM })
          .backgroundColor($r('sys.color.ohos_id_color_dialog_bg'))
          .borderRadius(Constants.DIALOG_PRIVACY_BORDER_RADIUS)
        }
      }
    }.margin({ left: globalThis.isBottomPopover ? Constants.DIALOG_MARGIN_VERTICAL : Constants.DIALOG_MARGIN,
      right: globalThis.isBottomPopover ? Constants.DIALOG_MARGIN_VERTICAL : Constants.DIALOG_MARGIN,
      bottom: globalThis.isBottomPopover ? this.naviHeight : 0})
  }

  aboutToAppear() {
    Log.info('onAboutToAppear.');
    this.getAvoidWindow();
    this.GetAppName();
    this.index = want.parameters['ohos.user.security.type'];
  }
}


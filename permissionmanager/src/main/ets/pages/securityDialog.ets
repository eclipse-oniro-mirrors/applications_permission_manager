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
import { CustomContentDialog } from '@ohos.arkui.advanced.Dialog';
import { Log } from '../common/utils/utils';
import { Param, WantInfo } from '../common/utils/typedef';

let storage = LocalStorage.getShared();

@Entry(storage)
@Component
struct SecurityDialog {
  private context = getContext(this) as common.ServiceExtensionContext;
  @LocalStorageLink('want') want: WantInfo = new WantInfo([]);
  @LocalStorageLink('win') win: window.Window = {} as window.Window;
  @State appName: string = 'ToBeInstead';
  @State index: number = 0;
  @State scrollBarWidth: number = Constants.SCROLL_BAR_WIDTH_DEFAULT;

  securityParams : Array<Param> = [
    new Param(
      $r('app.media.ic_location'), $r('app.string.SecurityTitle_location'), 'app.string.SecurityDescription_location'
    ),
    new Param(
      $r('app.media.file'), $r('app.string.SecurityTitle_mediaFiles'), 'app.string.SecurityDescription_mediaFiles'
    )
  ]

  dialogController: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      contentBuilder: () => {
        this.buildContent();
      },
      contentAreaPadding: { right: 0 },
      buttons: [
        {
          value: $r('app.string.cancel'),
          buttonStyle: ButtonStyleMode.TEXTUAL,
          action: () => {
            this.dialogController.close();
            this.win.destroyWindow();
            this.context.terminateSelf();
          }
        },
        {
          value: $r('app.string.ALLOW'),
          buttonStyle: ButtonStyleMode.TEXTUAL,
          action: () => {
            this.dialogController.close();
            this.destruction();
          }
        }
      ],
    }),
    cancel: () => {
      this.destruction();
    }
  });

  @Builder
  buildContent(): void {
    Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
      Scroll() {
        Column() {
          Column() {
            SymbolGlyph($r('sys.symbol.person_shield_fill'))
              .width(Constants.SECURITY_ICON_WIDTH)
              .height(Constants.SECURITY_ICON_HEIGHT)
              .fontSize(Constants.FONT_SIZE_28)
              .fontColor([$r('sys.color.brand')])
              .border({
                width: Constants.BORDER_WIDTH_1,
                color: $r('app.color.icon_border'),
                radius: $r('sys.float.ohos_id_corner_radius_default_m')
              })
              .padding(Constants.PADDING_10)
            Image(this.securityParams[this.index].icon)
              .width(Constants.IMAGE_LENGTH_20)
              .height(Constants.IMAGE_LENGTH_20)
              .position({ x: Constants.IMAGE_POSITION_28, y: Constants.IMAGE_POSITION_28 })
          }
          .backgroundColor($r('app.color.icon_bg'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
          Column() { // content
            Column() {
              Text(this.securityParams[this.index].label)
                .textAlign(TextAlign.Center)
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
                .fontSize($r('sys.float.ohos_id_text_size_headline8'))
                .fontWeight(FontWeight.Bold)
                .lineHeight(Constants.TEXT_LINE_HEIGHT_27)
            }
            .height(Constants.HEADLINE_HEIGHT)
            .padding({ top: Constants.PADDING_16, bottom: Constants.PADDING_16 })

            Text($r(this.securityParams[this.index].description, this.appName))
              .textAlign(TextAlign.Start)
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .lineHeight(Constants.TEXT_SMALL_LINE_HEIGHT)
          }
        }
        .clip(true)
      }
      .padding({ left: Constants.PADDING_24, right: Constants.PADDING_24 })
      .margin({ top: Constants.MARGIN_24 })
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false })
      .scrollBarWidth(this.scrollBarWidth)
      .onScrollStart(() => {
        this.scrollBarWidth = Constants.SCROLL_BAR_WIDTH_ACTIVE;
      })
      .onScrollStop(() => {
        this.scrollBarWidth = Constants.SCROLL_BAR_WIDTH_DEFAULT;
      })
    }
  }

  build() {}

  aboutToAppear() {
    Log.info('onAboutToAppear.');
    this.GetAppName();
    this.index = this.want.parameters['ohos.user.security.type'];
    this.dialogController.open();
  }

  GetAppName() {
    let bundleName: string = this.want.parameters['ohos.aafwk.param.callerBundleName'];
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
    Promise.all([
    data.writeInterfaceToken(Constants.SEC_COMP_DIALOG_CALLBACK),
    data.writeInt(0)
    ]).then(() => {
      let proxy = this.want.parameters['ohos.ability.params.callback'].value as rpc.RemoteObject;
      if (proxy != undefined) {
        proxy.sendMessageRequest(Constants.RESULT_CODE, data, reply, option);
      }
    }).catch(() => {
      Log.error('write result failed!');
    }).finally(() => {
      data.reclaim();
      reply.reclaim();
      this.win.destroyWindow();
      this.context.terminateSelf();
    })
  }
}
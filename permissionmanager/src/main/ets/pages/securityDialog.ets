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
import { Log, getFontSizeScale } from '../common/utils/utils';
import { Param, WantInfo } from '../common/model/typedef';
import { GlobalContext } from '../common/utils/globalContext';
import { preferences } from '@kit.ArkData';
import bundleResourceManager from '@ohos.bundle.bundleResourceManager';

let storage = LocalStorage.getShared();
const RESOURCE_TYPE: number = 10003;

@Extend(Text)function titleText() {
  .fontWeight(FontWeight.Bold)
  .fontColor($r('sys.color.font_primary'))
  .textAlign(TextAlign.Center)
  .textOverflow({ overflow: TextOverflow.Ellipsis })
  .maxLines(Constants.SECURITY_HEADER_MAX_LINES)
}

@Entry(storage)
@Component
struct SecurityDialog {
  private context = getContext(this) as common.ServiceExtensionContext;
  @LocalStorageLink('want') want: WantInfo = new WantInfo([]);
  @LocalStorageLink('win') win: window.Window = {} as window.Window;
  @LocalStorageLink('dataPreferences') dataPreferences: preferences.Preferences | null = null;
  @State appName: ResourceStr = 'Application';
  @State appIndex: number = 0;
  @State index: number = 0;
  @State scrollBarWidth: number = Constants.SCROLL_BAR_WIDTH_DEFAULT;

  securityParams : Array<Param> = [
    new Param(
      $r('app.media.ic_location'), $r('app.string.SecurityTitle_location'), 'app.string.SecurityDescription_location'
    ),
    new Param(
      $r('app.media.rawfile'), $r('app.string.SecurityTitle_mediaFiles'), 'app.string.SecurityDescription_mediaFiles'
    )
  ]

  dialogController: CustomDialogController | null = new CustomDialogController({
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
            this.dialogController?.close();
            this.win.destroyWindow();
            let dialogSet: Set<number> = GlobalContext.load('dialogSet');
            let callerToken: number = this.want.parameters['ohos.caller.uid'];
            dialogSet.delete(callerToken);
            GlobalContext.store('dialogSet', dialogSet);
            if (dialogSet.size === 0) {
              this.context.terminateSelf();
            }
          }
        },
        {
          value: $r('app.string.allow'),
          buttonStyle: ButtonStyleMode.TEXTUAL,
          action: () => {
            this.dialogController?.close();
            this.destruction();
          }
        }
      ],
    }),
    autoCancel: false,
    cancel: () => {
      this.win.destroyWindow();
      let dialogSet: Set<number> = GlobalContext.load('dialogSet');
      let callerToken: number = this.want.parameters['ohos.caller.uid'];
      dialogSet.delete(callerToken);
      GlobalContext.store('dialogSet', dialogSet);
      if (dialogSet.size === 0) {
        this.context.terminateSelf();
      }
    }
  });

  @Builder
  DialogTitle() {
    Column() {
      if (getFontSizeScale()) {
        Text(this.securityParams[this.index].label)
          .titleText()
          .fontSize($r('sys.float.Title_S'))
      } else {
        Text(this.securityParams[this.index].label)
          .titleText()
          .minFontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
          .maxFontSize($r('sys.float.Title_S'))
          .heightAdaptivePolicy(TextHeightAdaptivePolicy.MIN_FONT_SIZE_FIRST)
      }
    }
    .constraintSize({ minHeight: Constants.HEADLINE_HEIGHT })
    .justifyContent(FlexAlign.Center)
    .padding({
      top: Constants.DEFAULT_PADDING_TOP,
      bottom: Constants.DEFAULT_PADDING_BOTTOM,
    })
  }

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
                radius: Constants.SECURITY_ICON_WIDTH * 14 / 54
              })
              .padding(Constants.PADDING_10)
              .pixelRound({ start: PixelRoundCalcPolicy.NO_FORCE_ROUND, end: PixelRoundCalcPolicy.NO_FORCE_ROUND })
            if (this.index === 1) {
              Image(this.securityParams[this.index].icon)
                .width(Constants.IMAGE_LENGTH_20)
                .height(Constants.IMAGE_LENGTH_20)
                .syncLoad(true)
                .position({ x: Constants.IMAGE_POSITION_28, y: Constants.IMAGE_POSITION_28 })
                .border({
                  width: Constants.BORDER_WIDTH_1,
                  color: $r('app.color.icon_border'),
                  radius: Constants.IMAGE_LENGTH_20 * 14 / 54
                })
            } else {
              SymbolGlyph($r('sys.symbol.local_fill'))
                .width(Constants.IMAGE_LENGTH_20)
                .height(Constants.IMAGE_LENGTH_20)
                .fontSize(Constants.FONT_SIZE_12)
                .fontColor([Color.White])
                .backgroundColor($r('app.color.local_background_color'))
                .padding(Constants.PADDING_4)
                .position({ x: Constants.IMAGE_POSITION_28, y: Constants.IMAGE_POSITION_28 })
                .border({
                  width: Constants.BORDER_WIDTH_1,
                  color: $r('app.color.icon_border'),
                  radius: Constants.IMAGE_LENGTH_20 * 14 / 54
                })
            }
          }
          .pixelRound({ start: PixelRoundCalcPolicy.NO_FORCE_ROUND, end: PixelRoundCalcPolicy.NO_FORCE_ROUND })
          .backgroundColor($r('app.color.icon_bg'))
          .borderRadius(Constants.SECURITY_ICON_WIDTH * 14 / 54)
          Column() { // content
            this.DialogTitle();

            Text($r(this.securityParams[this.index].description, this.appName))
              .textAlign(TextAlign.Start)
              .fontColor($r('sys.color.font_primary'))
              .fontSize($r('sys.float.Body_L'))
              .lineHeight(Constants.TEXT_SMALL_LINE_HEIGHT)
              .maxFontScale(Constants.DIALOG_TEXT_MAX_SCALE)
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
    this.dialogController?.open();
    this.dataPreferences?.on('change', (key: string) => {
      Log.info('dataPreferences change.');
      this.appIndex === 0 ? null : this.GetAppName();
    })
  }

  aboutToDisappear() {
    this.dialogController = null;
  }

  GetAppName() {
    let uid: number = this.want.parameters['ohos.caller.uid'];
    try {
      bundleManager.getAppCloneIdentity(uid).then(cloneInfo => {
        Log.info(`getAppCloneIdentity: ${JSON.stringify(cloneInfo)}`);
        this.appIndex = cloneInfo.appIndex;
        cloneInfo.appIndex === 0 ? this.getSelfName(cloneInfo) : this.getCloneName(cloneInfo);
      }).catch((err: BusinessError) => {
        Log.error(`getAppCloneIdentity failed: ${JSON.stringify(err)}`);
      })
    } catch (err) {
      Log.error(`get appName failed: ${JSON.stringify(err)}`);
    }
  }

  getSelfName(cloneInfo: bundleManager.AppCloneIdentity) {
    try {
      bundleManager.getApplicationInfo(cloneInfo.bundleName, bundleManager.ApplicationFlag.GET_APPLICATION_INFO_DEFAULT)
        .then(data => {
          data.labelResource.params = [];
          data.labelResource.type = RESOURCE_TYPE;
          this.appName = data.labelResource;
        }).catch((error: BusinessError) => {
          Log.error('getApplicationInfo failed. err is ' + JSON.stringify(error));
        });
    } catch (err) {
      Log.error('getSelfName failed. err is ' + JSON.stringify(err));
    }
  }

  getCloneName(cloneInfo: bundleManager.AppCloneIdentity) {
    try {
      let resourceFlag = bundleResourceManager.ResourceFlag.GET_RESOURCE_INFO_ALL;
      let resourceInfo =
        bundleResourceManager.getBundleResourceInfo(cloneInfo.bundleName, resourceFlag, cloneInfo.appIndex);
      this.appName = resourceInfo?.label;
    } catch (err) {
      Log.error('getCloneName failed. err is ' + JSON.stringify(err));
    }
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
      let dialogSet: Set<number> = GlobalContext.load('dialogSet');
      let callerToken: number = this.want.parameters['ohos.caller.uid'];
      dialogSet.delete(callerToken);
      GlobalContext.store('dialogSet', dialogSet);
      if (dialogSet.size === 0) {
        this.context.terminateSelf();
      }
    })
  }
}

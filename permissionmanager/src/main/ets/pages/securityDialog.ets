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
import { Param, WantInfo, DialogInfo } from '../common/model/typedef';
import { GlobalContext } from '../common/utils/globalContext';
import bundleResourceManager from '@ohos.bundle.bundleResourceManager';
import deviceInfo from '@ohos.deviceInfo';

const RESOURCE_TYPE: number = 10003;

@Extend(Text)
function titleText(isWearable: boolean) {
  .fontWeight(FontWeight.Bold)
  .fontColor(isWearable ? '#FFFFFF' : $r('sys.color.font_primary'))
  .textAlign(TextAlign.Center)
  .textOverflow({ overflow: TextOverflow.Ellipsis })
  .maxLines(Constants.SECURITY_HEADER_MAX_LINES)
}

@Extend(Button)
function customizeButton() {
  .padding({
    left: Constants.PADDING_16,
    right: Constants.PADDING_16,
    top: Constants.PADDING_10,
    bottom: Constants.PADDING_10
  })
  .width(Constants.CUSTOMIZE_BUTTON_WIDTH)
  .margin({ bottom: Constants.MARGIN_12 })
}

@Extend(Text)
function customizeButtonText() {
  .minFontSize(Constants.CUSTOMIZE_BUTTON_TEXT_MIN_SIZE)
  .maxFontSize(Constants.CUSTOMIZE_BUTTON_TEXT_MAX_SIZE)
  .textAlign(TextAlign.Center)
  .fontSize(Constants.CUSTOMIZE_BUTTON_TEXT_MAX_SIZE)
  .fontWeight(FontWeight.Medium)
  .textOverflow({ overflow: TextOverflow.MARQUEE })
}

@Builder
function dialogTitle(index: number, securityParams: Array<Param>, isWearable: boolean) {
  Column() {
    if (getFontSizeScale()) {
      Text(securityParams[index].label)
        .titleText(isWearable)
        .fontSize($r('sys.float.Title_S'))
    } else {
      Text(securityParams[index].label)
        .titleText(isWearable)
        .minFontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
        .maxFontSize($r('sys.float.Title_S'))
        .heightAdaptivePolicy(TextHeightAdaptivePolicy.MAX_LINES_FIRST)
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
function dialogContentsArea(params: DialogInfo) {
  Column() {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.security_shield'))
          .fontSize(Constants.FONT_SIZE_28)
          .renderingStrategy(SymbolRenderingStrategy.MULTIPLE_COLOR)
          .fontColor(['#E5000000', '#0A59F7'])
      }
      .width(Constants.SECURITY_ICON_WIDTH)
      .height(Constants.SECURITY_ICON_HEIGHT)
      .justifyContent(FlexAlign.Center)
      .pixelRound({ start: PixelRoundCalcPolicy.NO_FORCE_ROUND, end: PixelRoundCalcPolicy.NO_FORCE_ROUND })
      .border({
        width: Constants.BORDER_WIDTH_1,
        color: $r('app.color.icon_border'),
        radius: Constants.SECURITY_ICON_WIDTH * 14 / 54
      })

      if (params.index === 1) {
        Image(params.securityParams[params.index].icon)
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
        Row() {
          SymbolGlyph($r('sys.symbol.local_fill'))
            .fontSize(Constants.FONT_SIZE_12)
            .fontColor([Color.White])
        }
        .width(Constants.IMAGE_LENGTH_20)
        .height(Constants.IMAGE_LENGTH_20)
        .justifyContent(FlexAlign.Center)
        .backgroundColor($r('app.color.local_background_color'))
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
    .margin(params.isWearable ? { top: Constants.MARGIN_12 } : {})

    Column() { // content
      dialogTitle(params.index, params.securityParams, params.isWearable);
      Text($r(
        params.securityParams[params.index].description,
        params.appName,
        params.appIndex === 0 ? '' : String(params.appIndex)
      ))
        .textAlign(params.isWearable ? TextAlign.Center : TextAlign.Start)
        .fontColor($r('sys.color.font_primary'))
        .fontSize($r('sys.float.Body_L'))
        .maxFontScale(Constants.DIALOG_TEXT_MAX_SCALE)
        .margin(params.isWearable ? {
          left: Constants.MARGIN_26,
          right: Constants.MARGIN_26,
          bottom: Constants.MARGIN_12
        } : {})
    }
  }
  .clip(true)
}

@CustomDialog
struct CustomDialogWearable {
  cancel?: () => void;
  confirm?: () => void;
  dialogControllerForWearable: CustomDialogController;
  @Link index: number;
  @Link appName: ResourceStr;
  @Link securityParams: Array<Param>;
  @Link isWearable: boolean;
  @Link appIndex: number;

  build() {
    Scroll() {
      Column() {
        dialogContentsArea({
          index: this.index,
          securityParams: this.securityParams,
          appName: this.appName,
          isWearable: this.isWearable,
          appIndex: this.appIndex
        })
        Button({ type: ButtonType.Capsule, stateEffect: true }) {
          Text($r('app.string.allow'))
            .customizeButtonText()
            .fontColor('#FFFFFF')
        }
        .customizeButton()
        .backgroundColor('#1F71FF')
        .onClick(() => {
          Log.info('Allow click start.');
          this.dialogControllerForWearable?.close();
          if (this.confirm) {
            this.confirm();
          }
        })

        Button({ type: ButtonType.Capsule, stateEffect: true }) {
          Text($r('app.string.cancel'))
            .customizeButtonText()
            .fontColor('#5EA1FF')
        }
        .customizeButton()
        .backgroundColor('#405EA1FF')
        .onClick(() => {
          Log.info('cancel click start.');
          this.dialogControllerForWearable?.close();
          if (this.cancel) {
            this.cancel();
          }
        })
      }
    }
    .edgeEffect(EdgeEffect.Spring)
    .backgroundColor(Color.Black)
    .width(Constants.FULL_WIDTH)
    .height(Constants.FULL_HEIGHT)
  }
}

@Entry({ useSharedStorage: true })
@Component
struct SecurityDialog {
  private context = this.getUIContext().getHostContext() as common.ServiceExtensionContext;
  @LocalStorageLink('want') want: WantInfo = new WantInfo([]);
  @LocalStorageLink('win') win: window.Window = {} as window.Window;
  @State appName: ResourceStr = 'Application';
  @State appIndex: number = 0;
  @State index: number = 0;
  @State scrollBarWidth: number = Constants.SCROLL_BAR_WIDTH_DEFAULT;
  @State isWearable: boolean = false;
  @State securityParams: Array<Param> = [
    new Param(
      $r('app.media.ic_location'), $r('app.string.SecurityTitle_location'), 'app.string.SecurityText_location'
    ),
    new Param(
      $r('app.media.rawfile'), $r('app.string.SecurityTitle_mediaFiles'), 'app.string.SecurityText_mediaFiles'
    )
  ]
  dialogControllerForWearable: CustomDialogController | null = new CustomDialogController({
    builder: CustomDialogWearable({
      cancel: () => {
        this.loadCancel();
      },
      confirm: () => {
        this.onAccept();
      },
      index: $index,
      appName: $appName,
      isWearable: $isWearable,
      securityParams: $securityParams,
      appIndex: $appIndex
    }),
    customStyle: true,
    cancel: () => {
      this.loadCancel();
    },
  })
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
            this.loadCancel();
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
      this.loadCancel();
    },
  });

  @Builder
  buildContent(): void {
    Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
      Scroll() {
        dialogContentsArea({
          index: this.index,
          securityParams: this.securityParams,
          appName: this.appName,
          isWearable: this.isWearable,
          appIndex: this.appIndex
        })
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

  build() {
  }

  async aboutToAppear() {
    Log.info('onAboutToAppear.');
    await this.GetAppName();
    this.index = this.want.parameters['ohos.user.security.type'];
    if (deviceInfo.deviceType === 'wearable') {
      this.dialogControllerForWearable?.open();
      this.isWearable = true;
    } else {
      this.dialogController?.open();
      this.isWearable = false;
    }
  }

  aboutToDisappear() {
    Log.info('aboutToDisappear.');
    this.dialogController = null;
    this.dialogControllerForWearable = null;
  }

  loadCancel() {
    Log.info('Callback when the first button is clicked.');
    this.win?.destroyWindow();
    let dialogSet: Set<String> = GlobalContext.load('dialogSet');
    let callerToken: number = this.want.parameters['ohos.caller.uid'];
    let windId: number = this.want.parameters['ohos.ability.params.windowId'];
    let token: String = String(callerToken) + '_' + String(windId);
    dialogSet.delete(token);
    GlobalContext.store('dialogSet', dialogSet);
    if (dialogSet.size === 0) {
      this.context.terminateSelf();
    }
  }

  onAccept() {
    Log.info('Callback when the second button is clicked.');
    this.destruction();
  }

  async GetAppName() {
    let uid: number = this.want.parameters['ohos.caller.uid'];
    try {
      const cloneInfo = await bundleManager.getAppCloneIdentity(uid);
      Log.info(`getAppCloneIdentity: ${JSON.stringify(cloneInfo)}.`);
      this.appIndex = cloneInfo.appIndex;
      await this.getSelfName(cloneInfo);
    } catch (err) {
      Log.error(`get appName failed: ${JSON.stringify(err)}.`);
    };
  }

  async getSelfName(cloneInfo: bundleManager.AppCloneIdentity) {
    try {
      const data = await bundleManager.getApplicationInfo(cloneInfo.bundleName,
        bundleManager.ApplicationFlag.GET_APPLICATION_INFO_DEFAULT);
      data.labelResource.params = [];
      data.labelResource.type = RESOURCE_TYPE;
      this.appName = data.labelResource;
    } catch (err) {
      Log.error(`getSelfName failed. err is ${JSON.stringify(err)}.`);
    };
  }

  getCloneName(cloneInfo: bundleManager.AppCloneIdentity) {
    try {
      let resourceFlag = bundleResourceManager.ResourceFlag.GET_RESOURCE_INFO_ALL;
      let resourceInfo =
        bundleResourceManager.getBundleResourceInfo(cloneInfo.bundleName, resourceFlag, cloneInfo.appIndex);
      this.appName = resourceInfo?.label;
    } catch (err) {
      Log.error(`getCloneName failed. err is ${JSON.stringify(err)}.`);
    };
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
      this.loadCancel();
    })
  }
}

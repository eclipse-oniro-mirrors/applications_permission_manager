/*
 * Copyright (c) 2021-2023 Huawei Device Co., Ltd.
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

import window from '@ohos.window';
import common from '@ohos.app.ability.common';
import Constants from '../common/utils/constant';
import { CustomContentDialog } from '@ohos.arkui.advanced.Dialog';
import { Log, getFontSizeScale, } from '../common/utils/utils';
import { EventObserver } from '../common/observer/EventObserver';
import { PermissionGroup, ButtonStatus } from '../common/model/definition';
import { CallerAppInfo, PermissionGroupConfig } from '../common/model/typedef';
import { LocationCanvas } from '../common/components/location';
import { buttonResource } from '../common/model/permissionGroup';
import { GrantDialogIntent } from '../ServiceExtAbility/GrantDialogIntent';
import { GrantDialogViewModel } from '../ServiceExtAbility/GrantDialogViewModel';
import { GrantDialogViewState } from '../ServiceExtAbility/GrantDialogViewState';

@Extend(Button)function customizeButton() {
  .buttonStyle(ButtonStyleMode.TEXTUAL)
  .fontColor($r('sys.color.font_emphasize'))
  .width(Constants.HALF_LENGTH)
}

@Extend(Text)function titleText() {
  .fontWeight(FontWeight.Bold)
  .fontColor($r('sys.color.font_primary'))
  .textAlign(TextAlign.Center)
  .textOverflow({ overflow: TextOverflow.Ellipsis })
  .maxLines(Constants.SECURITY_HEADER_MAX_LINES)
}

const EVENT_BUNDLE_RESOURCES_CHANGED = 'usual.event.BUNDLE_RESOURCES_CHANGED';

@Entry({ useSharedStorage: true })
@Component
struct dialogPlusPage {
  private context = this.getUIContext().getHostContext() as common.ServiceExtensionContext;
  private resourceChangeObserver: EventObserver = new EventObserver([EVENT_BUNDLE_RESOURCES_CHANGED]);
  @LocalStorageLink('callerAppInfo') callerAppInfo: CallerAppInfo = {} as CallerAppInfo;
  @LocalStorageLink('win') win: window.Window = {} as window.Window;
  @State viewModel: GrantDialogViewModel = new GrantDialogViewModel(this.callerAppInfo, this.win);
  @State viewState: GrantDialogViewState = this.viewModel.getViewState();
  private refreshData = (): void => {
    if (this.callerAppInfo === undefined) {
      Log.error(`event error, callerAppInfo is undefined.`);
      return;
    }
    try {
      this.viewModel.processIntent(
        new GrantDialogIntent.RefreshIntent(this.context, this.callerAppInfo)
      );
    } catch (error) {
      Log.error(`try to refresh data faild, code: ${error.code}, message: ${error.message}.`);
    }
  }

  dialogController: CustomDialogController | null = new CustomDialogController({
    builder: CustomContentDialog({
      contentBuilder: () => {
        this.buildContentComp();
      },
      contentAreaPadding: { right: 0 }
    }),
    autoCancel: false
  });

  @Builder
  DialogTitle() {
    Row() {
      Column() {
        if (getFontSizeScale()) {
          Text(this.viewState.grantGroups[this.viewState.curIndex].title)
            .titleText()
            .fontSize($r('sys.float.Title_S'))
        } else {
          Text(this.viewState.grantGroups[this.viewState.curIndex].title)
            .titleText()
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
        left: Constants.PADDING_24,
        right: Constants.PADDING_24
      })
    }
  }

  @Builder
  buildContentComp(): void {
    Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
      Column() {
          Image(this.viewState.grantGroups[this.viewState.curIndex].icon)
            .width(Constants.DIALOG_ICON_WIDTH)
            .height(Constants.DIALOG_ICON_HEIGHT)
            .fillColor($r('sys.color.font_primary'))
            .margin({ top: Constants.DIALOG_ICON_MARGIN_TOP })
          if (this.viewState.grantGroups.length > 1) {
            Text(`${this.viewState.curIndex + 1} / ${this.viewState.grantGroups.length}`)
              .fontSize(Constants.DIALOG_LABEL_FONT_SIZE)
              .fontColor($r('sys.color.font_secondary'))
              .lineHeight(Constants.DIALOG_LABEL_LINE_HEIGHT)
              .margin({ top: Constants.DIALOG_LABEL_MARGIN_TOP })
          }
          Scroll() {
            Column() {
              this.DialogTitle();

              Row() {
                Flex({ justifyContent: FlexAlign.Center }) {
                  Text() {
                      if (this.viewState.grantGroups[this.viewState.curIndex].readAndWrite) {
                        Span(this.viewState.grantGroups[this.viewState.curIndex].readAndWrite)
                        Span(this.viewState.grantGroups[this.viewState.curIndex].reason ? $r('app.string.comma') : $r('app.string.period'))
                      }
                      Span(this.showReason())
                  }
                  .textAlign(TextAlign.Start)
                  .fontColor($r('sys.color.font_primary'))
                  .fontSize($r('sys.float.Body_L'))
                  .maxFontScale(Constants.DIALOG_TEXT_MAX_SCALE)
                  .margin({
                    left: Constants.MARGIN_24,
                    right: Constants.MARGIN_24,
                    bottom: Constants.MARGIN_8
                  })
                }
              }

              if (
                this.viewState.locationFlag > Constants.LOCATION_NONE &&
                this.viewState.grantGroups[this.viewState.curIndex].groupName === PermissionGroup.LOCATION
              ) {
                LocationCanvas({ viewState: $viewState })
              }
            }
          }.constraintSize({ maxHeight: Constants.MAXIMUM_HEADER_HEIGHT })
          if (
            this.viewState.grantGroups[this.viewState.curIndex].buttonList.length <= 2 &&
            this.calculateButtonWidth(this.viewState.grantGroups[this.viewState.curIndex].buttonList)
          ) {
            //横向布局
            Row() {
              Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
                Button(buttonResource.get(this.viewState.grantGroups[this.viewState.curIndex].buttonList[0]))
                  .customizeButton()
                  .onClick(() => {
                    this.processClick(this.viewState.grantGroups[this.viewState.curIndex].buttonList[0]);
                  })
                Divider()
                  .color($r('sys.color.comp_divider'))
                  .vertical(true)
                  .strokeWidth(Constants.DIALOG_DIVIDER)
                  .height(Constants.DIVIDER_HEIGHT)
                  .opacity(0.2)
                  .margin({ left: Constants.MARGIN_8, right: Constants.MARGIN_8 })
                Button(buttonResource.get(this.viewState.grantGroups[this.viewState.curIndex].buttonList[1]))
                  .customizeButton()
                  .onClick(() => {
                    this.processClick(this.viewState.grantGroups[this.viewState.curIndex].buttonList[1]);
                  })
              }.margin({
                left: Constants.MARGIN_16,
                right: Constants.MARGIN_16,
                bottom: Constants.MARGIN_8
              })
            }
          } else {
            //纵向布局
            Column() {
              ForEach(
                this.viewState.grantGroups[this.viewState.curIndex].buttonList, (buttonStatus: ButtonStatus, idx: number
              ) => {
                Button(buttonResource.get(buttonStatus))
                  .customizeButton()
                  .width(Constants.FULL_WIDTH)
                  .margin({
                    bottom: idx + 1 < this.viewState.grantGroups[this.viewState.curIndex].buttonList.length ?
                      Constants.MARGIN_4 : 0
                  })
                  .onClick(() => {
                    this.processClick(buttonStatus);
                  })
              })
            }
            .padding({ left: Constants.PADDING_16, right: Constants.PADDING_16 })
          }
      }
      .padding({ bottom: Constants.PADDING_8 })
      .clip(true)
    }
  }

  build() {}

  showReason(): ResourceStr {
    if (this.viewState.grantGroups[this.viewState.curIndex].groupName === PermissionGroup.LOCATION) {
      if (
        (this.viewState.locationFlag === Constants.LOCATION_FUZZY) ||
        (this.viewState.locationFlag === Constants.LOCATION_BOTH_FUZZY)
      ) {
        return $r('app.string.close_exact_position');
      }
    }
    return this.viewState.grantGroups[this.viewState.curIndex].reason;
  }

  calculateButtonWidth(buttonStatus: ButtonStatus[]): boolean {
    let denyText = buttonResource.get(buttonStatus[0]);
    let allowText = buttonResource.get(buttonStatus[1]);
    let maxButtonTextLength = Math.max(
      this.getUIContext().getMeasureUtils().measureText({ textContent: denyText }),
      this.getUIContext().getMeasureUtils().measureText({ textContent: allowText })
    )

    Log.info(`px2vp(maxButtonTextLength): ${this.getUIContext().px2vp(maxButtonTextLength)}`);
    if (this.getUIContext().px2vp(maxButtonTextLength) > Constants.DIALOG_BUTTON_MAX_WIDTH) {
      return false;
    }

    return true;
  }

  aboutToAppear() {
    this.viewModel.processIntent(new GrantDialogIntent.InitIntent(this.context)).then(result => {
      this.dialogController?.open();
    })
    this.context.eventHub.on('refresh', () => {
      this.refreshData();
    })
    this.resourceChangeObserver.register(this.refreshData);
  }

  aboutToDisappear() {
    this.dialogController = null;
    this.context.eventHub.off('refresh');
    this.resourceChangeObserver.unregister();
  }

  processClick(buttonStatus: ButtonStatus) {
    let groupConfig: PermissionGroupConfig = this.viewState.grantGroups[this.viewState.curIndex];
    if (this.callerAppInfo === undefined) {
      Log.error(`processClick faild, callerAppInfo is undefined.`);
      return;
    }
    let clickIntent: GrantDialogIntent.ClickIntent =
      new GrantDialogIntent.ClickIntent(this.context, groupConfig, this.callerAppInfo, buttonStatus);
    this.viewModel.processIntent(clickIntent);
  }

}
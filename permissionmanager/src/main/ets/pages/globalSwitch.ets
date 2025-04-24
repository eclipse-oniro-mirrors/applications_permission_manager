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
import common from '@ohos.app.ability.common';
import { CustomContentDialog } from '@ohos.arkui.advanced.Dialog';
import { GlobalDialogModel } from '../GlobalExtAbility/GlobalDialogModel';
import { GlobalDialogViewState } from '../GlobalExtAbility/GlobalDialogViewState';

let globalDialogModel: GlobalDialogModel = new GlobalDialogModel();

@Entry({ useSharedStorage: true })
@Component
struct globalSwitch {
  private context = this.getUIContext().getHostContext() as common.ServiceExtensionContext;
  @LocalStorageLink('globalState') globalState: string = '';
  @State viewState: GlobalDialogViewState = globalDialogModel.initViewState(this.globalState);

  dialogController: CustomDialogController | null = new CustomDialogController({
    builder: CustomContentDialog({
      contentBuilder: () => {
        this.buildContent();
      },
      contentAreaPadding: { left: Constants.PADDING_24, right: Constants.PADDING_24 },
      buttons: [
        {
          value: $r('app.string.cancel'),
          buttonStyle: ButtonStyleMode.TEXTUAL,
          action: () => {
            this.context.terminateSelf();
          }
        },
        {
          value: $r('app.string.open'),
          buttonStyle: ButtonStyleMode.TEXTUAL,
          action: () => {
            globalDialogModel.setMuteState(this.context, this.globalState, false, true);
          }
        }
      ],
    }),
    autoCancel: false,
    cancel: () => {
      this.context.terminateSelf();
    }
  });

  @Builder
  buildContent(): void {
    Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
      Column() {
        Text(this.viewState.title)
          .fontSize(Constants.TEXT_BIG_FONT_SIZE)
          .fontColor($r('sys.color.font_primary'))
          .fontWeight(FontWeight.Medium)
          .lineHeight(Constants.TEXT_BIG_LINE_HEIGHT)
          .width(Constants.FULL_WIDTH)
          .padding({ top: Constants.PADDING_14, bottom: Constants.PADDING_14 })
        Text(this.viewState.text)
          .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
          .fontColor($r('sys.color.font_primary'))
          .lineHeight(Constants.TEXT_LINE_HEIGHT)
      }
      .clip(true)
    }
  }

  build() {}

  aboutToAppear() {
    this.dialogController?.open();
  }

  aboutToDisappear() {
    this.dialogController = null;
  }
}
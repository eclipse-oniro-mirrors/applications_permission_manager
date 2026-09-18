/*
 * Copyright (c) 2026 Huawei Device Co., Ltd.
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

import { CustomContentDialog } from '@ohos.arkui.advanced.Dialog';
import Constants from '../utils/constant';

/**
 * Build the shared content area for the "permission fixed by admin policy" dialog.
 */
@Builder
function permissionFixedDialogContent() {
  Column() {
    Text($r('app.string.permission_fixed_by_admin_policy_title'))
      .fontSize(Constants.TEXT_BIG_FONT_SIZE)
      .fontColor($r('sys.color.font_primary'))
      .fontWeight(FontWeight.Medium)
      .lineHeight(Constants.TEXT_BIG_LINE_HEIGHT)
      .width(Constants.FULL_WIDTH)
      .padding({ top: Constants.PADDING_14, bottom: Constants.PADDING_14 })
    Text($r('app.string.permission_fixed_by_admin_policy_message'))
      .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
      .fontColor($r('sys.color.font_primary'))
      .lineHeight(Constants.TEXT_LINE_HEIGHT)
  }
  .clip(true)
}

/**
 * Create the controller for the "permission fixed by admin policy" dialog.
 */
export function createPermissionFixedDialog(closeAction: () => void): CustomDialogController {
  return new CustomDialogController({
    builder: CustomContentDialog({
      contentBuilder: () => {
        permissionFixedDialogContent();
      },
      contentAreaPadding: { left: Constants.PADDING_24, right: Constants.PADDING_24 },
      buttons: [
        {
          value: $r('app.string.confirm'),
          buttonStyle: ButtonStyleMode.TEXTUAL,
          action: closeAction
        }
      ]
    }),
    autoCancel: true
  });
}

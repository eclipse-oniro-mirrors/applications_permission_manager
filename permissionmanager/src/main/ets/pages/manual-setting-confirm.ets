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
import common from '@ohos.app.ability.common';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import { CustomContentDialog } from '@ohos.arkui.advanced.Dialog';
import { BusinessError } from '@ohos.base';
import { GlobalContext } from '../common/utils/globalContext';
import { getPermissionLabel, Log } from '../common/utils/utils';
import { AppInfo } from '../common/model/typedef';
import { Permission } from '../common/model/definition';
import Constants from '../common/utils/constant';
import { getTextFromResource, resolveAppLabel } from '../common/utils/resourceDisplayUtils';

const PERMISSION_MANAGER_BUNDLE_NAME: string = 'com.ohos.permissionmanager';
const PERMISSION_MANAGER_MAIN_ABILITY: string = `${PERMISSION_MANAGER_BUNDLE_NAME}.MainAbility`;

@Entry
@Component
struct ManualSettingConfirmPage {
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;
  @State applicationInfo: AppInfo = GlobalContext.load('applicationInfo');
  @State targetPermission: Permission = GlobalContext.load('manualSettingTargetPermission') as Permission;
  @State applicationLabel: string = '';
  private hasOpenedDialog: boolean = false;

  dialogController: CustomDialogController | null = new CustomDialogController({
    builder: CustomContentDialog({
      contentBuilder: () => {
        this.buildDialogContent();
      },
      contentAreaPadding: { right: 0 },
      buttons: [
        {
          value: $r('app.string.cancel'),
          buttonStyle: ButtonStyleMode.TEXTUAL,
          action: () => {
            this.cancel();
          }
        },
        {
          value: $r('app.string.go_to_settings'),
          buttonStyle: ButtonStyleMode.TEXTUAL,
          fontColor: $r('sys.color.font_emphasize'),
          action: () => {
            this.goToPermissionDetail();
          }
        }
      ]
    }),
    autoCancel: false,
    customStyle: false,
    isModal: true,
    width: '99%',
    height: '99%'
  });

  async aboutToAppear(): Promise<void> {
    if (this.hasOpenedDialog) {
      return;
    }
    this.hasOpenedDialog = true;
    await this.initApplicationLabel();
    this.dialogController?.open();
  }

  private async initApplicationLabel(): Promise<void> {
    this.applicationLabel = this.applicationInfo?.label || this.applicationInfo?.bundleName || '';
    if (this.applicationInfo?.label) {
      return;
    }
    this.applicationLabel = await resolveAppLabel(this.context, this.applicationInfo);
  }

  private goToPermissionDetail(): void {
    this.dialogController?.close();
    Log.info(`ManualSettingConfirmPage goToPermissionDetail bundle=${this.applicationInfo?.bundleName}, permission=${this.targetPermission}`);
    this.context.startAbility({
      bundleName: PERMISSION_MANAGER_BUNDLE_NAME,
      abilityName: PERMISSION_MANAGER_MAIN_ABILITY,
      parameters: {
        bundleName: this.applicationInfo?.bundleName ?? '',
        targetPermission: this.targetPermission
      }
    }).then(() => {
      Log.info('ManualSettingConfirmPage start permission manager success');
      this.returnManualSettingResult(Constants.MANUAL_SETTING_USER_OPENED);
    }).catch((error: BusinessError) => {
      Log.error(`ManualSettingConfirmPage start permission manager failed: ${error.code} ${error.message}`);
      this.dialogController?.open();
    });
  }

  private getApplicationLabel(): string {
    return this.applicationLabel || this.applicationInfo?.label || this.applicationInfo?.bundleName || '';
  }

  private getPermissionDisplayName(): ResourceStr {
    return getPermissionLabel(this.targetPermission);
  }

  private getPrimaryPathText(): string {
    let prefix: string = getTextFromResource(this.context, $r('app.string.manual_setting_path_primary_prefix'));
    let permissionName: string = getTextFromResource(this.context, this.getPermissionDisplayName());
    return `${prefix}${permissionName} -> ${this.getApplicationLabel()}`;
  }

  private getSecondaryPathText(): string {
    let prefix: string = getTextFromResource(this.context, $r('app.string.manual_setting_path_secondary_prefix'));
    return `${prefix}${this.getApplicationLabel()}`;
  }

  private returnManualSettingResult(code: number): void {
    // Read the session from the dedicated key. Do not check globalThis.isUIExtensionMode:
    // starting MainAbility of this process may reset it before this callback runs.
    let session = globalThis.openSettingSession as UIExtensionContentSession;
    if (typeof session?.terminateSelfWithResult === 'function') {
      session.terminateSelfWithResult({
        resultCode: code === Constants.MANUAL_SETTING_USER_OPENED ? 0 : -1,
        want: {
          parameters: {
            'ohos.open.setting.result_code': code,
            'ohos.user.setting.permission.result': [],
            'ohos.user.setting.error_code': code,
          }
        }
      });
      return;
    }
    this.context.terminateSelf();
  }

  private cancel(): void {
    this.dialogController?.close();
    this.returnManualSettingResult(Constants.MANUAL_SETTING_USER_REJECTED);
  }

  @Builder
  private buildDialogContent() {
    Column({ space: 12 }) {
      Text($r('app.string.manual_setting_confirm_title'))
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .textAlign(TextAlign.Center)

      Text($r('app.string.manual_setting_confirm_message'))
        .fontSize(14)
        .fontColor($r('sys.color.font_secondary'))
        .width('100%')
        .textAlign(TextAlign.Center)

      Column({ space: 10 }) {
        Row() {
          Text($r('app.string.manual_setting_target_app'))
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width(88)
          Text(this.getApplicationLabel())
            .fontSize(14)
            .layoutWeight(1)
        }
        .width('100%')

        Row() {
          Text($r('app.string.manual_setting_target_permission'))
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width(88)
          Text(this.getPermissionDisplayName())
            .fontSize(14)
            .layoutWeight(1)
        }
        .width('100%')
      }
      .width('100%')
      .padding(14)
      .backgroundColor($r('sys.color.comp_background_secondary'))
      .borderRadius(16)

      Text($r('app.string.manual_setting_path_title'))
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .textAlign(TextAlign.Start)

      Text(this.getPrimaryPathText())
        .fontSize(14)
        .width('100%')
        .textAlign(TextAlign.Start)

      Text(this.getSecondaryPathText())
        .fontSize(14)
        .width('100%')
        .textAlign(TextAlign.Start)

      Text($r('app.string.manual_setting_confirm_tip'))
        .fontSize(12)
        .fontColor($r('sys.color.font_secondary'))
        .width('100%')
        .textAlign(TextAlign.Start)
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ left: 12, right: 12, top: 12, bottom: 0 })
    .constraintSize({ maxWidth: 1200 })
  }

  build() {
    Column() {
      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Transparent)
  }
}

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
import bundleManager from '@ohos.bundle.bundleManager';
import { GlobalContext } from '../common/utils/globalContext';
import { getPermissionGroup, Log } from '../common/utils/utils';
import { AppInfo, GroupInfo } from '../common/model/typedef';
import { Permission, PermissionGroup } from '../common/model/definition';
import Constants from '../common/utils/constant';
import { DeviceUtil } from '../common/utils/deviceUtil';
import { getPermissionReason, resolveAppLabel } from '../common/utils/resourceDisplayUtils';
import { PermissionGroupManager } from '../common/permissionGroupManager/PermissionGroupManager';

const PERMISSION_MANAGER_BUNDLE_NAME: string = 'com.ohos.permissionmanager';
const PERMISSION_MANAGER_MAIN_ABILITY: string = `${PERMISSION_MANAGER_BUNDLE_NAME}.MainAbility`;
const DIALOG_WIDTH_DEFAULT: string = '405vp';
const DIALOG_HEIGHT_DEFAULT: string = '285vp';
const TITLE_ICON_PANEL_SIZE: number = 32;
const TITLE_ICON_SIZE: number = 20;
const TITLE_ICON_OFFSET: number = 6;

@Entry
@Component
struct ManualSettingConfirmPage {
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;
  @State applicationInfo: AppInfo = GlobalContext.load('applicationInfo');
  @State targetPermission: Permission = GlobalContext.load('manualSettingTargetPermission') as Permission;
  @State applicationLabel: string = '';
  @State permissionReason: string = '';
  @State groupInfo: GroupInfo = getPermissionGroup(GlobalContext.load('manualSettingTargetPermission') as Permission);
  @State groupTitle: ResourceStr = '';
  private hasOpenedDialog: boolean = false;

  dialogController: CustomDialogController | null = new CustomDialogController({
    builder: CustomContentDialog({
      contentBuilder: () => {
        this.buildDialogContent();
      },
      contentAreaPadding: { left: 0, right: 0, top: 0, bottom: 0 },
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
    alignment: DialogAlignment.Center,
    maskColor: '#00000000',
    width: DIALOG_WIDTH_DEFAULT as Dimension,
    height: DIALOG_HEIGHT_DEFAULT as Dimension
  });

  async aboutToAppear(): Promise<void> {
    if (this.hasOpenedDialog) {
      return;
    }
    this.hasOpenedDialog = true;
    await this.initApplicationLabel();
    this.groupTitle = PermissionGroupManager.getInstance().getGroupTitleByPermission(this.targetPermission,
      this.getApplicationLabel());
    this.initPermissionReason();
    this.dialogController?.open();
  }

  private async initApplicationLabel(): Promise<void> {
    this.applicationLabel = this.applicationInfo?.label || this.applicationInfo?.bundleName || '';
    if (this.applicationInfo?.label) {
      return;
    }
    this.applicationLabel = await resolveAppLabel(this.context, this.applicationInfo);
  }

  private initPermissionReason(): void {
    let bundleName = this.applicationInfo?.bundleName;
    if (!bundleName) {
      return;
    }
    this.permissionReason = getPermissionReason(this.context, bundleName, this.targetPermission);
    if (this.permissionReason) {
      return;
    }
    try {
      let permissionDef = bundleManager.getPermissionDefSync(this.targetPermission);
      if (permissionDef?.descriptionId > 0) {
        this.permissionReason = this.context.resourceManager.getStringSync(permissionDef.descriptionId);
      }
    } catch (error) {
      let businessError = error as BusinessError;
      Log.error(`ManualSettingConfirmPage init permission reason failed: ${businessError.code} ${businessError.message}`);
    }
  }

  private goToPermissionDetail(): void {
    this.dialogController?.close();
    let redirectPermission: Permission = this.targetPermission;
    Log.info(`ManualSettingConfirmPage goToPermissionDetail bundle=${this.applicationInfo?.bundleName}, permission=${this.targetPermission}, redirect=${redirectPermission}`);
    this.context.startAbility({
      bundleName: PERMISSION_MANAGER_BUNDLE_NAME,
      abilityName: PERMISSION_MANAGER_MAIN_ABILITY,
      parameters: {
        bundleName: this.applicationInfo?.bundleName ?? '',
        targetPermission: redirectPermission
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

  private getJumpPathText(): ResourceStr {
    switch (this.groupInfo.name) {
      case PermissionGroup.HOOK_INPUT_EVENT:
        return $r('app.string.manual_settings_hook_input_dialog_desc_second');
      case PermissionGroup.CUSTOM_SCREEN_RECORDING:
        return $r('app.string.manual_settings_screen_share_dialog_desc_second');
      case PermissionGroup.CONTROL_DEVICE:
        return $r('app.string.manual_settings_control_device_dialog_desc_second');
      case PermissionGroup.FOLDER:
        return $r('app.string.manual_settings_folder_dialog_desc_second');
      default:
        return '';
    }
  }

  private returnManualSettingResult(code: number): void {
    // Read the session from the dedicated key. Do not check globalThis.isUIExtensionMode:
    // starting MainAbility of this process may reset it before this callback runs.
    // Destroy the carrier window first: if the session termination fails afterwards,
    // the session callbacks may never fire and the full-screen window would leak.
    globalThis.manualSettingDestroyCarrier?.();
    let session = globalThis.openSettingSession as UIExtensionContentSession;
    if (typeof session?.terminateSelfWithResult === 'function') {
      session.terminateSelfWithResult({
        resultCode: code === Constants.MANUAL_SETTING_USER_OPENED ? 1 : 0,
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
      Column({ space: 12 }) {
        Column() {
          Image(this.groupInfo.icon)
            .width(TITLE_ICON_SIZE)
            .height(TITLE_ICON_SIZE)
            .fillColor($r('sys.color.font_primary'))
            .offset({ x: TITLE_ICON_OFFSET, y: TITLE_ICON_OFFSET })
        }
        .width(TITLE_ICON_PANEL_SIZE)
        .height(TITLE_ICON_PANEL_SIZE)
        .backgroundColor($r('sys.color.ohos_id_color_panel_bg'))

        Text(this.groupTitle)
          .fontSize($r('sys.float.Title_S'))
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Center)
      .width('100%')
      .padding({ top: 12, bottom: 12 })

      Column() {
        if (this.permissionReason !== '') {
          Text(this.permissionReason)
            .fontSize($r('sys.float.Body_L'))
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))
            .textAlign(TextAlign.Center)
        }

        Text(this.getJumpPathText())
          .fontSize($r('sys.float.Body_L'))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .textAlign(TextAlign.Center)
          .margin({ top: this.permissionReason !== '' ? 8 : 0 })
      }
      .alignItems(HorizontalAlign.Center)
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ left: 24, right: 24, top: 24, bottom: 0 })
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

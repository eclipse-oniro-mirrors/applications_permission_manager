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

import { backBar } from '../common/components/backBar';
import { createPermissionFixedDialog } from '../common/components/permissionFixedDialog';
import common from '@ohos.app.ability.common';
import bundleManager from '@ohos.bundle.bundleManager';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import { BusinessError } from '@ohos.base';
import { showSubPermissionsGroup } from '../common/model/permissionGroup';
import {
  getDocumentsPermissionStatus,
  getFolderCheckboxInfo,
  getDocumentsPermissions,
  getFolderPermissions,
  hasDocumentAllFilesPermission,
  getMergedDocumentsStatus,
  isDocumentsMediaPermission,
  shouldShowFolderPermissionSection,
  updateFolderStatusByPermission
} from '../common/utils/documentsPermissionUtils';
import { Log, getPermissionLabel } from '../common/utils/utils';
import { isReadPermission, isReadWriteGroup, isWritePermission } from '../common/utils/permissionGroupUtils';
import { resolveAppLabel } from '../common/utils/resourceDisplayUtils';
import Constants from '../common/utils/constant';
import { MediaDocObj, RouterParams3, AppInfo, CheckboxInfo } from '../common/model/typedef';
import { GlobalContext } from '../common/utils/globalContext';
import { Permission, PermissionGroup } from '../common/model/definition';
import { PermissionUtils } from '../common/utils/permissionUtils';

const showPrecise: number[] = [Constants.PERMISSION_ALLOW, Constants.PERMISSION_ALLOWED_ONLY_DURING_USE];
let accessTokenId: number = 0;
let reqPermissionInfo: bundleManager.ReqPermissionDetail;

function isDisplayDocumentsGroup(currentGroup: string): boolean {
  return currentGroup === PermissionGroup.DOCUMENTS;
}

function isMergedDocumentsDisplayGroup(currentGroup: string): boolean {
  return isDisplayDocumentsGroup(currentGroup) && shouldShowFolderPermissionSection();
}

function isPureDocumentsDisplayGroup(currentGroup: string): boolean {
  return isDisplayDocumentsGroup(currentGroup) && !isMergedDocumentsDisplayGroup(currentGroup);
}

@Entry
@Component
struct mediaDocumentPage {
  private backTitle: ResourceStr = (this.getUIContext().getRouter().getParams() as RouterParams3).backTitle;
  private permissions: Permission[] = (this.getUIContext().getRouter().getParams() as RouterParams3).permission;
  private tokenId: number = (this.getUIContext().getRouter().getParams() as RouterParams3).tokenId;
  @State currentGroup: string = GlobalContext.load('currentPermissionGroup');
  @State folderStatus: boolean[] = GlobalContext.load('folderStatus');
  @State refresh: boolean = false;
  @State selected: number = 0; // Permission status array
  @State accurateIsOn: boolean = false;
  @State isRefreshReason: number = 0;
  @State statusBarHeight: number = 0;
  aboutToAppear(): void {
    this.statusBarHeight = (AppStorage.get('STATUS_BAR_HEIGHT') as number) ?? 0
  }

  getDocumentsStatus(): number {
    return getDocumentsPermissionStatus(this.tokenId, this.permissions);
  }

  build() {
    Column() {
      GridRow({ gutter: Constants.GUTTER, columns: {
        xs: Constants.XS_COLUMNS, sm: Constants.SM_COLUMNS, md: Constants.MD_COLUMNS, lg: Constants.LG_COLUMNS } }) {
        GridCol({
          span: { xs: Constants.XS_SPAN, sm: Constants.SM_SPAN, md: Constants.MD_SPAN, lg: Constants.LG_SPAN },
          offset: { xs: Constants.XS_OFFSET, sm: Constants.SM_OFFSET, md: Constants.MD_OFFSET, lg: Constants.LG_OFFSET }
        }) {
          Row() {
            Column() {
              Row() {
                backBar({ title: JSON.stringify(this.backTitle), recordable: false })
              }
              Row() {
                Column() {
                  mediaDocumentItem({
                    selected: $selected,
                    accurateIsOn: $accurateIsOn,
                    isRefreshReason: $isRefreshReason,
                    folderStatus: $folderStatus
                  })
                }.width(Constants.FULL_WIDTH)
              }
              .margin({ top: Constants.TITLE_MARGIN_BOTTOM })
              .layoutWeight(Constants.LAYOUT_WEIGHT)
            }
          }
          .height(Constants.FULL_HEIGHT)
          .width(Constants.FULL_WIDTH)
          .backgroundColor($r('sys.color.background_secondary'))
          .padding({top:this.statusBarHeight})
        }
      }.backgroundColor($r('sys.color.background_secondary'))
    }
  }

  onPageShow() {
    this.refreshStatus();
  }

  refreshStatus() {
    if (reqPermissionInfo) {
      this.isRefreshReason ++;
    }
    Log.info('Refresh permission status');
    let isGranted = this.currentGroup === 'LOCATION' ? Constants.PERMISSION_BAN : Constants.PERMISSION_ALLOW;
    let folderStatus = [false, false, false, false];
    let atManager = abilityAccessCtrl.createAtManager();
    if (isReadWriteGroup(this.currentGroup)) {
      let hasReadPermission = false;
      let hasWritePermission = false;
      let hasGrantedRead = false;
      let hasGrantedWrite = false;
      for (let i = 0; i < this.permissions.length; i++) {
        let permission = this.permissions[i];
        let res = atManager.verifyAccessTokenSync(this.tokenId, permission);
        if (isReadPermission(this.currentGroup, permission)) {
          hasReadPermission = true;
          if (res === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
            hasGrantedRead = true;
          }
        }
        if (isWritePermission(this.currentGroup, permission)) {
          hasWritePermission = true;
          if (res === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
            hasGrantedWrite = true;
          }
        }
      }
      if (hasReadPermission && hasGrantedRead && hasWritePermission && hasGrantedWrite) {
        this.refreshSelected(Constants.PERMISSION_ALLOW);
      } else if (hasReadPermission && hasGrantedRead) {
        this.refreshSelected(Constants.PERMISSION_READ_ONLY);
      } else if (hasWritePermission && hasGrantedWrite) {
        this.refreshSelected(Constants.PERMISSION_WRITE_ONLY);
      } else {
        this.refreshSelected(Constants.PERMISSION_BAN);
      }
      return;
    }
    for (let i = 0; i < this.permissions.length; i++) {
      let permission = this.permissions[i];
      if (this.currentGroup === 'LOCATION') {
        continue;
      }
      let res = atManager.verifyAccessTokenSync(this.tokenId, permission);
      if (res != abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        isGranted = Constants.PERMISSION_BAN;
      }
      if (
        (this.currentGroup === 'FOLDER' || isMergedDocumentsDisplayGroup(this.currentGroup)) &&
        res === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
      ) {
        updateFolderStatusByPermission(folderStatus, permission);
      }
    }
    Log.info('isGranted: ' + JSON.stringify(isGranted));
    this.folderStatus = folderStatus;
    if (isMergedDocumentsDisplayGroup(this.currentGroup)) {
      this.refreshSelected(getMergedDocumentsStatus(this.tokenId, this.permissions));
      return;
    }
    if (isPureDocumentsDisplayGroup(this.currentGroup)) {
      this.refreshSelected(this.getDocumentsStatus());
      return;
    }

    this.refreshSelected(isGranted);
  }

  refreshSelected(isGranted: number) {
    this.selected = isGranted;
    if (this.currentGroup === 'PASTEBOARD') {
      try {
        let acManager = abilityAccessCtrl.createAtManager();
        acManager.getPermissionFlags(this.tokenId, Permission.READ_PASTEBOARD).then(flag => {
          flag === Constants.PERMISSION_ALLOW_THIS_TIME ? this.selected = Constants.PERMISSION_ONLY_THIS_TIME : null;
        })
      } catch (err) {
        Log.error('getPermissionFlags error: ' + JSON.stringify(err));
      }
    }
    if (this.currentGroup === 'LOCATION') {
      try {
        let acManager = abilityAccessCtrl.createAtManager();
        let fuzzyState = acManager.verifyAccessTokenSync(this.tokenId, Permission.APPROXIMATELY_LOCATION);
        fuzzyState === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED ?
          this.selected = Constants.PERMISSION_ALLOWED_ONLY_DURING_USE : null;
        let accurateStatus = acManager.verifyAccessTokenSync(this.tokenId, Permission.LOCATION);
        this.accurateIsOn = (accurateStatus == abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) ? true : false;
        let backgroundState = acManager.verifyAccessTokenSync(this.tokenId, Permission.LOCATION_IN_BACKGROUND);
        backgroundState === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED ?
          this.selected = Constants.PERMISSION_ALLOW : null;
        acManager.getPermissionFlags(this.tokenId, Permission.APPROXIMATELY_LOCATION ).then(flag => {
          flag === Constants.PERMISSION_ALLOW_THIS_TIME ? this.selected = Constants.PERMISSION_ONLY_THIS_TIME : null;
        })
      } catch (err) {
        Log.error('change location status error: ' + JSON.stringify(err));
      }
    }
  }
}

@Component
struct mediaDocumentItem {
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;
  private backTitle: ResourceStr = (this.getUIContext().getRouter().getParams() as RouterParams3).backTitle;
  private bundleName: string = (this.getUIContext().getRouter().getParams() as RouterParams3).bundleName;
  private permissions: Permission[] = (this.getUIContext().getRouter().getParams() as RouterParams3).permission;
  private status: number = (this.getUIContext().getRouter().getParams() as RouterParams3).status;
  @State currentGroup: PermissionGroup = GlobalContext.load('currentPermissionGroup');
  @State applicationInfo: AppInfo = GlobalContext.load('applicationInfo');
  @Link folderStatus: boolean[];
  @State mediaDocListItem: MediaDocObj[] = []; // Permission information array
  @Link selected: number;
  @Link accurateIsOn: boolean;
  @State isRisk: boolean = false; // Whether it is a risky application
  @State isFixedByAdminPolicy: boolean = false; // Whether it is fixed by admin policy
  @State noForeground: boolean = false;
  @State isTouch: number = -1;
  @State isCheck: string = '';
  @State reason: string = '';
  @State label: string = '';
  @State version: string = '';
  @State permissionLabels: Array<ResourceStr> = [];
  @Link @Watch('updateReason') isRefreshReason: number;

  promptDialogController: CustomDialogController | null = createPermissionFixedDialog(() => {
    this.promptDialogController?.close();
  });

  getReadablePermissions(): Permission[] {
    return this.permissions.filter((permission) => isReadPermission(this.currentGroup, permission));
  }

  getWritablePermissions(): Permission[] {
    return this.permissions.filter((permission) => isWritePermission(this.currentGroup, permission));
  }
  //Only media
  getDocumentsMediaPermissions(): Permission[] {
    return this.permissions.filter((permission) => isDocumentsMediaPermission(permission));
  }

  getDocumentsPermissions(): Permission[] {
    return getDocumentsPermissions(this.permissions);
  }

  getFolderPermissions(): Permission[] {
    return getFolderPermissions(this.permissions);
  }

  shouldShowMergedFolderSection(): boolean {
    return isMergedDocumentsDisplayGroup(this.currentGroup) &&
      this.getFolderPermissions().length > 0;
  }

  getDocumentsAllFilesPermissions(): Permission[] {
    return this.getDocumentsPermissions().filter((permission) => !isDocumentsMediaPermission(permission));
  }

  async applyReadWritePermissionStatus(status: number) {
    this.selected = status;
    let grantedPermissions: Permission[] = [];
    if (status === Constants.PERMISSION_ALLOW) {
      grantedPermissions = [...this.getReadablePermissions(), ...this.getWritablePermissions()];
    } else if (status === Constants.PERMISSION_READ_ONLY) {
      grantedPermissions = this.getReadablePermissions();
    } else if (status === Constants.PERMISSION_WRITE_ONLY) {
      grantedPermissions = this.getWritablePermissions();
    }
    for (const permission of this.permissions) {
      if (grantedPermissions.includes(permission)) {
        await PermissionUtils.grantPermissionWithResult(permission, Constants.PERMISSION_FLAG, accessTokenId);
      } else {
        await PermissionUtils.revokePermissionWithResult(permission, Constants.PERMISSION_FLAG, accessTokenId);
      }
    }
  }

  async applyDocumentsPermissionStatus(status: number) {
    this.selected = status;
    let grantedPermissions: Permission[] = [];
    if (status === Constants.PERMISSION_ALLOW) {
      grantedPermissions = this.getDocumentsPermissions();
    } else if (status === Constants.PERMISSION_DOCUMENT_MEDIA_ONLY) {
      grantedPermissions = this.getDocumentsMediaPermissions();
    }
    for (const permission of this.getDocumentsPermissions()) {
      if (grantedPermissions.includes(permission)) {
        await PermissionUtils.grantPermissionWithResult(permission, Constants.PERMISSION_FLAG, accessTokenId);
      } else {
        await PermissionUtils.revokePermissionWithResult(permission, Constants.PERMISSION_FLAG, accessTokenId);
      }
    }
  }

  async applyFolderPermissionStatus(permission: Permission, isGranted: boolean) {
    if (isGranted) {
      await PermissionUtils.grantPermissionWithResult(permission, Constants.PERMISSION_FLAG, accessTokenId);
      updateFolderStatusByPermission(this.folderStatus, permission);
      return;
    }
    await PermissionUtils.revokePermissionWithResult(permission, Constants.PERMISSION_FLAG, accessTokenId);
    this.folderStatus = [...this.folderStatus];
    this.folderStatus[this.getCheckboxInfo(permission).index] = false;
  }

  /**
   * Update reason
   */
  updateReason() {
    bundleManager.getApplicationInfo(
      this.applicationInfo.bundleName, bundleManager.ApplicationFlag.GET_APPLICATION_INFO_DEFAULT
    ).then(appInfo => {
      this.applicationInfo.labelId = appInfo.labelId;
      this.applicationInfo.labelResource = appInfo.labelResource;
      resolveAppLabel(this.context, this.applicationInfo, this.applicationInfo.label).then((value) => {
        if (value !== '') {
          this.applicationInfo.label = value;
          GlobalContext.store('applicationInfo', this.applicationInfo);
          this.label = value;
        }
      });
    }).catch((error: BusinessError) => {
      Log.error('getApplicationInfo error: ' + JSON.stringify(error));
    })
    let context = this.context.createModuleContext(this.bundleName, reqPermissionInfo.moduleName);
    context.resourceManager.getStringValue(reqPermissionInfo.reasonId).then(value => {
      if (value !== undefined) {
        this.reason = value.slice(Constants.START_SUBSCRIPT, Constants.END_SUBSCRIPT);
      }
    })
  }

  getCheckboxInfo(permission: Permission): CheckboxInfo {
    return getFolderCheckboxInfo(permission);
  }

  getMediaDocList() {
    this.mediaDocListItem = [];
    if (isDisplayDocumentsGroup(this.currentGroup)) {
      let documentPermissions = this.getDocumentsPermissions();
      if (documentPermissions.length > 0) {
        this.mediaDocListItem.push(
          new MediaDocObj($r('app.string.allow'), documentPermissions, Constants.PERMISSION_ALLOW)
        );
        if (isPureDocumentsDisplayGroup(this.currentGroup) &&
          hasDocumentAllFilesPermission(documentPermissions)) {
          this.mediaDocListItem.push(
            new MediaDocObj(
              $r('app.string.media_only'),
              documentPermissions,
              Constants.PERMISSION_DOCUMENT_MEDIA_ONLY
            )
          );
        }
        this.mediaDocListItem.push(
          new MediaDocObj($r('app.string.ban'), documentPermissions, Constants.PERMISSION_BAN)
        );
      }
      return;
    }
    if (isReadWriteGroup(this.currentGroup)) {
      let readPermissions = this.getReadablePermissions();
      let writePermissions = this.getWritablePermissions();
      if (readPermissions.length > 0 && writePermissions.length > 0) {
        this.mediaDocListItem.push(
          new MediaDocObj(
            $r('app.string.read_and_modify'),
            [...readPermissions, ...writePermissions],
            Constants.PERMISSION_ALLOW
          )
        );
      }
      if (readPermissions.length > 0) {
        this.mediaDocListItem.push(
          new MediaDocObj($r('app.string.read_only'), readPermissions, Constants.PERMISSION_READ_ONLY)
        );
      }
      if (writePermissions.length > 0) {
        this.mediaDocListItem.push(
          new MediaDocObj($r('app.string.modify_only'), writePermissions, Constants.PERMISSION_WRITE_ONLY)
        );
      }
      this.mediaDocListItem.push(
        new MediaDocObj($r('app.string.ban'), this.permissions, Constants.PERMISSION_BAN)
      );
      return;
    }
    if (this.currentGroup == 'PASTEBOARD') {
      this.mediaDocListItem.push(
        new MediaDocObj($r('app.string.per_use_query'), this.permissions, Constants.PERMISSION_ONLY_THIS_TIME)
      );
      this.mediaDocListItem.push(
        new MediaDocObj($r('app.string.always_allow'), this.permissions, Constants.PERMISSION_ALLOW)
      );
      this.mediaDocListItem.push(
        new MediaDocObj($r('app.string.ban'), this.permissions, Constants.PERMISSION_BAN)
      );
    } else if (this.currentGroup == 'LOCATION') {
      this.mediaDocListItem.push(
        new MediaDocObj($r('app.string.per_inquiry'), this.permissions, Constants.PERMISSION_ONLY_THIS_TIME)
      );
      if (this.permissions.includes(Permission.LOCATION_IN_BACKGROUND)) {
        this.mediaDocListItem.push(
          new MediaDocObj($r('app.string.always_allow'), this.permissions, Constants.PERMISSION_ALLOW)
        );
      }
      if (this.permissions.includes(Permission.APPROXIMATELY_LOCATION)) {
        this.mediaDocListItem.push(
          new MediaDocObj(
            $r('app.string.allowed_only_during_use'),
            [Permission.APPROXIMATELY_LOCATION],
            Constants.PERMISSION_ALLOWED_ONLY_DURING_USE
          )
        );
      } else {
        this.noForeground = true;
      }
      this.mediaDocListItem.push(
        new MediaDocObj($r('app.string.ban'), this.permissions, Constants.PERMISSION_BAN)
      );
    } else {
      this.mediaDocListItem.push(
        new MediaDocObj($r('app.string.allow'), this.permissions, Constants.PERMISSION_ALLOW)
      );
      this.mediaDocListItem.push(
        new MediaDocObj($r('app.string.ban'), this.permissions, Constants.PERMISSION_BAN)
      );
    }
  }

  getReason() {
    this.label = this.applicationInfo.label;
    if (showSubPermissionsGroup.indexOf(this.currentGroup) != -1) {
      this.permissions.forEach((permission, idx) => {
        if (idx > 0) {
          this.permissionLabels.push($r('app.string.and'))
        }
        let label = getPermissionLabel(permission)
        this.permissionLabels.push(label);
      })
    }
    let hasReason = false;
    try {
      bundleManager.getBundleInfo(this.bundleName, bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_REQUESTED_PERMISSION)
        .then(info => {
          this.permissions.forEach(permission => {
            info.reqPermissionDetails.forEach(reqPermissionDetail => {
              if (reqPermissionDetail.name == permission) {
                Log.info('reqPermissionDetail: ' + JSON.stringify(reqPermissionDetail));
                let context = this.context.createModuleContext(this.bundleName, reqPermissionDetail.moduleName);
                context.resourceManager.getStringValue(reqPermissionDetail.reasonId).then(value => {
                  if (value !== undefined && !hasReason) {
                    this.reason = value.slice(Constants.START_SUBSCRIPT, Constants.END_SUBSCRIPT);
                    reqPermissionInfo = reqPermissionDetail;
                    hasReason = true;
                  }
                })
              }
            })
          })
        })
    } catch (error) {
      Log.error('getBundleInfo error in getReason: ' + JSON.stringify(error));
    }
  }

  /**
   * Lifecycle function, executed when the page is initialized
   */
  aboutToAppear() {
    this.getMediaDocList();
    this.getReason();

    try {
      bundleManager.getBundleInfo(this.bundleName, bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
        .then(res => {
          this.version = res.versionName;
          accessTokenId = res.appInfo.accessTokenId;
          let acManager = abilityAccessCtrl.createAtManager();
          let accurateStatus = acManager.verifyAccessTokenSync(res.appInfo.accessTokenId, Permission.LOCATION);
          this.accurateIsOn = (accurateStatus == abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) ? true : false;
          let getFlagPermission =
            this.currentGroup === 'LOCATION' ? Permission.APPROXIMATELY_LOCATION : this.permissions[0];
          acManager.getPermissionFlags(res.appInfo.accessTokenId, getFlagPermission).then((flag) => {
            Log.info(`getPermissionFlags success, data->${JSON.stringify(flag)}`);
            this.isRisk = (flag & Constants.PERMISSION_POLICY_FIXED) !== 0;
            this.isFixedByAdminPolicy = (flag & Constants.PERMISSION_FIXED_BY_ADMIN_POLICY) !== 0;
            (flag & Constants.PERMISSION_ALLOW_THIS_TIME) !== 0 ?
              this.selected = Constants.PERMISSION_ONLY_THIS_TIME : null;
          })
        }).catch((error: BusinessError) => {
          Log.error('bundle.getBundleInfo failed. Cause: ' + JSON.stringify(error));
        })
    } catch (err) {
      Log.error('bundle.getBundleInfo failed. Cause: ' + JSON.stringify(err));
    }
  }

  getFolderPermissionItems(): Permission[] {
    return isMergedDocumentsDisplayGroup(this.currentGroup) ? this.getFolderPermissions() : this.permissions;
  }

  getFullDiskPermission(): Permission | undefined {
    return this.getFolderPermissionItems().find((permission) => permission === Permission.ACCESS_USER_FULL_DISK);
  }

  getFolderDirectoryPermissionItems(): Permission[] {
    return this.getFolderPermissionItems().filter((permission) => permission !== Permission.ACCESS_USER_FULL_DISK);
  }

  @Builder
  buildAccessPermissionSubtitle(title: ResourceStr) {
    Row() {
      Text() {
        Span(title)
        Span($r('app.string.access_permission'))
      }
        .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
        .fontColor($r('sys.color.icon_secondary'))
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Start)
        .lineHeight(Constants.SUBTITLE_LINE_HEIGHT)
    }
    .width(Constants.FULL_WIDTH)
    .constraintSize({ minHeight: Constants.SUBTITLE_MIN_HEIGHT })
    .padding({
      top: Constants.SUBTITLE_PADDING_TOP,
      bottom: Constants.SUBTITLE_PADDING_BOTTOM,
      left: Constants.DEFAULT_PADDING_START,
      right: Constants.DEFAULT_PADDING_END
    })
  }

  @Builder
  buildFullDiskPermissionRow(fullDiskPermission: Permission) {
    Column() {
      Row() {
        Text($r('app.string.allow_full_disk_access'))
          .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
          .fontColor($r('sys.color.font_primary'))
          .fontWeight(FontWeight.Medium)
          .flexGrow(Constants.FLEX_GROW)
        Toggle({ type: ToggleType.Switch, isOn: this.folderStatus[this.getCheckboxInfo(fullDiskPermission).index] })
          .selectedColor($r('sys.color.icon_emphasize'))
          .switchPointColor($r('sys.color.comp_background_primary_contrary'))
          .padding({ right: 0 })
          .hitTestBehavior(HitTestMode.None)
      }
      .width(Constants.FULL_WIDTH)
      .height(Constants.LISTITEM_ROW_HEIGHT)
      .onClick(() => {
        if (this.isFixedByAdminPolicy) {
          this.promptDialogController?.open();
          return;
        }
        this.applyFolderPermissionStatus(
          fullDiskPermission, !this.folderStatus[this.getCheckboxInfo(fullDiskPermission).index]
        );
      })
    }
    .width(Constants.FULL_WIDTH)
    .padding({
      left: Constants.DEFAULT_PADDING_START,
      right: Constants.DEFAULT_PADDING_END,
      top: Constants.TERTIARY_LIST_PADDING_TOP,
      bottom: Constants.TERTIARY_LIST_PADDING_BOTTOM
    })
    .margin({
      top: Constants.TERTIARY_LISTITEM_MARGIN_TOP,
      bottom: Constants.TERTIARY_LISTITEM_MARGIN_TOP
    })
    .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
    .backgroundColor($r('sys.color.comp_background_list_card'))
  }

  @Builder
  buildFolderPermissionDescription() {
    Row() {
      Text($r('app.string.allow_full_disk_access_desc'))
        .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
        .fontColor($r('sys.color.font_secondary'))
        .lineHeight(Constants.TEXT_SMALL_LINE_HEIGHT)
    }
    .width(Constants.FULL_WIDTH)
    .constraintSize({ minHeight: Constants.SUBTITLE_MIN_HEIGHT })
    .padding({
      top: Constants.SUBTITLE_PADDING_TOP,
      bottom: Constants.SUBTITLE_PADDING_BOTTOM,
      left: Constants.DEFAULT_PADDING_START,
      right: Constants.DEFAULT_PADDING_END
    })
  }

  @Builder
  buildFolderPermissionList() {
    List() {
      ForEach(this.getFolderDirectoryPermissionItems(), (permission: Permission) => {
        ListItem() {
          Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
            Row() {
              Text(this.getCheckboxInfo(permission).label)
                .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
                .fontColor($r('sys.color.font_primary'))
                .fontWeight(FontWeight.Medium)
                .flexGrow(Constants.FLEX_GROW)
              Checkbox()
                .select(this.folderStatus[this.getCheckboxInfo(permission).index])
                .hitTestBehavior(HitTestMode.None)
            }
            .width(Constants.FULL_WIDTH)
            .height(Constants.LISTITEM_ROW_HEIGHT)
            .onClick(() => {
              if (this.isFixedByAdminPolicy) {
                this.promptDialogController?.open();
                return;
              }
              let targetStatus = !this.folderStatus[this.getCheckboxInfo(permission).index];
              this.applyFolderPermissionStatus(permission, targetStatus);
            })
          }
        }
        .padding({
          left: $r('sys.float.ohos_id_card_margin_start'),
          right: $r('sys.float.ohos_id_card_margin_end')
        })
        .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
        .margin({ top: Constants.TERTIARY_LISTITEM_MARGIN_TOP })
        .linearGradient((this.isCheck === permission) ? {
          angle: 90,
          direction: GradientDirection.Right,
          colors: [['#DCEAF9', 0.0], ['#FAFAFA', 1.0]]
        } : {
          angle: 90,
          direction: GradientDirection.Right,
          colors: []
        })
        .onTouch(event => {
          if (event === undefined) {
            return;
          }
          if (event.type === TouchType.Down) {
            this.isCheck = permission;
          }
          if (event.type === TouchType.Up) {
            this.isCheck = '';
          }
        })
      }, (permission: Permission) => JSON.stringify(permission))
    }
    .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
    .backgroundColor($r('sys.color.comp_background_list_card'))
    .padding(Constants.LIST_PADDING_TOP)
    .divider({
      strokeWidth: Constants.DIVIDER,
      color: $r('sys.color.comp_divider'),
      startMargin: Constants.DEFAULT_MARGIN_START,
      endMargin: Constants.DEFAULT_MARGIN_END
    })
    .margin({ top: Constants.TERTIARY_LISTITEM_MARGIN_TOP })
  }

  build() {
    Column() {
      Row() {
        Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
          Image(this.applicationInfo.icon)
            .width(Constants.TERTIARY_IMAGE_WIDTH)
            .height(Constants.TERTIARY_IMAGE_HEIGHT)
            .margin({ left: Constants.TERTIARY_IMAGE_MARGIN_LEFT, right: Constants.TERTIARY_IMAGE_MARGIN_RIGHT })
          Column() {
            Row() {
              Text(this.label)
                .maxLines(Constants.MAXIMUM_HEADER_LINES)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
                .fontColor($r('sys.color.font_primary'))
                .fontWeight(FontWeight.Bold)
                .textAlign(TextAlign.Start)
            }
            .width(Constants.TERTIARY_HALF_WIDTH)
            .margin({ bottom: Constants.TERTIARY_LABEL_MARGIN_BOTTOM })
            Row() {
              Text($r('app.string.version'))
                .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
                .fontColor($r('sys.color.font_secondary'))
                .textAlign(TextAlign.Start)
              Text(this.version)
                .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
                .fontColor($r('sys.color.font_secondary'))
                .textAlign(TextAlign.Start)
            }
            .width(Constants.TERTIARY_HALF_WIDTH)
          }
        }.margin({ left: Constants.TERTIARY_MARGIN_LEFT })
      }
      if (this.reason !== '' || this.permissionLabels.length > 0) {
        Row() {
          Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
            Row() {
              Text() {
                if (this.permissionLabels.length > 0) {
                  ForEach(this.permissionLabels, (item: ResourceStr) => {
                    Span(item)
                  })
                  Span(this.reason ? $r('app.string.comma') : $r('app.string.period'))
                }
                Span(this.reason)
              }
                .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
                .fontColor($r('sys.color.icon_secondary'))
                .textAlign(TextAlign.Start)
            }.margin({ left: Constants.TERTIARY_IMAGE_MARGIN_LEFT, right: Constants.TERTIARY_IMAGE_MARGIN_RIGHT })
          }
        }
        .margin({
          top: Constants.TERTIARY_ROW_MARGIN_TOP,
          left: Constants.DEFAULT_MARGIN_START,
          bottom: Constants.DEFAULT_MARGIN_BOTTOM
        })
      }
      if (this.isRisk) {
        Row() {
          Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
            Row() {
              Image($r('app.media.ic_public_fail'))
                .fillColor($r('sys.color.icon_secondary'))
                .width(Constants.TERTIARY_RADIO_IMAGE_WIDTH)
                .height(Constants.TERTIARY_RADIO_IMAGE_HEIGHT)
                .margin({ right: Constants.TERTIARY_IMAGE_MARGIN_RIGHT })
              Text($r('app.string.risk_warning'))
                .fontColor($r('sys.color.font_primary'))
                .fontSize($r('sys.float.ohos_id_text_size_body1'))
                .fontWeight(FontWeight.Regular)
            }.margin({ left: Constants.DEFAULT_PADDING_START, right: Constants.DEFAULT_PADDING_END })
          }
        }.backgroundColor($r('sys.color.interactive_click'))
        .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
        .padding({ top: Constants.DEFAULT_PADDING_TOP, bottom: Constants.DEFAULT_PADDING_BOTTOM })
        .margin({ left: Constants.DEFAULT_MARGIN_START, right: Constants.DEFAULT_MARGIN_END })
      }
      Column() {
        this.buildAccessPermissionSubtitle(this.backTitle)
        if (this.currentGroup === 'FOLDER') {
          if (this.getFullDiskPermission() !== undefined) {
            this.buildFullDiskPermissionRow(this.getFullDiskPermission() as Permission)
          }
          this.buildFolderPermissionList()
        } else if (this.mediaDocListItem.length > 0) {
          List() {
            ForEach(this.mediaDocListItem, (item: MediaDocObj) => {
              ListItem() {
                Column() {
                  Row() {
                    Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
                      Row() {
                        Text(item.name)
                          .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
                          .fontColor($r('sys.color.font_primary'))
                          .fontWeight(FontWeight.Medium)
                          .flexGrow(Constants.FLEX_GROW)
                        Radio({ value: 'Radio', group: 'radioGroup' })
                          .checked(item.index === this.selected)
                          .hitTestBehavior(HitTestMode.None)
                          .height(Constants.SHAPE_DIA)
                          .width(Constants.SHAPE_DIA)
                      }
                      .width(Constants.FULL_WIDTH)
                      .height(Constants.LISTITEM_ROW_HEIGHT)
                      .onClick(async () => {
                        if (this.isFixedByAdminPolicy) {
                          this.promptDialogController?.open();
                          return;
                        }
                        if (isReadWriteGroup(this.currentGroup)) {
                          await this.applyReadWritePermissionStatus(item.index);
                          return;
                        }
                        if (this.currentGroup === 'DOCUMENTS') {
                          await this.applyDocumentsPermissionStatus(item.index);
                          return;
                        }
                        this.selected = item.index;
                        item.permissions.forEach((permission): boolean => {
                          if (item.index === Constants.PERMISSION_ALLOW) {
                            if (permission === Permission.LOCATION) {
                              return false;
                            }
                            PermissionUtils.grantPermissionWithResult(
                              permission, Constants.PERMISSION_FLAG, accessTokenId
                            );
                          } else if (item.index === Constants.PERMISSION_BAN) {
                            if (permission == Permission.LOCATION && this.accurateIsOn) {
                              PermissionUtils.revokePermissionWithResult(
                                permission, Constants.PERMISSION_FLAG, accessTokenId
                              );
                              this.accurateIsOn = false;
                            } else {
                              PermissionUtils.revokePermissionWithResult(
                                permission, Constants.PERMISSION_FLAG, accessTokenId
                              );
                            }
                          } else if (item.index === Constants.PERMISSION_ONLY_THIS_TIME) {
                            if (permission === Permission.LOCATION) {
                              return false;
                            }
                            PermissionUtils.revokePermissionWithResult(
                              permission, Constants.PERMISSION_ALLOW_THIS_TIME, accessTokenId
                            );
                          } else if (item.index === Constants.PERMISSION_ALLOWED_ONLY_DURING_USE) {
                            PermissionUtils.grantPermissionWithResult(
                              permission, Constants.PERMISSION_FLAG, accessTokenId
                            );
                            PermissionUtils.revokePermissionWithResult(
                              Permission.LOCATION_IN_BACKGROUND, Constants.PERMISSION_FLAG, accessTokenId
                            );
                          }
                          return true;
                        })
                      })
                    }
                  }
                }
              }
              .padding({
                left: $r('sys.float.ohos_id_card_margin_start'),
                right: $r('sys.float.ohos_id_card_margin_end')
              })
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
              .linearGradient((this.isTouch === item.index) ? {
                  angle: 90,
                  direction: GradientDirection.Right,
                  colors: [['#DCEAF9', 0.0], ['#FAFAFA', 1.0]]
                } : {
                  angle: 90,
                  direction: GradientDirection.Right,
                  colors: []
                })
              .onTouch(event => {
                if (event === undefined) {
                  return;
                }
                if (event.type === TouchType.Down) {
                  this.isTouch = item.index;
                }
                if (event.type === TouchType.Up) {
                  this.isTouch = -1;
                }
              })
              .margin({ top: Constants.TERTIARY_LISTITEM_MARGIN_TOP })
            }, (item: MediaDocObj) => JSON.stringify(item))
          }
          .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
          .backgroundColor($r('sys.color.comp_background_list_card'))
          .padding(Constants.LIST_PADDING_TOP)
          .divider({
            strokeWidth: Constants.DIVIDER,
            color: $r('sys.color.comp_divider'),
            startMargin: Constants.DEFAULT_MARGIN_START,
            endMargin: Constants.DEFAULT_MARGIN_END
          })
        }

        if (this.shouldShowMergedFolderSection()) {
          this.buildAccessPermissionSubtitle($r('app.string.group_name_folder'))
          if (this.getFullDiskPermission() !== undefined) {
            this.buildFullDiskPermissionRow(this.getFullDiskPermission() as Permission)
            this.buildFolderPermissionDescription()
          }
          this.buildFolderPermissionList()
        }

        if (this.permissions.includes(Permission.LOCATION) && showPrecise.includes(this.selected)) {
          Column() {
            Row() {
              Text($r('app.string.precise_location'))
                .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
                .fontColor($r('sys.color.font_primary'))
                .fontWeight(FontWeight.Medium)
                .flexGrow(Constants.FLEX_GROW)
              Toggle({ type: ToggleType.Switch, isOn: this.accurateIsOn })
                .selectedColor($r('sys.color.icon_emphasize'))
                .switchPointColor($r('sys.color.comp_background_primary_contrary'))
                .hitTestBehavior(HitTestMode.None)
            }.width(Constants.FULL_WIDTH)
            .height(Constants.LISTITEM_ROW_HEIGHT)
            .onClick(() => {
              if (this.isFixedByAdminPolicy) {
                this.promptDialogController?.open();
                return;
              }
              if (!this.accurateIsOn) {
                PermissionUtils.grantPermissionWithResult(
                  Permission.LOCATION, Constants.PERMISSION_FLAG, accessTokenId
                ).then((result) => {
                  this.accurateIsOn = result.operationResult === Constants.RESULT_SUCCESS;
                })
              } else {
                PermissionUtils.revokePermissionWithResult(
                  Permission.LOCATION, Constants.PERMISSION_FLAG, accessTokenId
                ).then((result) => {
                  this.accurateIsOn = result.operationResult !== Constants.RESULT_SUCCESS;
                })
              }
            })
          }.margin({ top: Constants.LOCATION_MARGIN_TOP, bottom: Constants.LOCATION_MARGIN_BOTTOM })
          .padding({
            left: Constants.DEFAULT_PADDING_START,
            right: Constants.DEFAULT_PADDING_END,
            top: Constants.TERTIARY_LIST_PADDING_TOP,
            bottom: Constants.TERTIARY_LIST_PADDING_BOTTOM
          })
          .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
          .backgroundColor($r('sys.color.comp_background_list_card'))

          Row() {
            Text($r('app.string.get_the_exact_position'))
              .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
              .fontColor($r('sys.color.font_secondary'))
              .lineHeight(Constants.TEXT_SMALL_LINE_HEIGHT)
          }.width(Constants.FULL_WIDTH)
          .padding({
            left: Constants.DEFAULT_PADDING_START,
            right: Constants.DEFAULT_PADDING_END,
          })
        }
      }
      .padding({
        left: Constants.LIST_PADDING_LEFT,
        right: Constants.LIST_PADDING_LEFT
      })
      .width(Constants.FULL_WIDTH)
      .height(Constants.FULL_HEIGHT)
      // Keep the container interactive when fixed by admin policy: tapping an option
      // opens the explanation dialog (see onClick guards). Disabling it here would
      // make those explanation branches unreachable.
      .enabled(!this.isRisk && !this.noForeground)
      .opacity((!this.isRisk && !this.noForeground && !this.isFixedByAdminPolicy) ? 1 : $r('sys.float.ohos_id_alpha_disabled'))
    }
    .width(Constants.FULL_WIDTH)
  }
}

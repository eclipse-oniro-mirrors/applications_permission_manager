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
import common from '@ohos.app.ability.common';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import bundleManager from '@ohos.bundle.bundleManager';
import { BusinessError } from '@ohos.base';
import { groups } from '../common/model/permissionGroup';
import Constants from '../common/utils/constant';
import { Log, verifyAccessToken } from '../common/utils/utils';
import { buildGroupIds, collectSupportedUserPermissions } from '../common/utils/bundlePermissionCollector';
import {
  getDocumentsPermissionStatus,
  getFolderGroupStatus,
  getMergedDocumentsAndFolderStatus,
  isDocumentsOrFolderPermission,
  isFolderPermission,
  shouldShowFolderPermissionSection,
  updateFolderStatusByPermission
} from '../common/utils/documentsPermissionUtils';
import { isReadPermission, isReadWriteGroup, isWritePermission } from '../common/utils/permissionGroupUtils';
import { resolveAppIcon, resolveAppLabel } from '../common/utils/resourceDisplayUtils';
import { PermissionObj, AppInfo } from '../common/model/typedef';
import { GlobalContext } from '../common/utils/globalContext';
import { Permission, PermissionGroup } from '../common/model/definition';

@Entry
@Component
struct appNamePlusPage {
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;
  @State allowedListItem: PermissionObj[] = []; // Array of allowed permissions
  @State bannedListItem: PermissionObj[] = []; // array of forbidden permissions
  @State applicationInfo: AppInfo = GlobalContext.load('applicationInfo'); // Routing jump data
  @State bundleName: string = GlobalContext.load('bundleName');
  @State label: string = '';
  @State isTouch: string = '';
  @State isGranted: number = Constants.PERMISSION_ALLOW;
  @State folderStatus: boolean[] = [false, false, false, false];
  @State reqUserPermissions: Permission[] = [];
  @State statusBarHeight: number = 0;

  @Builder ListItemLayout(item: PermissionObj, status: number) {
    ListItem() {
      Row() {
        Column() {
          Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
            Row() {
              Text(item.groupName)
                .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
                .fontColor($r('sys.color.font_primary'))
                .fontWeight(FontWeight.Medium)
                .flexGrow(Constants.FLEX_GROW)
              SymbolGlyph($r('sys.symbol.chevron_forward'))
                .width(Constants.IMAGE_WIDTH)
                .height(Constants.IMAGE_HEIGHT)
                .fontSize(Constants.FONT_SIZE_18_vp)
                .fontColor([$r('sys.color.icon_tertiary')])
                .fontWeight(FontWeight.Medium)
            }
            .width(Constants.FULL_WIDTH)
            .height(Constants.LISTITEM_ROW_HEIGHT)
          }
        }.onClick(() => {
          this.openPermissionDetail(item, status);
        })
      }
    }.padding({ left: $r('sys.float.ohos_id_card_margin_start'), right: $r('sys.float.ohos_id_card_margin_end') })
    .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
    .linearGradient((this.isTouch === item.group) ? {
        angle: 90,
        direction: GradientDirection.Right,
        colors: [['#DCEAF9', 0.0], ['#FAFAFA', 1.0]]
      } : {
        angle: 90,
        direction: GradientDirection.Right,
        colors: [[$r('sys.color.comp_background_list_card'), 1], [$r('sys.color.comp_background_list_card'), 1]]
      })
    .onTouch(event => {
      if (event === undefined) {
        return;
      }
      if (event.type === TouchType.Down) {
        this.isTouch = item.group;
      }
      if (event.type === TouchType.Up) {
        this.isTouch = '';
      }
    })
  }

  async initApplicationInfo(info: AppInfo) {
    Log.info(`labelResource: ` + JSON.stringify(info.labelResource));
    info.label = await resolveAppLabel(this.context, info);
    info.icon = resolveAppIcon(this.context, info);
    this.reqUserPermissions = await collectSupportedUserPermissions(info.tokenId, info.permissions);
    info.permissions = this.reqUserPermissions;
    info.groupId = buildGroupIds(this.reqUserPermissions);
  }

  private openPermissionDetail(item: PermissionObj, status: number): void {
    GlobalContext.store('currentPermissionGroup', item.group);
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/application-tertiary',
      params: {
        bundleName: this.applicationInfo.bundleName,
        backTitle: item.groupName,
        permission: item.permission,
        status,
        tokenId: this.applicationInfo.tokenId
      }
    });
  }

  /**
   * Jump to the detail page of the target permission carried by the launch want,
   * consumed once so returning to this page does not trigger it again.
   */
  private navigateToTargetPermission(): void {
    let targetPermission = GlobalContext.load<string>('targetPermission');
    if (!targetPermission) {
      return;
    }
    GlobalContext.store('targetPermission', '');
    for (let i = 0; i < this.allowedListItem.length; i++) {
      if (this.allowedListItem[i].permission.indexOf(targetPermission) !== -1) {
        Log.info(`application-secondary navigate to allowed permission: ${targetPermission}`);
        this.openPermissionDetail(this.allowedListItem[i], Constants.PERMISSION_ALLOW);
        return;
      }
    }
    for (let i = 0; i < this.bannedListItem.length; i++) {
      if (this.bannedListItem[i].permission.indexOf(targetPermission) !== -1) {
        Log.info(`application-secondary navigate to banned permission: ${targetPermission}`);
        this.openPermissionDetail(this.bannedListItem[i], Constants.PERMISSION_BAN);
        return;
      }
    }
    Log.error(`application-secondary target permission not found: ${targetPermission}`);
  }

  /**
   * Get the merged document and folder permissions for the current application.
   */
  private getMergedDocumentsAndFolderPermissions(reqPermissions: Permission[]): Permission[] {
    return reqPermissions.filter((permission) => isDocumentsOrFolderPermission(permission));
  }

  private shouldMergeDocumentsAndFolderPermissions(): boolean {
    return shouldShowFolderPermissionSection();
  }

  /**
   * Compute the two-state status of the merged documents-and-folders entry and sync folder
   * selections.
   */
  private async getMergedDocumentsAndFolderGroupStatus(permissions: Permission[]): Promise<number> {
    this.folderStatus = [false, false, false, false];
    for (const permission of permissions) {
      let res = await verifyAccessToken(this.applicationInfo.tokenId, permission);
      if (res === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED && isFolderPermission(permission)) {
        updateFolderStatusByPermission(this.folderStatus, permission);
      }
    }
    return getMergedDocumentsAndFolderStatus(this.applicationInfo.tokenId, permissions);
  }

  private async getStandaloneFolderGroupStatus(permissions: Permission[]): Promise<number> {
    this.folderStatus = [false, false, false, false];
    for (const permission of permissions) {
      let res = await verifyAccessToken(this.applicationInfo.tokenId, permission);
      if (res === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        updateFolderStatusByPermission(this.folderStatus, permission);
      }
    }
    return getFolderGroupStatus(permissions, this.folderStatus);
  }

  /**
   * Initialize permission status information and group permission information
   */
  async initialPermissions() {
    if (this.bundleName && !this.applicationInfo.groupId.length) {
      await this.initApplicationInfo(this.applicationInfo);
    }
    let reqPermissions = this.applicationInfo.permissions;
    let reqGroupIds = this.applicationInfo.groupId;

    this.allowedListItem = [];
    this.bannedListItem = [];
    let documentsAndFolderHandled = false;

    for (let i = 0; i < reqGroupIds.length; i++) {
      let id = reqGroupIds[i];
      let groupName = groups[id].groupName;
      let group = groups[id].name;
      // Merge document and folder groups into one unified file permission entry on PC/tablet.
      if (this.shouldMergeDocumentsAndFolderPermissions() &&
        (group === PermissionGroup.DOCUMENTS || group === PermissionGroup.FOLDER)) {
        // Run the merge logic only once to avoid duplicate handling.
        if (documentsAndFolderHandled) {
          continue;
        }
        documentsAndFolderHandled = true;
        // Filter all document-related and folder-related permissions from the app request list.
        let mergedPermissions = this.getMergedDocumentsAndFolderPermissions(reqPermissions);
        if (mergedPermissions.length <= 0) {
          continue;
        }
        // Compute the merged grant status and update the status of each specific folder.
        let mergedStatus = await this.getMergedDocumentsAndFolderGroupStatus(mergedPermissions);
        // Add the unified file permission entry to the allowed or banned list by merged status.
        if (mergedStatus === Constants.PERMISSION_ALLOW) {
          this.allowedListItem.push(
            new PermissionObj($r('sys.string.ohos_desc_read_document'), mergedPermissions, PermissionGroup.DOCUMENTS)
          );
        } else {
          this.bannedListItem.push(
            new PermissionObj($r('sys.string.ohos_desc_read_document'), mergedPermissions, PermissionGroup.DOCUMENTS)
          );
        }
        // Store each folder status in the global context for the permission detail page.
        GlobalContext.store('folderStatus', this.folderStatus);
        continue;
      }
      let groupReqPermissions: Permissions[] = [];
      for (let j = 0; j < reqPermissions.length; j++) {
        let permission = reqPermissions[j];
        if (groups[id].permissions.indexOf(permission) != -1) {
          groupReqPermissions.push(permission);
        }
      }
      this.isGranted = group === 'LOCATION' ? Constants.PERMISSION_BAN : Constants.PERMISSION_ALLOW;
      this.folderStatus = [false, false, false, false];
      await this.getStatus(groupReqPermissions, group);

      if (
        (isReadWriteGroup(group) && this.isGranted !== Constants.PERMISSION_BAN) ||
        ((group === PermissionGroup.DOCUMENTS || group === PermissionGroup.FOLDER) &&
          this.isGranted !== Constants.PERMISSION_BAN) ||
        this.isGranted === Constants.PERMISSION_ALLOW ||
        this.isGranted === Constants.PERMISSION_ALLOWED_ONLY_DURING_USE
      ) {
        this.allowedListItem.push(new PermissionObj(groupName, groupReqPermissions, group));
      } else {
        this.bannedListItem.push(new PermissionObj(groupName, groupReqPermissions, group));
      }

      GlobalContext.store('folderStatus', this.folderStatus);
    }
  }

  async getStatus(groupReqPermissions: Permissions[], group: string) {
    if (group === 'LOCATION') {
      try {
        let acManager = abilityAccessCtrl.createAtManager();
        let fuzzyState = acManager.verifyAccessTokenSync(
          this.applicationInfo.tokenId, Permission.APPROXIMATELY_LOCATION
        );
        fuzzyState === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED ?
          this.isGranted = Constants.PERMISSION_ALLOWED_ONLY_DURING_USE : null;
        let backgroundState = acManager.verifyAccessTokenSync(
          this.applicationInfo.tokenId, Permission.LOCATION_IN_BACKGROUND
        );
        backgroundState === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED ?
          this.isGranted = Constants.PERMISSION_ALLOW : null;
        await acManager.getPermissionFlags(this.applicationInfo.tokenId, Permission.APPROXIMATELY_LOCATION )
        .then(flag => {
          flag === Constants.PERMISSION_ALLOW_THIS_TIME ? this.isGranted = Constants.PERMISSION_ONLY_THIS_TIME : null;
        })
      } catch (err) {
        Log.error('change location status error: ' + JSON.stringify(err));
      }
      GlobalContext.store('locationStatus', this.isGranted);
      return true;
    }
    if (group === PermissionGroup.DOCUMENTS && !this.shouldMergeDocumentsAndFolderPermissions()) {
      this.isGranted = getDocumentsPermissionStatus(this.applicationInfo.tokenId, groupReqPermissions as Permission[]);
      return true;
    }
    if (group === PermissionGroup.FOLDER && !this.shouldMergeDocumentsAndFolderPermissions()) {
      this.isGranted = await this.getStandaloneFolderGroupStatus(groupReqPermissions as Permission[]);
      return true;
    }
    if (isReadWriteGroup(group)) {
      let hasReadPermission = false;
      let hasWritePermission = false;
      let hasGrantedRead = false;
      let hasGrantedWrite = false;
      for (let i = 0; i < groupReqPermissions.length; i++) {
        let permission = groupReqPermissions[i] as Permission;
        let res = await verifyAccessToken(this.applicationInfo.tokenId, permission);
        if (isReadPermission(group, permission)) {
          hasReadPermission = true;
          if (res === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
            hasGrantedRead = true;
          }
        }
        if (isWritePermission(group, permission)) {
          hasWritePermission = true;
          if (res === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
            hasGrantedWrite = true;
          }
        }
      }
      if (hasReadPermission && hasGrantedRead && hasWritePermission && hasGrantedWrite) {
        this.isGranted = Constants.PERMISSION_ALLOW;
      } else if (hasReadPermission && hasGrantedRead) {
        this.isGranted = Constants.PERMISSION_ONLY_THIS_TIME;
      } else if (hasWritePermission && hasGrantedWrite) {
        this.isGranted = Constants.PERMISSION_ALLOWED_ONLY_DURING_USE;
      } else {
        this.isGranted = Constants.PERMISSION_BAN;
      }
      return true;
    }
    for (let i = 0; i < groupReqPermissions.length; i++) {
      let permission = groupReqPermissions[i];
      let res = await verifyAccessToken(this.applicationInfo.tokenId, permission);
      if (res != abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        this.isGranted = Constants.PERMISSION_BAN;
      }
      if (group === 'FOLDER' && res === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        switch (permission) {
          case Permission.READ_WRITE_DOWNLOAD_DIRECTORY:
            this.folderStatus[0] = true;
            break;
          case Permission.READ_WRITE_DESKTOP_DIRECTORY:
            this.folderStatus[1] = true;
            break;
          case Permission.READ_WRITE_DOCUMENTS_DIRECTORY:
            this.folderStatus[2] = true;
            break;
          case Permission.ACCESS_USER_FULL_DISK:
            this.folderStatus[3] = true;
            break;
        }
      }
    }
    return true;
  }

  /**
   * Lifecycle function, triggered once when this page is displayed
   */
  onPageShow() {
    this.initialPermissions().then(() => {
      this.navigateToTargetPermission();
    }).catch((error: BusinessError) => {
      Log.error(`application-secondary initialPermissions failed: ${error?.code} ${error?.message}`);
    });
    bundleManager.getApplicationInfo(
      this.applicationInfo.bundleName, bundleManager.ApplicationFlag.GET_APPLICATION_INFO_DEFAULT
    ).then(appInfo => {
      this.statusBarHeight = (AppStorage.get('STATUS_BAR_HEIGHT') as number) ?? 0
      let bundleContext = this.context.createBundleContext(this.applicationInfo.bundleName);
      bundleContext.resourceManager.getStringValue(appInfo.labelId, (error, value) => {
        if (value) {
          this.applicationInfo.label = value;
          GlobalContext.store('applicationInfo', this.applicationInfo);
          this.label = value
        }
      })
    }).catch((error: BusinessError) => {
      Log.error('getApplicationInfo error: ' + JSON.stringify(error));
    })
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
                backBar({ title: JSON.stringify(this.label || this.applicationInfo.label), recordable: false })
              }
              Row() {
                Column() {
                  if (!this.allowedListItem.length && !this.bannedListItem.length) {
                    Row() {
                      List() {
                        ListItem() {
                          Row() {
                            Column() {
                              Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
                                Row() {
                                  Column() {
                                    Row() {
                                      Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
                                        Text($r('app.string.no_permission'))
                                          .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
                                          .fontColor($r('sys.color.font_primary'))
                                      }.margin({ top: Constants.FLEX_MARGIN_TOP, bottom: Constants.FLEX_MARGIN_BOTTOM })
                                    }.height(Constants.FULL_HEIGHT)
                                  }.flexGrow(Constants.FLEX_GROW)
                                   .constraintSize({minHeight: Constants.CONSTRAINTSIZE_MINHEIGHT })
                                }
                                .width(Constants.FULL_WIDTH)
                                .height(Constants.LISTITEM_ROW_HEIGHT)
                              }
                            }
                          }
                        }.padding({ left: Constants.LISTITEM_PADDING_LEFT, right: Constants.LISTITEM_PADDING_RIGHT })
                      }
                      .backgroundColor($r('sys.color.comp_background_list_card'))
                      .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
                      .padding({ top: Constants.LIST_PADDING_TOP, bottom: Constants.LIST_PADDING_BOTTOM })
                    }.margin({ top: Constants.ROW_MARGIN_TOP })
                     .padding({
                       left: Constants.SECONDARY_LIST_PADDING_LEFT,
                       right: Constants.SECONDARY_LIST_PADDING_RIGHT
                     })
                  } else {
                    Scroll() {
                      List() {
                        if (this.allowedListItem.length) {
                          ListItem() {
                            Row() {
                              Text($r('app.string.allowed'))
                                .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
                                .fontColor($r('sys.color.font_secondary'))
                                .fontWeight(FontWeight.Medium)
                                .lineHeight(Constants.SUBTITLE_LINE_HEIGHT)
                            }.constraintSize({ minHeight: Constants.SUBTITLE_MIN_HEIGHT })
                            .width(Constants.FULL_WIDTH)
                            .padding({ top: Constants.SUBTITLE_PADDING_TOP, bottom: Constants.SUBTITLE_PADDING_BOTTOM,
                              left: Constants.SECONDARY_TEXT_MARGIN_LEFT})
                          }

                          ListItem() {
                            Row() {
                              List() {
                                ForEach(this.allowedListItem, (item: PermissionObj) => {
                                  this.ListItemLayout(item, Constants.PERMISSION_ALLOW)
                                }, (item: PermissionObj) => JSON.stringify(item))
                              }
                              .backgroundColor($r('sys.color.comp_background_list_card'))
                              .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
                              .padding(Constants.LIST_PADDING_TOP)
                              .divider({
                                strokeWidth: Constants.DIVIDER,
                                color: $r('sys.color.comp_divider'),
                                startMargin: Constants.DEFAULT_MARGIN_START,
                                endMargin: Constants.DEFAULT_MARGIN_END
                              })
                            }.margin({ top: Constants.ROW_MARGIN_TOP })
                            .padding({
                              left: Constants.SECONDARY_LIST_PADDING_LEFT,
                              right: Constants.SECONDARY_LIST_PADDING_RIGHT
                            })
                          }
                        }
                        if (this.bannedListItem.length) {
                          ListItem() {
                            Row() {
                              Text($r('app.string.banned'))
                                .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
                                .fontColor($r('sys.color.font_secondary'))
                                .fontWeight(FontWeight.Medium)
                                .lineHeight(Constants.SUBTITLE_LINE_HEIGHT)
                            }.constraintSize({ minHeight: Constants.SUBTITLE_MIN_HEIGHT })
                            .width(Constants.FULL_WIDTH)
                            .padding({ top: Constants.SUBTITLE_PADDING_TOP, bottom: Constants.SUBTITLE_PADDING_BOTTOM,
                              left: Constants.SECONDARY_TEXT_MARGIN_LEFT})
                          }

                          ListItem() {
                            Row() {
                              List() {
                                ForEach(this.bannedListItem, (item: PermissionObj) => {
                                  this.ListItemLayout(item, Constants.PERMISSION_BAN)
                                }, (item: PermissionObj) => JSON.stringify(item))
                              }
                              .backgroundColor($r('sys.color.comp_background_list_card'))
                              .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
                              .padding(Constants.LIST_PADDING_TOP)
                              .divider({
                                strokeWidth: Constants.DIVIDER,
                                color: $r('sys.color.comp_divider'),
                                startMargin: Constants.DEFAULT_MARGIN_START,
                                endMargin: Constants.DEFAULT_MARGIN_END
                              })
                            }.margin({ top: Constants.ROW_MARGIN_TOP })
                            .padding({
                              left: Constants.SECONDARY_LIST_PADDING_LEFT,
                              right: Constants.SECONDARY_LIST_PADDING_RIGHT
                            })
                          }
                        }
                      }
                    }.scrollBar(BarState.Off)
                  }
                }
                .width(Constants.FULL_WIDTH)
                .height(Constants.FULL_HEIGHT)
              }
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
}

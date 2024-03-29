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
import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import bundleManager from '@ohos.bundle.bundleManager';
import { BusinessError } from '@ohos.base';
import { groups, userGrantPermissions } from '../common/model/permissionGroup';
import Constants from '../common/utils/constant';
import { Log, verifyAccessToken, getGroupIdByPermission } from '../common/utils/utils';
import { PermissionObj, AppInfo } from '../common/utils/typedef';
import { GlobalContext } from '../common/utils/globalContext';

const FUZZY_LOCATION_PERMISSION = 'ohos.permission.APPROXIMATELY_LOCATION';
const PRECISE_LOCATION_PERMISSION = 'ohos.permission.LOCATION';
const BACKGROUND_LOCATION_PERMISSION = 'ohos.permission.LOCATION_IN_BACKGROUND';
const DOWNLOAD_PERMISSION = 'ohos.permission.READ_WRITE_DOWNLOAD_DIRECTORY';
const DESKTOP_PERMISSION = 'ohos.permission.READ_WRITE_DESKTOP_DIRECTORY';
const DOCUMENTS_PERMISSION = 'ohos.permission.READ_WRITE_DOCUMENTS_DIRECTORY';
const allowedStatus = 0; // Status: Allowed
const bannedStatus = 1; // Status: Banned

@Entry
@Component
struct appNamePlusPage {
  private context = getContext(this) as common.UIAbilityContext;
  @State allowedListItem: PermissionObj[] = []; // Array of allowed permissions
  @State bannedListItem: PermissionObj[] = []; // array of forbidden permissions
  @State applicationInfo: AppInfo = GlobalContext.load('applicationInfo'); // Routing jump data
  @State bundleName: string = GlobalContext.load('bundleName');
  @State label: string = '';
  @State isTouch: string = '';
  @State isGranted: boolean = false;
  @State folderStatus: boolean[] = [false, false, false];
  @State reqUserPermissions: Permissions[] = [];

  @Builder ListItemLayout(item: PermissionObj, status: number) {
    ListItem() {
      Row() {
        Column() {
          Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
            Row() {
              Text(item.groupName)
                .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
                .fontWeight(FontWeight.Medium)
                .flexGrow(Constants.FLEX_GROW)
              Image($r('app.media.ic_public_arrow_right'))
                .fillColor($r('sys.color.ohos_id_color_tertiary'))
                .objectFit(ImageFit.Contain)
                .height(Constants.IMAGE_HEIGHT)
                .width(Constants.IMAGE_WIDTH)
                .draggable(false)
            }
            .width(Constants.FULL_WIDTH)
            .height(Constants.LISTITEM_ROW_HEIGHT)
          }
        }.onClick(() => {
          GlobalContext.store('currentPermissionGroup', item.group);
          router.pushUrl({
            url: item.group == 'OTHER' ? 'pages/other-permissions' : 'pages/application-tertiary',
            params: {
              bundleName: this.applicationInfo.bundleName,
              backTitle: item.groupName,
              permission: item.permission,
              status: !status ? allowedStatus : bannedStatus,
              tokenId: this.applicationInfo.tokenId
            }
          });
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
        colors: [[$r('sys.color.ohos_id_color_list_card_bg'), 1], [$r('sys.color.ohos_id_color_list_card_bg'), 1]]
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

  async getReqUserPermissions(info: AppInfo) {
    let acManager = abilityAccessCtrl.createAtManager();
    if (info.permissions.length > 0) {
      for (let j = 0; j < info.permissions.length; j++) {
        let permission = info.permissions[j];
        if (userGrantPermissions.indexOf(permission) == -1) {
          continue;
        }
        if ((info.api < Constants.API_VERSION_SUPPORT_STAGE) && (permission == FUZZY_LOCATION_PERMISSION)) {
          continue;
        }
        try {
          let flag = await acManager.getPermissionFlags(info.tokenId, permission);
          if (flag == Constants.PERMISSION_SYSTEM_FIXED) {
            continue;
          }
        } catch (err) {
          Log.error('getPermissionFlags error: ' + JSON.stringify(err));
        }
        this.reqUserPermissions.push(permission);
      }
    }
  }

  async initApplicationInfo(info: AppInfo) {
    Log.info(`labelResource: ` + JSON.stringify(info.labelResource));
    let resourceManager = this.context.createBundleContext(info.bundleName).resourceManager;

    if (info.labelResource.id !== 0) {
      info.label = await this.context.resourceManager.getStringValue(info.labelResource);
    } else {
      info.label = await resourceManager.getStringValue(info.labelId);
    }

    try {
      if (info.iconResource.id !== 0) {
        let iconDescriptor = this.context.resourceManager.getDrawableDescriptor(info.iconResource);
        info.icon = iconDescriptor?.getPixelMap();
      } else {
        let iconDescriptor = resourceManager.getDrawableDescriptor(info.iconId);
        info.icon = iconDescriptor?.getPixelMap();
      }
    } catch (error) {
      Log.error(`getDrawableDescriptor failed, error code: ${error.code}, message: ${error.message}.`);
    }

    if (!info.icon) {
      info.icon = $r('app.media.icon');
    }

    this.reqUserPermissions = [];
    await this.getReqUserPermissions(info);
    let groupIds: number[] = [];
    for (let i = 0; i < this.reqUserPermissions.length; i++) {
      let groupId = getGroupIdByPermission(this.reqUserPermissions[i])
      if (groupIds.indexOf(groupId) == -1) {
        groupIds.push(groupId);
      }
    }
    info.permissions = this.reqUserPermissions;
    info.groupId = groupIds;
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

    for (let i = 0; i < reqGroupIds.length; i++) {
      let id = reqGroupIds[i];
      let groupName = groups[id].groupName;
      let group = groups[id].name;
      let groupReqPermissons: Permissions[] = [];
      for (let j = 0; j < reqPermissions.length; j++) {
        let permission = reqPermissions[j];
        if (groups[id].permissions.indexOf(permission) != -1) {
          groupReqPermissons.push(permission);
        }
      }
      this.isGranted = true;
      this.folderStatus = [false, false, false];
      if (
        group === 'LOCATION' &&
        !groupReqPermissons.includes(FUZZY_LOCATION_PERMISSION) &&
        this.applicationInfo.api >= Constants.API_VERSION_SUPPORT_STAGE
      ) {
        this.isGranted = false;
      }
      await this.getStatus(groupReqPermissons, group);

      if (this.isGranted) {
        this.allowedListItem.push(new PermissionObj(groupName, groupReqPermissons, group));
      } else {
        if (group === 'FOLDER' && this.folderStatus.includes(true)) {
          this.allowedListItem.push(new PermissionObj(groupName, groupReqPermissons, group));
        } else {
          this.bannedListItem.push(new PermissionObj(groupName, groupReqPermissons, group));
        }
      }

      GlobalContext.store('folderStatus', this.folderStatus);
    }
  }

  async getStatus(groupReqPermissons: Permissions[], group: string) {
    for (let i = 0; i < groupReqPermissons.length; i++) {
      let permission = groupReqPermissons[i];
      if (
        this.applicationInfo.api >= Constants.API_VERSION_SUPPORT_STAGE && permission == PRECISE_LOCATION_PERMISSION
      ) {
        continue;
      }
      if (permission == BACKGROUND_LOCATION_PERMISSION) {
        continue;
      }
      let res = await verifyAccessToken(this.applicationInfo.tokenId, permission);
      if (res != abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        this.isGranted = false;
      }
      if (group === 'FOLDER' && res === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        switch (permission) {
          case DOWNLOAD_PERMISSION:
            this.folderStatus[0] = true;
            break;
          case DESKTOP_PERMISSION:
            this.folderStatus[1] = true;
            break;
          case DOCUMENTS_PERMISSION:
            this.folderStatus[2] = true;
            break;
        }
      }
    }
  }

  /**
   * Lifecycle function, triggered once when this page is displayed
   */
  onPageShow() {
    this.initialPermissions();
    bundleManager.getApplicationInfo(
      this.applicationInfo.bundleName, bundleManager.ApplicationFlag.GET_APPLICATION_INFO_DEFAULT
    ).then(appInfo => {
      let bundleContext = this.context.createBundleContext(this.applicationInfo.bundleName)
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
                                          .fontColor($r('sys.color.ohos_id_color_text_primary'))
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
                      .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
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
                                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
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
                                  this.ListItemLayout(item, Constants.RADIO_ALLOW_INDEX)
                                }, (item: PermissionObj) => JSON.stringify(item))
                              }
                              .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
                              .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
                              .padding(Constants.LIST_PADDING_TOP)
                              .divider({
                                strokeWidth: Constants.DIVIDER,
                                color: $r('sys.color.ohos_id_color_list_separator'),
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
                                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
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
                                  this.ListItemLayout(item, Constants.RADIO_BAN_INDEX)
                                }, (item: PermissionObj) => JSON.stringify(item))
                              }
                              .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
                              .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
                              .padding(Constants.LIST_PADDING_TOP)
                              .divider({
                                strokeWidth: Constants.DIVIDER,
                                color: $r('sys.color.ohos_id_color_list_separator'),
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
          .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
        }
      }.backgroundColor($r('sys.color.ohos_id_color_sub_background'))
    }
  }
}

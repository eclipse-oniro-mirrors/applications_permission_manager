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

import { backBar } from "../common/components/backBar";
import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import bundleManager from '@ohos.bundle.bundleManager';
import { BusinessError } from '@ohos.base';
import { groups, userGrantPermissions } from "../common/model/permissionGroup";
import Constants from '../common/utils/constant';
import { verifyAccessToken, getGroupIdByPermission } from "../common/utils/utils";
import { permissionObj, appInfo } from '../common/utils/typedef';
import { GlobalContext } from '../common/utils/globalContext';

const TAG = 'PermissionManager_MainAbility:';
const FUZZY_LOCATION_PERMISSION = 'ohos.permission.APPROXIMATELY_LOCATION';
const PRECISE_LOCATION_PERMISSION = 'ohos.permission.LOCATION';
const allowedStatus = 0; // Status: Allowed
const bannedStatus = 1; // Status: Banned

@Entry
@Component
struct appNamePlusPage {
  private context = getContext(this) as common.UIAbilityContext;
  @State allowedListItem: permissionObj[] = []; // Array of allowed permissions
  @State bannedListItem: permissionObj[] = []; // array of forbidden permissions
  @State applicationInfo: appInfo = GlobalContext.load('applicationInfo'); // Routing jump data
  @State bundleName: string = GlobalContext.load('bundleName');
  @State label: string = '';
  @State isTouch: string = '';

  @Builder ListItemLayout(item: permissionObj, status: number) {
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
            url: item.group == "OTHER" ? 'pages/other-permissions' : 'pages/application-tertiary',
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
    .borderRadius($r("sys.float.ohos_id_corner_radius_default_l"))
    .linearGradient((this.isTouch === item.group) ? {
        angle: 90,
        direction: GradientDirection.Right,
        colors: [['#DCEAF9', 0.0], ['#FAFAFA', 1.0]]
      } : {
        angle: 90,
        direction: GradientDirection.Right,
        colors: [[$r("sys.color.ohos_id_color_list_card_bg"), 1], [$r("sys.color.ohos_id_color_list_card_bg"), 1]]
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

  async initApplicationInfo(info: appInfo) {
    console.info(TAG + `labelId: ` + JSON.stringify(info.labelId));
    let resourceManager = this.context.createBundleContext(info.bundleName).resourceManager;

    resourceManager.getStringValue(info.labelId, (error, value) => {
      info.label = value;
    })

    try {
      let iconDescriptor = resourceManager.getDrawableDescriptor(info.iconId);
      info.icon = iconDescriptor?.getPixelMap();
    } catch (error) {
      console.error(`getDrawableDescriptor failed, error code: ${error.code}, message: ${error.message}.`);
    }
    let icon = info.icon;
    if (!icon) {
      info.icon = await resourceManager.getMediaContentBase64(info.iconId);
    }
    let icon1 = info.icon;
    if (!icon1) {
      info.icon = $r('app.media.icon');
    }

    let reqUserPermissions: Permissions[] = [];
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
        }
        catch(err) {
          console.log(TAG + 'getPermissionFlags error: ' + JSON.stringify(err));
        }
        reqUserPermissions.push(permission);
      }
    }
    let groupIds: number[] = [];
    for (let i = 0; i < reqUserPermissions.length; i++) {
      let groupId = getGroupIdByPermission(reqUserPermissions[i])
      if (groupIds.indexOf(groupId) == -1) {
        groupIds.push(groupId);
      }
    }
    info.permissions = reqUserPermissions;
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
      let isGranted = true;
      for (let i = 0; i < groupReqPermissons.length; i++) {
        let permission = groupReqPermissons[i];
        if (this.applicationInfo.api >= Constants.API_VERSION_SUPPORT_STAGE && permission == PRECISE_LOCATION_PERMISSION) {
          continue;
        }
        let res = await verifyAccessToken(this.applicationInfo.tokenId, permission);
        if (res != abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
          isGranted = false;
        }
      }

      if (isGranted) {
        this.allowedListItem.push(new permissionObj(groupName, groupReqPermissons, group));
      } else {
        this.bannedListItem.push(new permissionObj(groupName, groupReqPermissons, group));
      }
    }
  }

  /**
   * Lifecycle function, triggered once when this page is displayed
   */
  onPageShow() {
    console.log(TAG + 'onPageShow application-secondary');
    this.initialPermissions();
    bundleManager.getApplicationInfo(this.applicationInfo.bundleName, bundleManager.ApplicationFlag.GET_APPLICATION_INFO_DEFAULT).then(appInfo => {
      let bundleContext = this.context.createBundleContext(this.applicationInfo.bundleName)
      bundleContext.resourceManager.getStringValue(appInfo.labelId, (error, value) => {
        if (value) {
          this.applicationInfo.label = value;
          GlobalContext.store('applicationInfo', this.applicationInfo);
          this.label = value
        }
      })
    }).catch((error: BusinessError) => {
      console.error(TAG + 'getApplicationInfo error: ' + JSON.stringify(error));
    })
  }

  build() {
    Column(){
      GridRow({ gutter: Constants.GUTTER, columns: {
        xs: Constants.XS_COLUMNS, sm: Constants.SM_COLUMNS, md: Constants.MD_COLUMNS, lg: Constants.LG_COLUMNS } }) {
        GridCol({ span: { xs: Constants.XS_SPAN, sm: Constants.SM_SPAN, md: Constants.MD_SPAN, lg: Constants.LG_SPAN },
          offset: { xs: Constants.XS_OFFSET, sm: Constants.SM_OFFSET, md: Constants.MD_OFFSET, lg: Constants.LG_OFFSET } }) {
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
                     .padding({ left: Constants.SECONDARY_LIST_PADDING_LEFT, right: Constants.SECONDARY_LIST_PADDING_RIGHT })
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
                                ForEach(this.allowedListItem, (item: permissionObj) => {
                                  this.ListItemLayout(item, Constants.RADIO_ALLOW_INDEX)
                                }, (item: permissionObj) => JSON.stringify(item))
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
                                ForEach(this.bannedListItem, (item: permissionObj) => {
                                  this.ListItemLayout(item, Constants.RADIO_BAN_INDEX)
                                }, (item: permissionObj) => JSON.stringify(item))
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
          .backgroundColor($r("sys.color.ohos_id_color_sub_background"))
        }
      }.backgroundColor($r("sys.color.ohos_id_color_sub_background"))
    }
  }
}

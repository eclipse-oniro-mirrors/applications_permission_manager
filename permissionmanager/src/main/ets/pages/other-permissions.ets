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
import Constants from '../common/utils/constant';
import { permissionGroups } from '../common/model/permissionGroup';
import { verifyAccessToken } from '../common/utils/utils';
import { OtherPermission, RouterParams3 } from '../common/utils/typedef';
import { Permissions } from '@ohos.abilityAccessCtrl';

let status: number = (router.getParams() as RouterParams3).status; // Status: Allowed, Forbidden
let permissions: Permissions[] = (router.getParams() as RouterParams3).permission; // permissions name
let otherPermissionList: OtherPermission[] = []; // otherPermission List
for (let i = 0; i < permissions.length; i++) {
  otherPermissionList.push(
    new OtherPermission(permissionGroups.filter(item => item.permissionName == permissions[i])[0].label, permissions[i])
  );
}

@Entry
@Component
struct appNamePage {
  private backTitle: ResourceStr = (router.getParams() as RouterParams3).backTitle;
  private tokenId: number = (router.getParams() as RouterParams3).tokenId;

  build() {
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
                Scroll() {
                  appNameItem()
                }
              }
            }.layoutWeight(Constants.LAYOUT_WEIGHT)
          }
        }
        .height(Constants.FULL_HEIGHT)
        .width(Constants.FULL_WIDTH)
        .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
      }
    }.backgroundColor($r('sys.color.ohos_id_color_sub_background'))
  }

/**
   * Lifecycle function, triggered once when this page is displayed
   */
  onPageShow() {
    permissions.forEach(permission => {
      verifyAccessToken(this.tokenId, permission).then((data): void => {
        status = data;
      });
    })
  }
}

@Component
struct appNameItem {
  private bundleName: string = (router.getParams() as RouterParams3).bundleName;
  private tokenId: number = (router.getParams() as RouterParams3).tokenId;
  @State otherPermissionListItem: OtherPermission[] = otherPermissionList; // Other permission interface data array
  @State isTouch: string = '';

  @Builder ListItemLayout(item: OtherPermission) {
    ListItem() {
      Row() {
        Column() {
          Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
            Row() {
              Text(item.permissionLabel)
                .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
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
            router.pushUrl({
              url: 'pages/application-tertiary',
              params: {
                bundleName: this.bundleName,
                backTitle: item.permissionLabel,
                permission: [item.permission],
                status,
                tokenId: this.tokenId
              }
            });
        })
      }
    }.padding({ left: $r('sys.float.ohos_id_card_margin_start'), right: $r('sys.float.ohos_id_card_margin_end') })
    .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
    .linearGradient((this.isTouch === item.permission) ? {
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
        this.isTouch = item.permission;
      }
      if (event.type === TouchType.Up) {
        this.isTouch = '';
      }
    })
  }

  build() {
    Row() {
      Column() {
        Row() {
          List() {
            ForEach(this.otherPermissionListItem, (item: OtherPermission) => {
              this.ListItemLayout(item)
            }, (item: OtherPermission) => JSON.stringify(item))
          }.backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
          .padding(Constants.LIST_PADDING_TOP)
          .divider({
            strokeWidth: Constants.DIVIDER,
            color: $r('sys.color.ohos_id_color_list_separator'),
            startMargin: Constants.DEFAULT_MARGIN_START,
            endMargin: Constants.DEFAULT_MARGIN_END
          })
        }.margin({ top: Constants.ROW_MARGIN_TOP })
         .padding({ left: Constants.LIST_PADDING_LEFT, right: Constants.LISTITEM_PADDING_RIGHT })
      }
      .width(Constants.FULL_WIDTH)
      .height(Constants.FULL_HEIGHT)
    }
  }
}

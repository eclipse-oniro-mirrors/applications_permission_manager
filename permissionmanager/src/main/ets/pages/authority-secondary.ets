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
import { permissionInfos, groups } from '../common/model/permissionGroup';
import Constants from '../common/utils/constant';
import { CalendarObj, RouterParams1, PermissionApplications } from '../common/model/typedef';

@Entry
@Component
struct appNamePage {
  private backTitle: ResourceStr = (this.getUIContext().getRouter().getParams() as RouterParams1).backTitle;

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
        .backgroundColor($r('sys.color.background_secondary'))
      }
    }.backgroundColor($r('sys.color.background_secondary'))
  }
}

@Component
struct appNameItem {
  @State calendarListItem: CalendarObj[] = [];
  private list: PermissionApplications[] = (this.getUIContext().getRouter().getParams() as RouterParams1).list;
  private group: string = (this.getUIContext().getRouter().getParams() as RouterParams1).group;
  @State isTouch: string = '';

  @Builder ListItemLayout(item: CalendarObj) {
    ListItem() {
      Row() {
        Column() {
          Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
            Row() {
              Text(item.label)
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
          let dataList = this.list.filter((ele) => {
            return ele.permission === item.permissionName;
          })
          this.getUIContext().getRouter().pushUrl({
            url: 'pages/authority-tertiary',
            params: { list: dataList, backTitle: item.label, permissionName: item.permissionName }
          });
        })
      }
    }.padding({ left: $r('sys.float.ohos_id_card_margin_start'), right: $r('sys.float.ohos_id_card_margin_end') })
    .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
    .linearGradient((this.isTouch === item.permissionName) ? {
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
        this.isTouch = item.permissionName;
      }
      if (event.type === TouchType.Up) {
        this.isTouch = '';
      }
    })
  }

  /**
   * Lifecycle function, executed when the page is initialized
   */
  aboutToAppear() {
    let permissionsList = groups.filter((item) => {
      return item.name === this.group;
    })
    if (!permissionsList.length) {
      return;
    }
    for (let i = 0; i < permissionsList[0].permissions.length; i++) {
      let permissionInfo = permissionInfos.get(permissionsList[0].permissions[i]);
      if (!permissionInfo) {
        continue;
      }
      this.calendarListItem.push(
        new CalendarObj(permissionInfo.permissionName, permissionInfo.groupName, permissionInfo.label, i)
      );
    }
  }

  build() {
    Row() {
      Column() {
        Row() {
            List() {
              if (this.calendarListItem.length > 0) {
                ForEach(this.calendarListItem, (item: CalendarObj) => {
                  this.ListItemLayout(item)
                }, (item: CalendarObj) => JSON.stringify(item))
              } else {
                ListItem() {
                  Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
                    Text($r('app.string.no_permission'))
                      .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
                      .fontColor($r('sys.color.font_primary'))
                  }
                }
                .width(Constants.FULL_WIDTH)
                .height(Constants.LISTITEM_ROW_HEIGHT)
                .padding({ left: Constants.DEFAULT_PADDING_START, right: Constants.DEFAULT_PADDING_END })
              }
            }.backgroundColor($r('sys.color.comp_background_list_card'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
            .padding(Constants.LIST_PADDING_TOP)
            .divider({
              strokeWidth: Constants.DIVIDER,
              color: $r('sys.color.comp_divider'),
              startMargin: Constants.DEFAULT_MARGIN_START,
              endMargin: Constants.DEFAULT_MARGIN_END
            })
          }.margin({ top: Constants.ROW_MARGIN_TOP })
        .padding({ left: Constants.LIST_PADDING_LEFT, right: Constants.DEFAULT_PADDING_END })
      }
      .width(Constants.FULL_WIDTH)
      .height(Constants.FULL_HEIGHT)
    }
  }
}

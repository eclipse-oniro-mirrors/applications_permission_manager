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
import { alphabetIndexerComponent } from '../common/components/alphabeticalIndex';
import { textInput } from '../common/components/search';
import router from '@ohos.router';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import { BusinessError } from '@ohos.base';
import { Log, verifyAccessToken, indexValue, sortByName } from '../common/utils/utils';
import { ApplicationObj, PermissionInfo, RouterParams2, PermissionApplications, AppInfo } from '../common/utils/typedef';
import { GlobalContext } from '../common/utils/globalContext';
import Constants from '../common/utils/constant';
import { permissionGroups } from '../common/model/permissionGroup';

@Extend(Image)function customizeImage(width: number, height: number) {
  .objectFit(ImageFit.Contain)
  .width(width)
  .height(height)
}

@Entry
@Component
struct locationInfoPage {
  private backTitle: ResourceStr = (router.getParams() as RouterParams2).backTitle;

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
                applicationItem()

              }.width(Constants.FULL_WIDTH)
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

@Component
struct applicationItem {
  private list: PermissionApplications[] = (router.getParams() as RouterParams2).list;
  private permissionName: string = (router.getParams() as RouterParams2).permissionName;
  @State permissionNum: number = Constants.PERMISSION_NUM; // permission num
  @State toggleIsOn: boolean[] = []; // toggle switch state array
  @State isRisk: boolean[] = [];
  @State isFirst: boolean[] = [];
  @State applicationList: ApplicationObj[] = []; // application info array
  @State searchResult: boolean = true; // search results
  @State selectedIndex: number = 0;
  @State permissionInfo: PermissionInfo = new PermissionInfo('', '', '', 0);
  @State allBundleInfo: AppInfo[] = GlobalContext.load('allBundleInfo');
  scroller: Scroller = new Scroller();

  @Builder ListItemLayout(item: ApplicationObj) {
    ListItem() {
      Row() {
        Column() {
          Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
            Row() {
              Image(item.icon)
                .customizeImage(Constants.AUTHORITY_IMAGE_WIDTH, Constants.AUTHORITY_IMAGE_HEIGHT)
                .margin({ right: Constants.AUTHORITY_IMAGE_MARGIN_RIGHT })
              Column() {
                Text(item.label)
                  .width(Constants.MAXIMUM_HEADER_WIDTH)
                  .maxLines(Constants.MAXIMUM_HEADER_LINES)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('sys.color.ohos_id_color_text_primary'))
                if (this.isRisk[item.index]) {
                  Text($r('app.string.risk_warning'))
                    .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
                    .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                }
              }.flexGrow(Constants.FLEX_GROW)
              .alignItems(HorizontalAlign.Start)
              Toggle({ type: ToggleType.Switch, isOn: this.toggleIsOn[item.index] })
                .selectedColor($r('sys.color.ohos_id_color_toolbar_icon_actived'))
                .switchPointColor($r('sys.color.ohos_id_color_foreground_contrary'))
                .padding({ right: 0 })
                .width(Constants.AUTHORITY_TOGGLE_WIDTH)
                .height(Constants.AUTHORITY_TOGGLE_HEIGHT)
                .onChange((isOn: boolean) => {
                  if (item.permission === undefined) {
                    return;
                  }
                  if (this.isFirst[item.index] && isOn) {
                    this.isFirst[item.index] = false;
                    return;
                  }
                  this.isFirst[item.index] = false;
                  if (isOn) {
                    this.grantUserGrantedPermission(item.accessTokenId, item.permission, item.index);
                  } else {
                    this.revokeUserGrantedPermission(item.accessTokenId, item.permission, item.index);
                  }
                })
            }
            .width(Constants.FULL_WIDTH)
            .height(Constants.AUTHORITY_ROW_HEIGHT)
            .constraintSize({ minHeight: Constants.AUTHORITY_CONSTRAINTSIZE_MINHEIGHT })
          }
        }.onClick(() => {
        })
      }
    }.padding({ left: Constants.DEFAULT_PADDING_START, right: Constants.DEFAULT_PADDING_END })
    .enabled(!this.isRisk[item.index])
    .opacity(this.isRisk[item.index] ? $r('sys.float.ohos_id_alpha_disabled') : 1)
  }

  /**
   * Grant permissions to the app
   * @param {Number} accessTokenId
   * @param {String} permission permission name
   * @param {Number} index Array index to modify permission status
   */
  grantUserGrantedPermission(accessTokenId: number, permission: Permissions, index: number) {
    abilityAccessCtrl.createAtManager().grantUserGrantedPermission(
      accessTokenId, permission, Constants.PERMISSION_FLAG).then(() => {
      // result: 0 Authorization succeeded; result: -1 Authorization failed
      this.toggleIsOn[index] = true;
      let num = this.toggleIsOn.filter(item => item === true).length;
      this.permissionNum = num;
    }).catch((error: BusinessError) => {
      this.toggleIsOn[index] = false;
      Log.error('grantUserGrantedPermission failed. Cause: ' + JSON.stringify(error));
    })
  }

  /**
   * Deauthorize the app
   * @param {Number} accessTokenId
   * @param {String} permission permission name
   * @param {Number} index Array index to modify permission status
   */
  revokeUserGrantedPermission(accessTokenId: number, permission: Permissions, index: number) {
    abilityAccessCtrl.createAtManager().revokeUserGrantedPermission(
      accessTokenId, permission, Constants.PERMISSION_FLAG).then(() => {
      // result: 0 successfully cancel the authorization; result: -1 cancel the authorization failed
      this.toggleIsOn[index] = false;
      let num = this.toggleIsOn.filter(item => item === true).length;
      this.permissionNum = num;
    }).catch(() => {
      this.toggleIsOn[index] = true;
    })
  }

  /**
   * Lifecycle function, executed when the page is initialized
   */
  aboutToAppear() {
    let bundleNames = this.list.length > 0 ? this.list[0].bundleNames : this.list;
    permissionGroups.forEach(permission => {
      if (permission.permissionName === this.permissionName) {
        this.permissionInfo = permission;
      }
    })

    let atManager = abilityAccessCtrl.createAtManager();
    for (let i = 0; i < bundleNames.length; i++) {
      // Get BundleInfo based on bundle name
      this.allBundleInfo.forEach(bundleInfo => {
        if (bundleInfo.bundleName === bundleNames[i]) {
          this.applicationList.push(
            new ApplicationObj(
              bundleInfo.label,
              bundleInfo.icon,
              i,
              bundleInfo.tokenId,
              this.list[0].permission,
              bundleInfo.zhTag,
              bundleInfo.indexTag,
              bundleInfo.language) // Get the first letter in the returned initials array
          );
          verifyAccessToken(bundleInfo.tokenId, this.list[0].permission).then(data => {
            // 0: have permission; -1: no permission
            if (data === Constants.PERMISSION_INDEX) {
              this.toggleIsOn[i] = true;
              this.isFirst[i] = true;
              this.permissionNum++;
            } else {
              this.toggleIsOn[i] = false;
              this.isFirst[i] = false;
            }
          })
          this.isRisk[i] = false;
          try {
            atManager.getPermissionFlags(bundleInfo.tokenId, this.list[0].permission).then(data => {
              if (data == Constants.PERMISSION_POLICY_FIXED) {
                this.isRisk[i] = true;
              }
            })
          } catch (err) {
            Log.error('getPermissionFlags error: ' + JSON.stringify(err));
          }
        }
      })
    }
  }

  build() {
    Column() {
      Row() {
        textInput({
          applicationItem: $applicationList,
          searchResult: $searchResult
        })
      }.padding({
        left: Constants.AUTHORITY_TEXTINPUT_PADDING_LEFT,
        right: Constants.AUTHORITY_TEXTINPUT_PADDING_RIGHT
      })
      Flex({ alignItems:ItemAlign.Start, justifyContent: FlexAlign.Start }) {
        Column() {
          Flex({ justifyContent: FlexAlign.Start }) {
            if (this.permissionNum > 0) {
              Text(
                this.permissionInfo.enableDescription ?
                $r(this.permissionInfo.enableDescription, String(this.permissionNum)) :
                ''
              )
                .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                .margin({ top: Constants.AUTHORITY_TEXT_MARGIN_TOP })
            } else {
              Text(this.permissionInfo.forbiddenDescription)
                .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                .margin({ top: Constants.AUTHORITY_TEXT_MARGIN_TOP })
            }
          }.padding({ left: Constants.DEFAULT_PADDING_START, right: Constants.DEFAULT_PADDING_END })
          .margin({ bottom: Constants.AUTHORITY_ROW_MARGIN_BOTTOM })
          Row() {
            Column() {
              if (!this.applicationList.length) {
                if (this.searchResult) {
                  Row() {}
                } else {
                  Row() {
                    Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
                      Image($r('app.media.searchnoresult'))
                        .customizeImage(Constants.SEARCHNORESULT_IMAGE_WIDTH, Constants.SEARCHNORESULT_IMAGE_HEIGHT)
                    }
                  }
                }
              } else {
                Row() {
                  List({ scroller: this.scroller }) {
                    ForEach(sortByName(this.applicationList), (item: ApplicationObj) => {
                      this.ListItemLayout(item)
                    }, (item: ApplicationObj) => JSON.stringify(item))
                  }
                  .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
                  .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
                  .padding({ top: Constants.LIST_PADDING_TOP, bottom: Constants.LIST_PADDING_BOTTOM })
                  .divider({
                    strokeWidth: Constants.DIVIDER,
                    color: $r('sys.color.ohos_id_color_list_separator'),
                    startMargin: Constants.DIVIDER_MARGIN_RIGHT_APPLICATION,
                    endMargin: Constants.DEFAULT_MARGIN_END
                  })
                  .onScrollIndex((start, end) => {
                    GlobalContext.getContext().set('scroller', this.scroller);
                    if (this.applicationList.length > 0) {
                      let alphabeticalIndex = sortByName(this.applicationList)[start].indexTag;
                      let index = indexValue.indexOf(alphabeticalIndex);
                      this.selectedIndex = index >= 0 ? index : 0;
                    }
                  })
                }
              }
            }.width(Constants.FULL_WIDTH)
            .margin({ bottom: Constants.AUTHORITY_LIST_MARGIN_BOTTOM })
          }
        }.padding({ left: Constants.AUTHORITY_LISTITEM_PADDING_LEFT })
        Column() {
          alphabetIndexerComponent({ applicationItem: $applicationList, index: $selectedIndex })
        }.width(Constants.AUTHORITY_ALPHABETINDEX_WIDTH)
         .padding({ top: Constants.AUTHORITY_ALPHABETINDEX_PADDING_TOP })
        .margin({ bottom: Constants.APPLICATION_LIST_MARGIN_BOTTOM })
      }.flexGrow(Constants.FLEX_GROW)
    }.height(Constants.FULL_HEIGHT)
  }
}

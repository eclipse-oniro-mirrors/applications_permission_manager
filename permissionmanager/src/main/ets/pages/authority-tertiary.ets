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
import { alphabetIndexerComponent } from "../common/components/alphabeticalIndex";
import { textInput } from "../common/components/search";
import router from '@ohos.router';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import { verifyAccessToken, makePy, appSort, getSortId, indexValue } from "../common/utils/utils";
import { authorizeDialog } from "../common/components/dialog";
import Constants from '../common/utils/constant';

var TAG = 'PermissionManager_MainAbility:';

@Extend(Image) function customizeImage(width: number, height: number) {
  .objectFit(ImageFit.Contain)
  .width(width)
  .height(height)
}

let routerData: any = router.getParams()['routerData']; // Routing jump data
let backTitle = router.getParams()['backTitle']; // return title name
class ApplicationObj {
  label: string
  icon: string
  index: number
  accessTokenId: number
  permission: string
  alphabeticalIndex: string
  sortId: string
  constructor(
    label: string,
    icon: string,
    index: number,
    accessTokenId: number,
    permission: string,
    alphabeticalIndex: string,
    sortId: string) {
    this.label = label
    this.icon = icon
    this.index = index
    this.accessTokenId = accessTokenId
    this.permission = permission
    this.alphabeticalIndex = alphabeticalIndex
    this.sortId = sortId
  }
} // application information

@Entry
@Component
struct locationInfoPage {
  build() {
    GridRow({ gutter: Constants.GUTTER, columns: {
      xs: Constants.XS_COLUMNS, sm: Constants.SM_COLUMNS, md: Constants.MD_COLUMNS, lg: Constants.LG_COLUMNS } }) {
      GridCol({ span: { xs: Constants.XS_SPAN, sm: Constants.SM_SPAN, md: Constants.MD_SPAN, lg: Constants.LG_SPAN },
        offset: { xs: Constants.XS_OFFSET, sm: Constants.SM_OFFSET, md: Constants.MD_OFFSET, lg: Constants.LG_OFFSET } }) {
        Row() {
          Column() {
            Row() {
              backBar({ title: JSON.stringify(backTitle), recordable: false })
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
        .backgroundColor($r("sys.color.ohos_id_color_sub_background"))
      }
    }.backgroundColor($r("sys.color.ohos_id_color_sub_background"))
  }
}

@Component
struct applicationItem {
  @State permissionNum: number = Constants.PERMISSION_NUM; // permission num
  @State toggleIsOn: object = {}; // toggle switch state array
  @State isRisk: object = {};
  @State applicationList: ApplicationObj[] = []; // application info array
  @State searchResult: boolean = true; // search results
  @State selectedIndex: number = 0;
  scroller: Scroller = new Scroller();

  authorizeDialogController: CustomDialogController = new CustomDialogController({
    builder: authorizeDialog({ }),
    autoCancel: true,
    alignment: DialogAlignment.Center
  });

  @Builder ListItemLayout(item, index) {
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
                  if (item.accessTokenId === '' || item.permission === '') {
                    return;
                  }
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
          if (index < this.applicationList.length - 1) {
            Row() {
              Flex() {
                Column().width(Constants.APPLICATION_TEXT_DECORATION_MARGIN_LEFT)
                Column()
                  .backgroundColor($r('sys.color.ohos_id_color_list_separator'))
                  .height(Constants.TEXT_DECORATION_HEIGHT)
                  .flexGrow(Constants.FLEX_GROW)
              }
            }
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
  grantUserGrantedPermission(accessTokenId, permission, index) {
    abilityAccessCtrl.createAtManager().grantUserGrantedPermission(
      accessTokenId, permission, Constants.PERMISSION_FLAG).then(() => {
      // result: 0 Authorization succeeded; result: -1 Authorization failed
      this.toggleIsOn[index] = true;
      let num = Constants.PERMISSION_NUM;
      for(let key in this.toggleIsOn){
        if(this.toggleIsOn[key]){
          num++;
        }
      }
      this.permissionNum = num;
    }).catch(error => {
        this.authorizeDialogController.open();
        this.toggleIsOn[index] = false;
        setTimeout(()=> {
          this.authorizeDialogController.close();
        }, Constants.DELAY_TIME)
      console.error(TAG + 'abilityAccessCtrl.createAtManager.grantUserGrantedPermission failed. Cause: ' + JSON.stringify(error));
    })
  }

  /**
   * Deauthorize the app
   * @param {Number} accessTokenId
   * @param {String} permission permission name
   * @param {Number} index Array index to modify permission status
   */
  revokeUserGrantedPermission(accessTokenId, permission, index) {
    abilityAccessCtrl.createAtManager().revokeUserGrantedPermission(
      accessTokenId, permission, Constants.PERMISSION_FLAG).then(() => {
      // result: 0 successfully cancel the authorization; result: -1 cancel the authorization failed
      this.toggleIsOn[index] = false;
      let num = Constants.PERMISSION_NUM;
      for (let key in this.toggleIsOn) {
        if (this.toggleIsOn[key]) {
          num++;
        }
      }
      this.permissionNum = num;
    }).catch(() => {
        this.authorizeDialogController.open();
        this.toggleIsOn[index] = true;
        setTimeout(() => {
          this.authorizeDialogController.close();
        }, Constants.DELAY_TIME)
    })
  }

  /**
   * Lifecycle function, executed when the page is initialized
   */
  aboutToAppear() {
    let bundleNames = routerData.length > 0 ? routerData[0].bundleNames : routerData;

    let atManager = abilityAccessCtrl.createAtManager();
    for (let i = 0; i < bundleNames.length; i++) {
      // Get BundleInfo based on bundle name
      globalThis.allBundleInfo.forEach(bundleInfo => {
        if (bundleInfo.bundleName === bundleNames[i]) {
          verifyAccessToken(bundleInfo.tokenId, routerData[0].permission).then(data => {
            this.applicationList.push(
              new ApplicationObj(
              bundleInfo.label,
              bundleInfo.icon,
                i,
              bundleInfo.tokenId,
              routerData[0].permission,
              makePy(bundleInfo.label)[0].slice(0, 1),
              getSortId(bundleInfo.label)) // Get the first letter in the returned initials array
            );
            // 0: have permission; -1: no permission
            if (data === Constants.PERMISSION_INDEX) {
              this.toggleIsOn[i] = true;
              this.permissionNum++;
            } else {
              this.toggleIsOn[i] = false;
            }
          })
          this.isRisk[i] = false;
          try {
            atManager.getPermissionFlags(bundleInfo.tokenId, routerData[0].permission).then(data => {
              if (data == Constants.PERMISSION_POLICY_FIXED) {
                this.isRisk[i] = true;
              }
            })
          }
          catch(err) {
            console.log(TAG + 'getPermissionFlags error: ' + JSON.stringify(err));
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
            Text(String(this.permissionNum))
              .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              .margin({ top: Constants.AUTHORITY_TEXT_MARGIN_TOP, left: Constants.AUTHORITY_TEXT_MARGIN_LEFT })
            Text($r('app.string.number_of_authorized_applications'))
              .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              .margin({ top: Constants.AUTHORITY_TEXT_MARGIN_TOP, left: Constants.AUTHORITY_TEXT_MARGIN_LEFT })
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
                    ForEach(appSort(this.applicationList), (item, index) => {
                      this.ListItemLayout(item, index)
                    }, item => JSON.stringify(item))
                  }
                  .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
                  .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
                  .padding({ top: Constants.LIST_PADDING_TOP, bottom: Constants.LIST_PADDING_BOTTOM })
                  .onScrollIndex((start, end) => {
                    globalThis.scroller = this.scroller;
                    if (this.applicationList.length > 0) {
                      let alphabeticalIndex = appSort(this.applicationList)[start].alphabeticalIndex;
                      let index = indexValue.indexOf(alphabeticalIndex.toUpperCase());
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

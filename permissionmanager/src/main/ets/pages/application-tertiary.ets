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
import bundleManager from '@ohos.bundle.bundleManager';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import { authorizeDialog } from "../common/components/dialog";
import { showSubpermissionsGrop } from "../common/model/permissionGroup";
import { verifyAccessToken, getPermissionLabel } from "../common/utils/utils";
import Constants from '../common/utils/constant';

var TAG = 'PermissionManager_MainAbility:';

let routerData: any = router.getParams()['routerData']; // Routing jump data
let backTitle: any = router.getParams()['backTitle']; // return title name
let status = router.getParams()['status']; // Status: Allowed, Forbidden
let permissions: any = router.getParams()['permission']; // permissions name
let tokenId: any = router.getParams()['tokenId']; // tokenId for verify permission
let api: number = 0;
let nowGrantResult = Constants.PERMISSION_NUM; // Authorization results now
let nowRevokeResult = Constants.PERMISSION_NUM; // Now deauthorize results
let GrantResultFlag = []; // Authorization result Flag
let RevokeResultFlag = []; // Cancel authorization result Flag
let bundleInfo: any = {};
let reqPermissionInfo;
const PRECISE_LOCATION_PERMISSION = 'ohos.permission.LOCATION';
class MeidaDocObj {
  name: Resource
  accessTokenId: number
  permissions: []
  constructor(name: Resource, accessTokenId: number, permissions: []) {
    this.name = name
    this.accessTokenId = accessTokenId
    this.permissions = permissions
  }
}; // permission information class

@Entry
@Component
struct mediaDocumentPage {
  @State refresh: boolean = false;
  @State isCheckList: boolean[] = []; // Permission status array
  @State isRefreshReason: number = 0

  build() {
    Column() {
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
                  mediaDocumentItem({ isCheckList: $isCheckList, isRefreshReason: $isRefreshReason })
                }.width(Constants.FULL_WIDTH)
              }
              .margin({ top: Constants.TITLE_MARGIN_BOTTOM })
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

  onPageShow() {
    console.log(TAG + 'onPageShow');
    if (this.refresh) this.refreshStatus();
    this.refresh = true;
  }

  async refreshStatus() {
    this.isRefreshReason ++;
    console.log(TAG + 'Refresh permission status');
    let isGranted = true;
    for (let i = 0; i < permissions.length; i++) {
      let permission = permissions[i];
      if (api >= Constants.API_VERSION_SUPPORT_STAGE && permission == PRECISE_LOCATION_PERMISSION) {
        continue;
      }
      let res = await verifyAccessToken(tokenId, permission);
      if (res != abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        isGranted = false;
      }
    }
    console.log(TAG + 'isGranted: ' + JSON.stringify(isGranted));

    if (isGranted) {
      this.isCheckList = [true, false];
    } else {
      this.isCheckList = [false, true];
    }
  }
}

@Component
struct mediaDocumentItem {
  @State mediaDocListItem: MeidaDocObj[] = []; // Permission information array
  @Link isCheckList: boolean[]; // Permission status array
  @State accurateIsOn: boolean = true;
  @State api: number = 0;
  @State isRisk: boolean = false; // Whether it is a risky application
  @State isTouch: number = -1;
  @State reason: string = '';
  @State label: string = '';
  @State version: string = '';
  @State permissionLabels: Array<any> = [];
  @Link @Watch("updateReason") isRefreshReason: number;

  authorizeDialogController: CustomDialogController = new CustomDialogController({
    builder: authorizeDialog({ }),
    autoCancel: true,
    alignment: DialogAlignment.Center
  });

  /**
   * Grant permissions to the app
   * @param {Number} accessTokenId
   * @param {String} permission permission name
   */
  grantUserGrantedPermission(accessTokenId, permission) {
    abilityAccessCtrl.createAtManager().grantUserGrantedPermission(accessTokenId, permission, Constants.PERMISSION_FLAG)
      .then(() => {
        nowGrantResult = Constants.PERMISSION_INDEX;
      })
      .catch((error) => {
        console.error(TAG + 'grantUserGrantedPermission failed. Cause: ' + JSON.stringify(error));
      })
  }

  /**
   * Deauthorize the app
   * @param {Number} accessTokenId
   * @param {String} permission permission name
   */
  revokeUserGrantedPermission(accessTokenId, permission) {
    abilityAccessCtrl.createAtManager().revokeUserGrantedPermission(accessTokenId, permission, Constants.PERMISSION_FLAG)
      .then(() => {
        nowRevokeResult = Constants.PERMISSION_INDEX;
      })
      .catch((error) => {
        console.error(TAG + 'revokeUserGrantedPermission failed. Cause: ' + JSON.stringify(error));
      })
  }

  /**
   * Update reason
   */
  updateReason() {
    bundleManager.getApplicationInfo(globalThis.applicationInfo.bundleName, bundleManager.ApplicationFlag.GET_APPLICATION_INFO_DEFAULT).then(appInfo => {
      let bundleContext = globalThis.context.createBundleContext(routerData)
      bundleContext.resourceManager.getStringValue(appInfo.labelId, (error, value) => {
        if (value) {
          globalThis.applicationInfo.label = value;
          this.label = value
        }
      })
    }).catch(error => {
      console.error(TAG + 'getApplicationInfo error: ' + JSON.stringify(error));
    })
    let context = globalThis.context.createModuleContext(routerData, reqPermissionInfo.moduleName);
    context.resourceManager.getString(reqPermissionInfo.reasonId).then(value => {
      if (value !== undefined) {
        this.reason = value.slice(Constants.START_SUBSCRIPT, Constants.END_SUBSCRIPT);
      }
    })
  }

  /**
   * Lifecycle function, executed when the page is initialized
   */
  aboutToAppear() {
    if (showSubpermissionsGrop.indexOf(globalThis.currentPermissionGroup) != -1) {
      permissions.forEach((permission, idx) => {
        if (idx > 0) {
          this.permissionLabels.push($r("app.string.and"))
        }
        let label = getPermissionLabel(permission)
        this.permissionLabels.push(label);
      })
    }
    let hasReason = false;
    bundleManager.getBundleInfo(routerData, bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_REQUESTED_PERMISSION).then(info => {
      permissions.forEach(permission => {
        info.reqPermissionDetails.forEach(reqPermissionDetail => {
          if (reqPermissionDetail.name == permission) {
            console.info("reqPermissionDetail: " + JSON.stringify(reqPermissionDetail));
            let context = globalThis.context.createModuleContext(routerData, reqPermissionDetail.moduleName);
            context.resourceManager.getString(reqPermissionDetail.reasonId).then(value => {
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
    bundleManager.getBundleInfo(routerData, bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION).then(res => {
      this.api = res.targetVersion;
      this.version = res.versionName;
      api = res.targetVersion;
      bundleInfo = res;
      var acManager = abilityAccessCtrl.createAtManager();
      let accurateStatus = acManager.verifyAccessTokenSync(res.appInfo.accessTokenId, PRECISE_LOCATION_PERMISSION);
      this.accurateIsOn = (accurateStatus == abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) ? true : false;
      try {
        acManager.getPermissionFlags(res.appInfo.accessTokenId, permissions[0]).then((data) => {
          console.log(TAG + `getPermissionFlags success, data->${JSON.stringify(data)}`);
          this.isRisk = (data == Constants.PERMISSION_POLICY_FIXED) ? true : false;
        })
      } catch(err) {
        console.log(TAG + 'acManager.getPermissionFlags failed. Cause: ' + JSON.stringify(err));
      }
      this.mediaDocListItem.push(
        new MeidaDocObj($r('app.string.allow'), res.appInfo.accessTokenId, permissions)
      );
      this.mediaDocListItem.push(
        new MeidaDocObj($r('app.string.ban'), res.appInfo.accessTokenId, permissions)
      );
    }).catch((error) => {
      console.error(TAG + 'bundle.getBundleInfo failed. Cause: ' + JSON.stringify(error));
      this.mediaDocListItem.push(
        new MeidaDocObj($r('app.string.allow'), 0, permissions)
      );
      this.mediaDocListItem.push(
        new MeidaDocObj($r('app.string.ban'), 0, permissions)
      );
    })
    // Get permission status
    if (!status) {
      this.isCheckList = [true, false];
    } else {
      this.isCheckList = [false, true];
    }
  }

  build(){
    Column() {
      Row() {
        Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
          Image(globalThis.applicationInfo.icon)
            .width(Constants.TERTIARY_IMAGE_WIDTH)
            .height(Constants.TERTIARY_IMAGE_HEIGHT)
            .margin({ left: Constants.TERTIARY_IMAGE_MARGIN_LEFT, right: Constants.TERTIARY_IMAGE_MARGIN_RIGHT })
          Column() {
            Row() {
              Text(this.label || globalThis.applicationInfo.label)
                .maxLines(Constants.MAXIMUM_HEADER_LINES)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
                .fontWeight(FontWeight.Bold)
                .textAlign(TextAlign.Start)
            }
            .width(Constants.TERTIARY_HALF_WIDTH)
            .margin({ bottom: Constants.TERTIARY_LABEL_MARGIN_BOTTOM })
            Row() {
              Text($r('app.string.version'))
                .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                .textAlign(TextAlign.Start)
              Text(this.version)
                .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                .textAlign(TextAlign.Start)
            }
            .width(Constants.TERTIARY_HALF_WIDTH)
          }
        }.margin({ left: Constants.TERTIARY_MARGIN_LEFT })
      }
      if (this.reason || this.permissionLabels.length > 0) {
        Row() {
          Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
            Row() {
              Text() {
                if (this.permissionLabels.length > 0) {
                  ForEach(this.permissionLabels, item => {
                    Span(item)
                  })
                  Span(this.reason ? $r("app.string.comma") : $r("app.string.period"))
                }
                Span(this.reason)
              }
                .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
                .fontColor($r('sys.color.ohos_id_color_secondary'))
                .textAlign(TextAlign.Start)
            }.margin({ left: Constants.TERTIARY_IMAGE_MARGIN_LEFT, right: Constants.TERTIARY_IMAGE_MARGIN_RIGHT })
          }
        }
        .margin({ top: Constants.TERTIARY_ROW_MARGIN_TOP, left: Constants.DEFAULT_MARGIN_START, bottom: Constants.DEFAULT_MARGIN_BOTTOM })
      }
      if (this.isRisk) {
        Row() {
          Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
            Row() {
              Image($r('app.media.ic_public_fail'))
                .fillColor($r('sys.color.ohos_id_color_secondary'))
                .width(Constants.TERTIARY_RADIO_IMAGE_WIDTH)
                .height(Constants.TERTIARY_RADIO_IMAGE_HEIGHT)
                .margin({ right: Constants.TERTIARY_IMAGE_MARGIN_RIGHT })
              Text($r('app.string.risk_warning'))
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
                .fontSize($r('sys.float.ohos_id_text_size_body1'))
                .fontWeight(FontWeight.Regular)
            }.margin({ left: Constants.DEFAULT_PADDING_START, right: Constants.DEFAULT_PADDING_END })
          }
        }.backgroundColor($r('sys.color.ohos_id_color_click_effect'))
        .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
        .padding({ top: Constants.DEFAULT_PADDING_TOP, bottom: Constants.DEFAULT_PADDING_BOTTOM })
        .margin({ left: Constants.DEFAULT_MARGIN_START, right: Constants.DEFAULT_MARGIN_END })
      }
      Row() {
        Text() {
          Span(backTitle)
          Span($r('app.string.access_permission'))
        }
          .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
          .fontColor($r('sys.color.ohos_id_color_secondary'))
          .fontWeight(FontWeight.Medium)
          .textAlign(TextAlign.Start)
          .lineHeight(Constants.SUBTITLE_LINE_HEIGHT)
      }.width(Constants.FULL_WIDTH)
      .constraintSize({ minHeight: Constants.SUBTITLE_MIN_HEIGHT })
      .padding({ top: Constants.SUBTITLE_PADDING_TOP, bottom: Constants.SUBTITLE_PADDING_BOTTOM,
        left: Constants.TERTIARY_TEXT_MARGIN_LEFT, right: Constants.TERTIARY_IMAGE_MARGIN_RIGHT})
      Column() {
        List() {
          ForEach(this.mediaDocListItem, (item, index) => {
            ListItem() {
              Column() {
                Row() {
                  Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
                    Row() {
                      Text(item.name)
                        .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
                        .fontColor($r('sys.color.ohos_id_color_text_primary'))
                        .fontWeight(FontWeight.Medium)
                        .flexGrow(Constants.FLEX_GROW)
                      Radio({ value: 'Radio', group: 'radioGroup' }).checked(this.isCheckList[index]).touchable(false)
                        .height(Constants.SHAPE_DIA)
                        .width(Constants.SHAPE_DIA)
                    }
                    .width(Constants.FULL_WIDTH)
                    .height(Constants.LISTITEM_ROW_HEIGHT)
                    .onClick(() => {
                        item.permissions.forEach((permission) => {
                          if (!index) {
                            if ((this.api >= Constants.API_VERSION_SUPPORT_STAGE) && (permission == PRECISE_LOCATION_PERMISSION)) {
                              return false;
                            }
                            this.grantUserGrantedPermission(item.accessTokenId, permission);
                            if (nowGrantResult != Constants.PERMISSION_INDEX) {
                              GrantResultFlag.push(-1);
                            } else {
                              GrantResultFlag.push(0);
                            }
                          } else {
                            if ((permission == PRECISE_LOCATION_PERMISSION) && (this.api >= Constants.API_VERSION_SUPPORT_STAGE)) {
                              if (this.accurateIsOn) {
                                this.revokeUserGrantedPermission(item.accessTokenId, permission);
                                this.accurateIsOn = false;
                              }
                            } else {
                              this.revokeUserGrantedPermission(item.accessTokenId, permission);
                            }

                            if (nowRevokeResult != Constants.PERMISSION_INDEX) {
                              RevokeResultFlag.push(-1);
                              this.authorizeDialogController.open();
                              setTimeout(()=> {
                                this.authorizeDialogController.close();
                              }, Constants.DELAY_TIME)
                            } else {
                              RevokeResultFlag.push(0);
                            }
                          }
                        })
                        if (!index) {
                          if (GrantResultFlag.indexOf(-1) > -1) {
                            this.authorizeDialogController.open();
                            setTimeout(()=> {
                              this.authorizeDialogController.close();
                            }, Constants.DELAY_TIME)
                          } else {
                            this.isCheckList = [true, false];
                          }
                        } else {
                          if (RevokeResultFlag.indexOf(-1) > -1) {
                            this.authorizeDialogController.open();
                            setTimeout(()=> {
                              this.authorizeDialogController.close();
                            }, Constants.DELAY_TIME)
                          } else {
                            this.isCheckList = [false, true];
                          }
                        }
                    })
                  }
                }
              }
            }
            .padding({ left: $r('sys.float.ohos_id_card_margin_start'), right: $r('sys.float.ohos_id_card_margin_end') })
            .borderRadius($r("sys.float.ohos_id_corner_radius_default_l"))
            .linearGradient((this.isTouch === index) ? {
                angle: 90,
                direction: GradientDirection.Right,
                colors: [['#DCEAF9', 0.0], ['#FAFAFA', 1.0]]
              } : {
                angle: 90,
                direction: GradientDirection.Right,
                colors: [[$r("sys.color.ohos_id_color_list_card_bg"), 1], [$r("sys.color.ohos_id_color_list_card_bg"), 1]]
              })
            .onTouch((event: TouchEvent) => {
              if (event.type === TouchType.Down) {
                this.isTouch = index;
              }
              if (event.type === TouchType.Up) {
                this.isTouch = -1;
              }
            })
            .margin({ top: Constants.TERTIARY_LISTITEM_MARGIN_TOP })
          }, item => JSON.stringify(item))
        }
        .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
        .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
        .padding(Constants.LIST_PADDING_TOP)
        .divider({
          strokeWidth: Constants.DIVIDER,
          color: $r('sys.color.ohos_id_color_list_separator'),
          startMargin: Constants.DEFAULT_MARGIN_START,
          endMargin: Constants.DEFAULT_MARGIN_END
        })

        if ((this.api >= Constants.API_VERSION_SUPPORT_STAGE) && (permissions.includes(PRECISE_LOCATION_PERMISSION))) {
          Column() {
            Row() {
              Text($r('app.string.precise_location'))
                .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
                .fontWeight(FontWeight.Medium)
                .flexGrow(Constants.FLEX_GROW)
              Toggle({ type: ToggleType.Switch, isOn: this.accurateIsOn })
                .selectedColor($r('sys.color.ohos_id_color_toolbar_icon_actived'))
                .switchPointColor($r('sys.color.ohos_id_color_foreground_contrary'))
                .onChange((isOn: boolean) => {
                  var acManager = abilityAccessCtrl.createAtManager()
                  if (isOn) {
                    acManager.grantUserGrantedPermission(bundleInfo.appInfo.accessTokenId, PRECISE_LOCATION_PERMISSION, Constants.PERMISSION_FLAG)
                      .then(() => { this.accurateIsOn = true })
                  } else {
                    acManager.revokeUserGrantedPermission(bundleInfo.appInfo.accessTokenId, PRECISE_LOCATION_PERMISSION, Constants.PERMISSION_FLAG)
                      .then(() => { this.accurateIsOn = false })
                  }
                })
                .padding({ right: 0 })
                .enabled(this.isCheckList[0])
            }.width(Constants.FULL_WIDTH)
            .height(Constants.LISTITEM_ROW_HEIGHT)
          }.margin({ top: Constants.LOCATION_MARGIN_TOP, bottom: Constants.LOCATION_MARGIN_BOTTOM })
          .padding({
            left: Constants.DEFAULT_PADDING_START,
            right: Constants.DEFAULT_PADDING_END,
            top: Constants.TERTIARY_LIST_PADDING_TOP,
            bottom: Constants.TERTIARY_LIST_PADDING_BOTTOM
          })
          .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
          .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))

          Row() {
            Text($r('app.string.get_the_exact_position'))
              .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
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
      .enabled(!this.isRisk)
      .opacity(this.isRisk ? $r('sys.float.ohos_id_alpha_disabled') : 1)
    }
    .width(Constants.FULL_WIDTH)
  }
}

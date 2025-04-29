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
import bundleManager from '@ohos.bundle.bundleManager';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import { BusinessError } from '@ohos.base';
import { showSubPermissionsGroup } from '../common/model/permissionGroup';
import { Log, getPermissionLabel } from '../common/utils/utils';
import Constants from '../common/utils/constant';
import { MediaDocObj, RouterParams3, AppInfo, CheckboxInfo } from '../common/model/typedef';
import { GlobalContext } from '../common/utils/globalContext';
import { Permission, PermissionGroup } from '../common/model/definition';
import { PermissionUtils } from '../common/utils/permissionUtils';

const showPrecise: number[] = [Constants.PERMISSION_ALLOW, Constants.PERMISSION_ALLOWED_ONLY_DURING_USE];
let accessTokenId: number = 0;
let reqPermissionInfo: bundleManager.ReqPermissionDetail;

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
        }
      }.backgroundColor($r('sys.color.background_secondary'))
    }
  }

  onPageShow() {
    if (this.refresh) {
      this.refreshStatus();
    }
    this.refresh = true;
  }

  refreshStatus() {
    if (reqPermissionInfo) {
      this.isRefreshReason ++;
    }
    Log.info('Refresh permission status');
    let isGranted = this.currentGroup === 'LOCATION' ? Constants.PERMISSION_BAN : Constants.PERMISSION_ALLOW;
    let folderStatus = [false, false, false];
    let atManager = abilityAccessCtrl.createAtManager();
    for (let i = 0; i < this.permissions.length; i++) {
      let permission = this.permissions[i];
      if (this.currentGroup === 'LOCATION') {
        continue;
      }
      let res = atManager.verifyAccessTokenSync(this.tokenId, permission);
      if (res != abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        isGranted = Constants.PERMISSION_BAN;
      }
      if (this.currentGroup === 'FOLDER' && res === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        switch (permission) {
          case Permission.READ_WRITE_DOWNLOAD_DIRECTORY:
            folderStatus[0] = true;
            break;
          case Permission.READ_WRITE_DESKTOP_DIRECTORY:
            folderStatus[1] = true;
            break;
          case Permission.READ_WRITE_DOCUMENTS_DIRECTORY:
            folderStatus[2] = true;
            break;
        }
      }
    }
    Log.info('isGranted: ' + JSON.stringify(isGranted));
    this.folderStatus = folderStatus;

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
  @State noForeground: boolean = false;
  @State isTouch: number = -1;
  @State isCheck: string = '';
  @State reason: string = '';
  @State label: string = '';
  @State version: string = '';
  @State permissionLabels: Array<ResourceStr> = [];
  @Link @Watch('updateReason') isRefreshReason: number;

  /**
   * Update reason
   */
  updateReason() {
    bundleManager.getApplicationInfo(
      this.applicationInfo.bundleName, bundleManager.ApplicationFlag.GET_APPLICATION_INFO_DEFAULT
    ).then(appInfo => {
      let bundleContext = this.context.createBundleContext(this.bundleName)
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
    let context = this.context.createModuleContext(this.bundleName, reqPermissionInfo.moduleName);
    context.resourceManager.getStringValue(reqPermissionInfo.reasonId).then(value => {
      if (value !== undefined) {
        this.reason = value.slice(Constants.START_SUBSCRIPT, Constants.END_SUBSCRIPT);
      }
    })
  }

  getCheckboxInfo(permission: Permission): CheckboxInfo {
    switch (permission) {
      case Permission.READ_WRITE_DOWNLOAD_DIRECTORY:
        return new CheckboxInfo($r('app.string.Download_folder'), 0);
      case Permission.READ_WRITE_DESKTOP_DIRECTORY:
        return new CheckboxInfo($r('app.string.Desktop_folder'), 1);
      case Permission.READ_WRITE_DOCUMENTS_DIRECTORY:
        return new CheckboxInfo($r('app.string.Document_folder'), 2);
      default:
        return new CheckboxInfo($r('app.string.Download_folder'), 0);
    }
  }

  getMediaDocList() {
    if (this.currentGroup == 'PASTEBOARD') {
      this.mediaDocListItem.push(
        new MediaDocObj($r('app.string.per_use_query'), this.permissions, Constants.PERMISSION_ONLY_THIS_TIME)
      );
      this.mediaDocListItem.push(
        new MediaDocObj($r('app.string.always_allow'), this.permissions, Constants.PERMISSION_ALLOW)
      );
    } else if (this.currentGroup == 'LOCATION') {
      this.selected = GlobalContext.load('locationStatus');
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
    } else {
      this.mediaDocListItem.push(
        new MediaDocObj($r('app.string.allow'), this.permissions, Constants.PERMISSION_ALLOW)
      );
    }
    this.mediaDocListItem.push(
      new MediaDocObj($r('app.string.ban'), this.permissions, Constants.PERMISSION_BAN)
    );
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
  }

  /**
   * Lifecycle function, executed when the page is initialized
   */
  aboutToAppear() {
    this.selected = this.status;
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
            this.isRisk = (flag == Constants.PERMISSION_POLICY_FIXED) ? true : false;
            flag === Constants.PERMISSION_ALLOW_THIS_TIME ? this.selected = Constants.PERMISSION_ONLY_THIS_TIME : null;
          })
        }).catch((error: BusinessError) => {
          Log.error('bundle.getBundleInfo failed. Cause: ' + JSON.stringify(error));
        })
    } catch (err) {
      Log.error('bundle.getBundleInfo failed. Cause: ' + JSON.stringify(err));
    }
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
      if (this.reason || this.permissionLabels.length > 0) {
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
      Row() {
        Text() {
          Span(this.backTitle)
          Span($r('app.string.access_permission'))
        }
          .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
          .fontColor($r('sys.color.icon_secondary'))
          .fontWeight(FontWeight.Medium)
          .textAlign(TextAlign.Start)
          .lineHeight(Constants.SUBTITLE_LINE_HEIGHT)
      }.width(Constants.FULL_WIDTH)
      .constraintSize({ minHeight: Constants.SUBTITLE_MIN_HEIGHT })
      .padding({ top: Constants.SUBTITLE_PADDING_TOP, bottom: Constants.SUBTITLE_PADDING_BOTTOM,
        left: Constants.TERTIARY_TEXT_MARGIN_LEFT, right: Constants.TERTIARY_IMAGE_MARGIN_RIGHT})
      Column() {
        List() {
          if (this.currentGroup === 'FOLDER') {
            ForEach(this.permissions, (permission: Permission) => {
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
                    if (this.folderStatus[this.getCheckboxInfo(permission).index]) {
                      PermissionUtils.revokePermissionWithResult(permission, Constants.PERMISSION_FLAG, accessTokenId);
                      this.folderStatus[this.getCheckboxInfo(permission).index] = false;
                    } else {
                      PermissionUtils.grantPermissionWithResult(permission, Constants.PERMISSION_FLAG, accessTokenId);
                      this.folderStatus[this.getCheckboxInfo(permission).index] = true;
                    }
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
          } else {
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
                      .onClick(() => {
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
                .onChange((isOn: boolean) => {
                  if (isOn) {
                    PermissionUtils.grantPermissionWithResult(
                      Permission.LOCATION, Constants.PERMISSION_FLAG, accessTokenId
                    );
                    this.accurateIsOn = true;
                  } else {
                    PermissionUtils.revokePermissionWithResult(
                      Permission.LOCATION, Constants.PERMISSION_FLAG, accessTokenId
                    );
                    this.accurateIsOn = false;
                  }
                })
                .padding({ right: 0 })
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
      .enabled(!this.isRisk && !this.noForeground)
      .opacity((!this.isRisk && !this.noForeground) ? 1 : $r('sys.float.ohos_id_alpha_disabled'))
    }
    .width(Constants.FULL_WIDTH)
  }
}

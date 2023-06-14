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
import bundleManager from "@ohos.bundle.bundleManager";
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import audio from '@ohos.multimedia.audio'
import camera from '@ohos.multimedia.camera'
import { verifyAccessToken} from "../common/utils/utils";
import { makePy, appSort, getSortId } from "../common/utils/utils";
import { globalDialog } from "../common/components/dialog";
import Constants from '../common/utils/constant';
import { polymorphismGroup, globalGroup } from "../common/model/permissionGroup";

var TAG = 'PermissionManager_MainAbility:';

@Extend(Image) function customizeImage(width: number, height: number) {
  .objectFit(ImageFit.Contain)
  .width(width)
  .height(height)
}

let routerData: any = router.getParams()['routerData']; // Routing jump data
let backTitle = router.getParams()['backTitle']; // return title name
const FUZZY_LOCATION_PERMISSION = 'ohos.permission.APPROXIMATELY_LOCATION';
const PRECISE_LOCATION_PERMISSION = 'ohos.permission.LOCATION';
let globalIsOn: any = router.getParams()['globalIsOn']; // return title name

class ApplicationObj {
  bundleName: string
  labelId: string
  iconId: string
  index: number
  accessTokenId: number
  permission: string
  alphabeticalIndex: string
  sortId: string
  constructor(
    bundleName: string,
    labelId: string,
    iconId: string,
    index: number,
    accessTokenId: number,
    permission: string,
    alphabeticalIndex: string,
    sortId: string) {
    this.bundleName = bundleName
    this.labelId = labelId
    this.iconId = iconId
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
  @State polymorphismIsOn: Array<boolean> = [];

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
                applicationItem({ polymorphismIsOn: $polymorphismIsOn })

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

  onPageShow() {
    console.log(TAG + "onPageShow");
    if (polymorphismGroup.indexOf(globalThis.currentPermissionGroup) !== -1) {
      var bundleNames = [];
      routerData.forEach(permissionmanager => {
        permissionmanager.bundleNames.forEach( bundleName => {
          if (bundleNames.indexOf(bundleName) == -1) {
            bundleNames.push(bundleName);
          }
        })
      })

      bundleNames.forEach((bundleName, index) => {
        bundleManager.getBundleInfo(bundleName, bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION | bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_REQUESTED_PERMISSION).then(res => {
          // 0: have permission; -1: no permission
          this.polymorphismIsOn[index] = true;
          let reqPermissions: Array<string> = [];
          res.reqPermissionDetails.forEach(item => {
            reqPermissions.push(item.name);
          })
          for (let j = 0; j < routerData.length; j++) {
            if ((routerData[j].permission == PRECISE_LOCATION_PERMISSION) && (res.targetVersion >= Constants.API_VERSION_SUPPORT_STAGE)) {
              continue;
            }
            if ((routerData[j].permission == FUZZY_LOCATION_PERMISSION) && (res.targetVersion < Constants.API_VERSION_SUPPORT_STAGE)) {
              continue;
            }
            if (reqPermissions.indexOf(routerData[j].permission) == -1) {
              continue;
            }
            verifyAccessToken(res.appInfo.accessTokenId, routerData[j].permission).then((access) => {
              if (Number(access) === abilityAccessCtrl.GrantStatus.PERMISSION_DENIED) {
                this.polymorphismIsOn[index] = false;
              }
            });
          }
        }).catch(error => {
          console.log(TAG + bundleName + "onPageShow getBundleInfo failed, cause: " + JSON.stringify(error));
        })
      })
    }
  }
}

@Component
struct applicationItem {
  @State permissionNum: number = Constants.PERMISSION_NUM; // permission num
  @State toggleIsOn: object = {}; // toggle switch state array
  @State isRisk: object = {};
  @State applicationList: ApplicationObj[] = []; // application info array
  @State searchResult: boolean = true; // search results
  @Link polymorphismIsOn: Array<boolean>;
  @State globalIsOn: boolean = true;

  privacyDialogController: CustomDialogController = new CustomDialogController({
    builder: globalDialog({ globalIsOn: $globalIsOn }),
    autoCancel: false,
    alignment: DialogAlignment.Center,
    customStyle: true
  })

  @Builder ListItemLayout(item, index) {
    ListItem() {
      Row() {
        Column() {
          Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
            Row() {
              Image(item.iconId)
                .customizeImage(Constants.AUTHORITY_IMAGE_WIDTH, Constants.AUTHORITY_IMAGE_HEIGHT)
                .margin({ right: Constants.AUTHORITY_IMAGE_MARGIN_RIGHT })
              Column() {
                Text(item.labelId)
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
              if (polymorphismGroup.indexOf(globalThis.currentPermissionGroup) == -1) {
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
                    let _this = this;
                    if (isOn) {
                      let promises = routerData.map(it => new Promise((resolve) => {
                        _this.grantUserGrantedPermission(item.accessTokenId, it.permission, item.index, resolve);
                      }));
                      Promise.all(promises).then(function() {
                        _this.toggleIsOn[item.index] = true;
                        let num = Constants.PERMISSION_NUM;
                        for (let key in _this.toggleIsOn) {
                          if (_this.toggleIsOn[key]) {
                            num++;
                          }
                        }
                        _this.permissionNum = num;
                      });
                    } else {
                      let promises = routerData.map(it => new Promise((resolve) => {
                        _this.revokeUserGrantedPermission(item.accessTokenId, it.permission, item.index, resolve);
                      }));
                      Promise.all(promises).then(function() {
                        _this.toggleIsOn[item.index] = false;
                        let num = Constants.PERMISSION_NUM;
                        for (let key in _this.toggleIsOn) {
                          if (_this.toggleIsOn[key]) {
                            num++;
                          }
                        }
                        _this.permissionNum = num;
                      });
                    }
                  })
              } else {
                Text(this.polymorphismIsOn[item.index] ? $r('app.string.allow') : $r('app.string.ban'))
                .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                .margin({ right: Constants.AUTHORITY_IMAGE_MARGIN_RIGHT })
                Image($r('app.media.ic_public_arrow_right'))
                  .fillColor($r('sys.color.ohos_id_color_tertiary'))
                  .customizeImage(Constants.IMAGE_WIDTH, Constants.IMAGE_HEIGHT)
              }
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
          if (polymorphismGroup.indexOf(globalThis.currentPermissionGroup) !== -1) {
            var permissions: any = [];
            routerData.forEach(item => {
              permissions.push(item.permission);
            })
            globalThis.allBundleInfo.forEach(bundleInfo => {
              if (bundleInfo.bundleName === item.bundleName) {
                globalThis.applicationInfo = bundleInfo;
              }
            })
            router.pushUrl({
              url: 'pages/application-tertiary',
              params: {
                routerData: item.bundleName,
                backTitle,
                permission: permissions,
                status: this.polymorphismIsOn[item.index] ? Constants.RADIO_ALLOW_INDEX : Constants.RADIO_BAN_INDEX
              }
            });
          }
        })
      }
    }.padding({ left: Constants.DEFAULT_PADDING_START, right: Constants.DEFAULT_PADDING_END })
    .enabled(!this.isRisk[item.index])
    .opacity(this.isRisk[item.index] ? $r('sys.float.ohos_id_alpha_disabled') : 1)
  }

  /**
   * Take the total number of access applications
   */
  getGrantApplicationNumber() {
    if (polymorphismGroup.indexOf(globalThis.currentPermissionGroup) !== -1) {
      var sum = this.polymorphismIsOn.filter(item => item == true);
      return sum.length;
    } else {
      return this.permissionNum;
    }
  }

  /**
   * Grant permissions to the app
   * @param {Number} accessTokenId
   * @param {String} permission permission name
   * @param {Number} index Array index to modify permission status
   */
  grantUserGrantedPermission(accessTokenId, permission, index, resolve) {
    abilityAccessCtrl.createAtManager().grantUserGrantedPermission(
      accessTokenId, permission, Constants.PERMISSION_FLAG).then(result => {
      // result: 0 Authorization succeeded; result: -1 Authorization failed
      resolve(result);
    }).catch(error => {
      resolve(-1);
      console.error(TAG + 'abilityAccessCtrl.createAtManager.grantUserGrantedPermission failed. Cause: ' + JSON.stringify(error));
    })
  }

  /**
   * Deauthorize the app
   * @param {Number} accessTokenId
   * @param {String} permission permission name
   * @param {Number} index Array index to modify permission status
   */
  revokeUserGrantedPermission(accessTokenId, permission, index, resolve) {
    abilityAccessCtrl.createAtManager().revokeUserGrantedPermission(
      accessTokenId, permission, Constants.PERMISSION_FLAG).then(result => {
      // result: 0 successfully cancel the authorization; result: -1 cancel the authorization failed
      resolve(result);
    }).catch(error => {
      resolve(-1);
      console.error(TAG + 'abilityAccessCtrl.createAtManager.revokeUserGrantedPermission failed. Cause: ' + JSON.stringify(error));
    })
  }

  /**
   * Lifecycle function, executed when the page is initialized
   */
  aboutToAppear() {
    var bundleNames = [];
    this.applicationList = [];
    routerData.forEach(permissionmanager => {
      permissionmanager.bundleNames.forEach( bundleName => {
        if (bundleNames.indexOf(bundleName) == -1) {
          bundleNames.push(bundleName);
        }
      })
    })

    let atManager = abilityAccessCtrl.createAtManager();
    for (let i = 0; i < bundleNames.length; i++) {
      // Get BundleInfo based on bundle name
      globalThis.allBundleInfo.forEach(bundleInfo => {
        if (bundleInfo.bundleName === bundleNames[i]) {
          this.applicationList.push(
            new ApplicationObj(
            bundleInfo.bundleName,
            bundleInfo.label,
            bundleInfo.icon,
              i,
            bundleInfo.tokenId,
            routerData[0].permission,
            makePy(bundleInfo.label)[0].slice(0, 1),
            getSortId(bundleInfo.label)) // Get the first letter in the returned initials array
          );
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
          // 0: have permission; -1: no permission
          var boole = true;
          this.permissionNum++;
          for (let j = 0; j < routerData.length; j++) {
            if (bundleInfo.permissions.indexOf(routerData[j].permission) == -1) {
              continue;
            }
            verifyAccessToken(bundleInfo.tokenId, routerData[j].permission).then((access) => {
              if (Number(access) === Constants.PERMISSION_INDEX) {
                if (boole) {
                  this.toggleIsOn[i] = true;
                }
              } else {
                if (boole) {
                  this.permissionNum--;
                }
                boole = false;
                this.toggleIsOn[i] = false;
              }
            });
          }
        }
      })
    }
    if (globalGroup.indexOf(globalThis.currentPermissionGroup) !== -1) {
      this.globalIsOn = globalIsOn;
      if (globalThis.currentPermissionGroup == "CAMERA") {
        let cameraManager = camera.getCameraManager(globalThis.context);
        cameraManager.on('cameraMute', curMuted => {
          this.globalIsOn = !curMuted;
        })
      } else {
        var audioManager = audio.getAudioManager();
        let audioVolumeManager = audioManager.getVolumeManager();
        let groupid = audio.DEFAULT_VOLUME_GROUP_ID;
        audioVolumeManager.getVolumeGroupManager(groupid).then(audioVolumeGroupManager => {
          audioVolumeGroupManager.on('micStateChange', micStateChange => {
            this.globalIsOn = !micStateChange.mute;
          })
        })
      }
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
          if (globalGroup.indexOf(globalThis.currentPermissionGroup) !== -1) {
            Row() {
              Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
                Text(globalThis.currentPermissionGroup == "CAMERA" ? $r('app.string.camera') : $r('app.string.microphone'))
                  .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE).fontColor($r('sys.color.ohos_id_color_text_primary'))
                  .fontWeight(FontWeight.Medium)
                Row() {
                  Toggle({ type: ToggleType.Switch, isOn: this.globalIsOn })
                    .selectedColor($r('sys.color.ohos_id_color_toolbar_icon_actived'))
                    .switchPointColor($r('sys.color.ohos_id_color_foreground_contrary'))
                    .padding({ right: 0 })
                    .onChange((isOn: boolean) => {
                      if (isOn) {
                        if (globalThis.currentPermissionGroup == "CAMERA") {
                          let cameraManager = camera.getCameraManager(globalThis.context);
                          cameraManager.muteCamera(false);
                        } else {
                          var audioManager = audio.getAudioManager();
                          let audioVolumeManager = audioManager.getVolumeManager();
                          let groupid = audio.DEFAULT_VOLUME_GROUP_ID;
                          audioVolumeManager.getVolumeGroupManager(groupid).then(audioVolumeGroupManager => {
                            audioVolumeGroupManager.setMicrophoneMute(false)
                          })
                        }
                      }
                    })
                  Row().onClick(() => { this.privacyDialogController.open() })
                    .width(Constants.DEFAULT_SLIDER_WIDTH).height(Constants.DEFAULT_SLIDER_HEIGHT)
                    .position({ x: this.globalIsOn ? 0 : Constants.OFFSET, y: 0 })
                }.clip(true)
              }.height(Constants.LISTITEM_ROW_HEIGHT)
              .padding({ left: Constants.DEFAULT_PADDING_START, right: Constants.DEFAULT_PADDING_END })
            }.padding({ top: Constants.LIST_PADDING_TOP, bottom: Constants.LIST_PADDING_BOTTOM })
            .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
            .borderRadius(Constants.BORDER_RADIUS)
            .margin({ top: Constants.TERTIARY_ROW_MARGIN_TOP })
          }
          Flex({ justifyContent: FlexAlign.Start }) {
            if (this.globalIsOn) {
              Text(String(this.getGrantApplicationNumber()))
                .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                .margin({ top: Constants.AUTHORITY_TEXT_MARGIN_TOP, left: Constants.AUTHORITY_TEXT_MARGIN_LEFT })
              Text($r('app.string.number_of_authorized_applications'))
                .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                .margin({ top: Constants.AUTHORITY_TEXT_MARGIN_TOP, left: Constants.AUTHORITY_TEXT_MARGIN_LEFT })
            } else {
              Text(globalThis.currentPermissionGroup == "CAMERA" ? $r('app.string.camera_is_off') : $r('app.string.microphone_is_off'))
                .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                .margin({ top: Constants.AUTHORITY_TEXT_MARGIN_TOP, left: Constants.AUTHORITY_TEXT_MARGIN_LEFT })
            }
          }.padding({ left: Constants.DEFAULT_PADDING_START, right: Constants.DEFAULT_PADDING_END })
          .margin({ bottom: Constants.AUTHORITY_ROW_MARGIN_BOTTOM })
          Scroll() {
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
                    List() {
                      ForEach(appSort(this.applicationList), (item, index) => {
                        this.ListItemLayout(item, index)
                      }, item => JSON.stringify(item))
                    }
                    .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
                    .borderRadius(Constants.BORDER_RADIUS)
                    .padding({ top: Constants.LIST_PADDING_TOP, bottom: Constants.LIST_PADDING_BOTTOM })
                  }
                }
              }.width(Constants.FULL_WIDTH)
              .margin({ bottom: globalGroup.includes(globalThis.currentPermissionGroup) ? Constants.AUTHORITY_LIST_MARGIN_BOTTOM_GLOBAL : Constants.AUTHORITY_LIST_MARGIN_BOTTOM })
            }
          }.scrollBar(BarState.Off)
          .borderRadius(Constants.BORDER_RADIUS)
        }.padding({ left: Constants.AUTHORITY_LISTITEM_PADDING_LEFT })
        Column() {
          alphabetIndexerComponent({ applicationItem: $applicationList })
        }.width(Constants.AUTHORITY_ALPHABETINDEX_WIDTH)
         .padding({ top: Constants.AUTHORITY_ALPHABETINDEX_PADDING_TOP })
      }.flexGrow(Constants.FLEX_GROW)
    }.height(Constants.FULL_HEIGHT)
  }
}

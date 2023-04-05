/*
 * Copyright (c) 2021-2022 Huawei Device Co., Ltd.
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
import bundle from "@ohos.bundle";
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import audio from '@ohos.multimedia.audio'
import camera from '@ohos.multimedia.camera'
import { getAppLabel, getAppIcon, verifyAccessToken} from "../common/utils/utils";
import { makePy } from "../common/utils/utils";
import { globalDialog } from "../common/components/dialog";
import Constants from '../common/utils/constant';
import { polymorphismGroup, globalGroup } from "../common/model/permissionGroup";

var TAG = 'PermissionManager_MainAbility:'

@Extend(Image) function customizeImage(width: number, height: number) {
  .objectFit(ImageFit.Contain)
  .width(width)
  .height(height)
}

let routerData: any = router.getParams()['routerData']; // Routing jump data
let backTitle = router.getParams()['backTitle']; // return title name
const FUZZY_LOCATION_PERMISSION = 'ohos.permission.APPROXIMATELY_LOCATION'
const PRECISE_LOCATION_PERMISSION = 'ohos.permission.LOCATION'
let globalIsOn: any = router.getParams()['globalIsOn']; // return title name

class ApplicationObj {
  labelId: string
  iconId: string
  index: number
  accessTokenId: number
  permission: string
  alphabeticalIndex: string
  constructor(
    labelId: string,
    iconId: string,
    index: number,
    accessTokenId: number,
    permission: string,
    alphabeticalIndex: string) {
    this.labelId = labelId
    this.iconId = iconId
    this.index = index
    this.accessTokenId = accessTokenId
    this.permission = permission
    this.alphabeticalIndex = alphabeticalIndex
  }
} // application information

@Entry
@Component
struct locationInfoPage {
  @State polymorphismIsOn: Array<boolean> = []

  build() {
    GridContainer({ gutter: Constants.GUTTER, margin: Constants.GRID_MARGIN }) {
      Row() {
        Row()
          .useSizeType({
            xs: { span: Constants.LEFT_XS_SPAN, offset: Constants.LEFT_XS_OFFSET },
            sm: { span: Constants.LEFT_SM_SPAN, offset: Constants.LEFT_SM_OFFSET },
            md: { span: Constants.LEFT_MD_SPAN, offset: Constants.LEFT_MD_OFFSET },
            lg: { span: Constants.LEFT_LG_SPAN, offset: Constants.LEFT_LG_OFFSET }
          })
          .height(Constants.FULL_HEIGHT)
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
        .useSizeType({
          xs: { span: Constants.MIDDLE_XS_SPAN, offset: Constants.MIDDLE_XS_OFFSET },
          sm: { span: Constants.MIDDLE_SM_SPAN, offset: Constants.MIDDLE_SM_OFFSET },
          md: { span: Constants.MIDDLE_MD_SPAN, offset: Constants.MIDDLE_MD_OFFSET },
          lg: { span: Constants.MIDDLE_LG_SPAN, offset: Constants.MIDDLE_LG_OFFSET }
        })
        .height(Constants.FULL_HEIGHT)
        Row()
          .useSizeType({
            xs: { span: Constants.RIGHT_XS_SPAN, offset: Constants.RIGHT_XS_OFFSET },
            sm: { span: Constants.RIGHT_SM_SPAN, offset: Constants.RIGHT_SM_OFFSET },
            md: { span: Constants.RIGHT_MD_SPAN, offset: Constants.RIGHT_MD_OFFSET },
            lg: { span: Constants.RIGHT_LG_SPAN, offset: Constants.RIGHT_LG_OFFSET }
          })
          .height(Constants.FULL_HEIGHT)
      }
      .height(Constants.FULL_HEIGHT)
      .width(Constants.FULL_WIDTH)
      .backgroundColor($r("sys.color.ohos_id_color_sub_background"))
    }
  }

  onPageShow() {
    console.log(TAG + "onPageShow");
    if (polymorphismGroup.indexOf(globalThis.currentPermissionGroup) !== -1) {
      var bundleNames = []
      routerData.forEach(permissionmanager => {
        permissionmanager.bundleNames.forEach( bundleName => {
          if (bundleNames.indexOf(bundleName) == -1) {
            bundleNames.push(bundleName)
          }
        })
      })

      bundleNames.forEach((bundleName, index) => {
        bundle.getBundleInfo(bundleName, Constants.PARMETER_BUNDLE_FLAG).then(res => {
          // 0: have permission; -1: no permission
          this.polymorphismIsOn[index] = true
          for (let j = 0; j < routerData.length; j++) {
            if ((routerData[j].permission == PRECISE_LOCATION_PERMISSION) && (res.targetVersion >= Constants.API_VERSION_SUPPORT_STAGE)) {
              continue
            }
            if ((routerData[j].permission == FUZZY_LOCATION_PERMISSION) && (res.targetVersion < Constants.API_VERSION_SUPPORT_STAGE)) {
              continue
            }
            if (res.reqPermissions.indexOf(routerData[j].permission) == -1) {
              continue
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
  @State applicationList: ApplicationObj[] = []; // application info array
  @State searchResult: boolean = true; // search results
  @State placeholder: string = ''
  @State bundleNameGroup: Array<string> = []
  @Link polymorphismIsOn: Array<boolean>
  @State globalIsOn: boolean = true

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
              Text(item.labelId)
                .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
                .fontColor($r('app.color.text_color'))
                .fontWeight(FontWeight.Medium)
                .flexGrow(Constants.FLEX_GROW)
              if (polymorphismGroup.indexOf(globalThis.currentPermissionGroup) == -1) {
                Toggle({ type: ToggleType.Switch, isOn: this.toggleIsOn[item.index] })
                  .selectedColor($r('app.color.button_color'))
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
                        for(let key in _this.toggleIsOn){
                          if(_this.toggleIsOn[key]){
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
                        for(let key in _this.toggleIsOn){
                          if(_this.toggleIsOn[key]){
                            num++;
                          }
                        }
                        _this.permissionNum = num;
                      });
                    }
                  })
              }else {
                Text(this.polymorphismIsOn[item.index] ? $r('app.string.allow') : $r('app.string.ban'))
                .fontSize(Constants.TEXT_SMAL_FONT_SIZE)
                .fontColor($r('app.color.label_color_light'))
                .margin({ right: Constants.AUTHORITY_IMAGE_MARGIN_RIGHT })
                Image($r('app.media.ic_public_arrow_right'))
                  .customizeImage(Constants.IMAGE_WIDTH, Constants.IMAGE_HEIGHT)
              }
            }
            .width(Constants.FULL_WIDTH)
            .height(Constants.AUTHORITY_ROW_HEIGHT)
            .constraintSize({ minHeight: Constants.AUTHORITY_CONSTRAINTSIZE_MINHEIGHT })
          }
          if (!index) {
            Row() {
              Flex() {
                Column().width(Constants.APPLICATION_TEXT_DECORATION_MARGIN_LEFT)
                Column()
                  .backgroundColor($r('app.color.text_decoration_color'))
                  .height(Constants.TEXT_DECORATION_HEIGHT)
                  .flexGrow(Constants.FLEX_GROW)
              }
            }
          }
        }.onClick(() => {
          if (polymorphismGroup.indexOf(globalThis.currentPermissionGroup) !== -1) {
            var permissions: any = []
            routerData.forEach(item => {
              permissions.push(item.permission)
            })
            router.pushUrl({
              url: 'pages/application-tertiary',
              params: {
                routerData: this.bundleNameGroup[item.index],
                backTitle,
                permission: permissions,
                status: this.polymorphismIsOn[item.index] ? Constants.RADIO_ALLOW_INDEX : Constants.RADIO_BAN_INDEX
              }
            });
          }
        })
      }
    }.padding({ left: Constants.DEFAULT_PADDING_START, right: Constants.DEFAULT_PADDING_END })
  }

  /**
   * Take the total number of access applications
   */
  getGrantApplicationNumber() {
    if (polymorphismGroup.indexOf(globalThis.currentPermissionGroup) !== -1) {
      var sum = this.polymorphismIsOn.filter(item => item == true)
      return sum.length
    }else {
      return this.permissionNum
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
    var bundleNames = []
    this.applicationList = []
    routerData.forEach(permissionmanager => {
      permissionmanager.bundleNames.forEach( bundleName => {
        if (bundleNames.indexOf(bundleName) == -1) {
          bundleNames.push(bundleName)
        }
      })
    })

    globalThis.context.resourceManager.getString($r("app.string.textInput_placeholder").id).then(val => {
      this.placeholder = val
    })

    // initial then fill values when sync return which may cause sync panic
    for (let i = 0; i < bundleNames.length; i++) {
      this.applicationList.push(new ApplicationObj('', '', i, 0, '', ''));
      this.bundleNameGroup.push(bundleNames[i])
    }

    for (let i = 0; i < bundleNames.length; i++) {
      // Get BundleInfo based on bundle name
      bundle.getBundleInfo(bundleNames[i], Constants.PARMETER_BUNDLE_FLAG).then(res => {
        Promise.all([getAppLabel(res.appInfo.labelId, res.name),
        getAppIcon(res.appInfo.iconId, res.name)
        ])
          .then((values) => {
            this.applicationList[i] = (
              new ApplicationObj(
              String(values[0]),
              String(values[1]),
                i,
                res.appInfo.accessTokenId,
                routerData[0].permission,
              makePy(values[0])[0].slice(0, 1)) // Get the first letter in the returned initials array
            );
            this.bundleNameGroup[i] = bundleNames[i]
          });
        // 0: have permission; -1: no permission
        var boole = true;
        this.permissionNum++;
        for (let j = 0; j < routerData.length; j++) {
          if (res.reqPermissions.indexOf(routerData[j].permission) == -1) {
            continue
          }
          verifyAccessToken(res.appInfo.accessTokenId, routerData[j].permission).then((access) => {
            if (Number(access) === Constants.PERMISSION_INDEX) {
              if(boole){
                this.toggleIsOn[i] = true;
              }
            } else {
              if(boole){
                this.permissionNum--
              }
              boole = false;
              this.toggleIsOn[i] = false;
            }
          });
        }
      }).catch(error => {
        console.log(TAG + bundleNames[i] + "getBundleInfo failed, cause: " + JSON.stringify(error));
      })
    }
    if(globalGroup.indexOf(globalThis.currentPermissionGroup) !== -1) {
      this.globalIsOn = globalIsOn
    }
  }

  build() {
    Column() {
      Row() {
        textInput({
          placeholder: this.placeholder,
          applicationItem: $applicationList,
          searchResult: $searchResult
        })
      }.padding({
        left: Constants.AUTHORITY_TEXTINPUT_PADDING_LEFT,
        right: Constants.AUTHORITY_TEXTINPUT_PADDING_RIGHT
      })
      Flex({ alignItems:ItemAlign.Start, justifyContent: FlexAlign.Start }) {
        Column() {
          if(globalGroup.indexOf(globalThis.currentPermissionGroup) !== -1) {
            Row() {
              Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
                Text(globalThis.currentPermissionGroup == "CAMERA" ? $r('app.string.camera') : $r('app.string.microphone'))
                  .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE).fontColor($r('app.color.label_color'))
                  .fontWeight(FontWeight.Medium)
                Row() {
                  Toggle({ type: ToggleType.Switch, isOn: this.globalIsOn })
                    .selectedColor($r('app.color.button_color'))
                    .switchPointColor($r('app.color.selected_Color'))
                    .padding({ right: 0 })
                    .onChange((isOn: boolean) => {
                      if(isOn) {
                        if(globalThis.currentPermissionGroup == "CAMERA") {
                          let cameraManager = camera.getCameraManager(globalThis.context);
                          cameraManager.muteCamera(false);
                          this.globalIsOn = isOn;
                        }else {
                          var audioManager = audio.getAudioManager();
                          audioManager.setMicrophoneMute(false).then(() => {
                            this.globalIsOn = isOn
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
            .backgroundColor($r('app.color.default_background_color'))
            .borderRadius(Constants.BORDER_RADIUS)
            .margin({ top: Constants.TERTIARY_ROW_MARGIN_TOP })
          }
          Flex({ justifyContent: FlexAlign.Start }) {
            if(this.globalIsOn) {
              Text(String(this.getGrantApplicationNumber()))
                .fontSize(Constants.TEXT_SMAL_FONT_SIZE)
                .fontColor($r('app.color.secondary_font_color'))
                .margin({ top: Constants.AUTHORITY_TEXT_MARGIN_TOP, left: Constants.AUTHORITY_TEXT_MARGIN_LEFT })
              Text($r('app.string.number_of_authorized_applications'))
                .fontSize(Constants.TEXT_SMAL_FONT_SIZE)
                .fontColor($r('app.color.secondary_font_color'))
                .margin({ top: Constants.AUTHORITY_TEXT_MARGIN_TOP, left: Constants.AUTHORITY_TEXT_MARGIN_LEFT })
            }else {
              Text(globalThis.currentPermissionGroup == "CAMERA" ? $r('app.string.camera_is_off') : $r('app.string.microphone_is_off'))
                .fontSize(Constants.TEXT_SMAL_FONT_SIZE)
                .fontColor($r('app.color.secondary_font_color'))
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
                      ForEach(this.applicationList.slice(Constants.SLICE_START, this.applicationList.length - 1),
                      (item) => {
                        this.ListItemLayout(item, Constants.SLICE_START_INDEX)
                      }, item => item.toString())
                      ForEach(this.applicationList.slice(Constants.SLICE_END), (item) => {
                        this.ListItemLayout(item, Constants.SLICE_END_INDEX)
                      }, item => item.toString())
                    }
                    .backgroundColor($r('app.color.default_background_color'))
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

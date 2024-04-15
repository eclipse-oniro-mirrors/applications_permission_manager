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
import bundleManager from '@ohos.bundle.bundleManager';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import { BusinessError } from '@ohos.base';
import audio from '@ohos.multimedia.audio'
import camera from '@ohos.multimedia.camera'
import { Log, verifyAccessToken, indexValue, sortByName } from '../common/utils/utils';
import { ApplicationObj, GroupInfo, RouterParams1, PermissionApplications, AppInfo } from '../common/utils/typedef';
import { GlobalContext } from '../common/utils/globalContext';
import { globalDialog } from '../common/components/dialog';
import Constants from '../common/utils/constant';
import { polymorphismGroup, globalGroup, groups } from '../common/model/permissionGroup';

const FUZZY_LOCATION_PERMISSION = 'ohos.permission.APPROXIMATELY_LOCATION';
const PRECISE_LOCATION_PERMISSION = 'ohos.permission.LOCATION';
const BACKGROUND_LOCATION_PERMISSION = 'ohos.permission.LOCATION_IN_BACKGROUND';
const DOWNLOAD_PERMISSION = 'ohos.permission.READ_WRITE_DOWNLOAD_DIRECTORY';
const DESKTOP_PERMISSION = 'ohos.permission.READ_WRITE_DESKTOP_DIRECTORY';
const DOCUMENTS_PERMISSION = 'ohos.permission.READ_WRITE_DOCUMENTS_DIRECTORY';
let globalIsOn: boolean = (router.getParams() as RouterParams1).globalIsOn; // return title name

@Extend(Image)function customizeImage(width: number, height: number) {
  .objectFit(ImageFit.Contain)
  .width(width)
  .height(height)
  .draggable(false)
}

@Entry
@Component
struct locationInfoPage {
  private backTitle: ResourceStr = (router.getParams() as RouterParams1).backTitle;
  private list: PermissionApplications[] = (router.getParams() as RouterParams1).list;
  @State currentGroup: string = GlobalContext.load('currentPermissionGroup');
  @State polymorphismIsOn: Array<boolean> = [];
  @State folderStatusArray: Array<Array<boolean>> = [[]];

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
                applicationItem({ polymorphismIsOn: $polymorphismIsOn, folderStatusArray: $folderStatusArray })

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

  onPageShow() {
    if (polymorphismGroup.indexOf(this.currentGroup) !== -1) {
      let bundleNames: string[] = [];
      this.list.forEach(permissionManager => {
        permissionManager.bundleNames.forEach(bundleName => {
          if (bundleNames.indexOf(bundleName) == -1) {
            bundleNames.push(bundleName);
          }
        })
      })

      bundleNames.forEach((bundleName, index) => {
        bundleManager.getBundleInfo(
          bundleName,
          bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION |
          bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_REQUESTED_PERMISSION
        ).then(res => {
          this.getGroupStatus(res, index);
        }).catch((error: BusinessError) => {
          Log.error(bundleName + 'onPageShow getBundleInfo failed, cause: ' + JSON.stringify(error));
        })
      })
    }
  }

  getGroupStatus(res: bundleManager.BundleInfo, index: number) {
    this.polymorphismIsOn[index] = true;
    this.folderStatusArray[index] = [false, false, false];
    let reqPermissions: string[] = [];
    res.reqPermissionDetails.forEach(item => {
      reqPermissions.push(item.name);
    })
    if (this.currentGroup === 'LOCATION') {
      if (
        !reqPermissions.includes(FUZZY_LOCATION_PERMISSION) && res.targetVersion >= Constants.API_VERSION_SUPPORT_STAGE
      ) {
        this.polymorphismIsOn[index] = false;
      }
      for (let j = 0; j < this.list.length; j++) {
        if ((this.list[j].permission == PRECISE_LOCATION_PERMISSION) &&
            (res.targetVersion >= Constants.API_VERSION_SUPPORT_STAGE)) {
          continue;
        }
        if ((this.list[j].permission == FUZZY_LOCATION_PERMISSION) &&
            (res.targetVersion < Constants.API_VERSION_SUPPORT_STAGE)) {
          continue;
        }
        if (this.list[j].permission == BACKGROUND_LOCATION_PERMISSION) {
          continue;
        }
        if (reqPermissions.indexOf(this.list[j].permission) == -1) {
          continue;
        }
        verifyAccessToken(res.appInfo.accessTokenId, this.list[j].permission).then((access) => {
          Number(access) === abilityAccessCtrl.GrantStatus.PERMISSION_DENIED ?
            this.polymorphismIsOn[index] = false : null;
        });
      }
    }
    if (this.currentGroup === 'FOLDER') {
      for (let j = 0; j < this.list.length; j++) {
        if (reqPermissions.indexOf(this.list[j].permission) == -1) {
          continue;
        }
        let atManager = abilityAccessCtrl.createAtManager();
        let access = atManager.verifyAccessTokenSync(res.appInfo.accessTokenId, this.list[j].permission);
        if (Number(access) === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
          this.updateFolderStatus(index, j);
        }
      }
    }
  }

  updateFolderStatus(index: number, idx: number) {
    switch (this.list[idx].permission) {
      case DOWNLOAD_PERMISSION:
        this.folderStatusArray[index][0] = true;
        break;
      case DESKTOP_PERMISSION:
        this.folderStatusArray[index][1] = true;
        break;
      case DOCUMENTS_PERMISSION:
        this.folderStatusArray[index][2] = true;
        break;
    }
  }
}

@Component
struct applicationItem {
  private backTitle: ResourceStr = (router.getParams() as RouterParams1).backTitle;
  private list: PermissionApplications[] = (router.getParams() as RouterParams1).list;
  @State permissionNum: number = Constants.PERMISSION_NUM; // permission num
  @State toggleIsOn: boolean[] = []; // toggle switch state array
  @State isRisk: boolean[] = [];
  @State isFirst: boolean[] = [];
  @State applicationList: ApplicationObj[] = []; // application info array
  @State searchResult: boolean = true; // search results
  @Link polymorphismIsOn: Array<boolean>;
  @Link folderStatusArray: Array<Array<boolean>>;
  @State globalIsOn: boolean = true;
  @State selectedIndex: number = 0;
  @State isTouch: string = '';
  @State groupInfo: GroupInfo = new GroupInfo('', '', '', '', [], '', [], false);
  @State currentGroup: string = GlobalContext.load('currentPermissionGroup');
  @State isMuteSupported: boolean = GlobalContext.load('isMuteSupported');
  @State allBundleInfo: AppInfo[] = GlobalContext.load('allBundleInfo');
  scroller: Scroller = new Scroller();

  privacyDialogController: CustomDialogController | null = new CustomDialogController({
    builder: globalDialog({ globalIsOn: $globalIsOn }),
    autoCancel: false,
    alignment: DialogAlignment.Center,
    customStyle: true
  })

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
              if (polymorphismGroup.indexOf(this.currentGroup) == -1) {
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
                    let _this = this;
                    if (isOn) {
                      let promises = this.list.map(it => new Promise<number>((resolve) => {
                        _this.grantUserGrantedPermission(item.accessTokenId, it.permission, resolve);
                      }));
                      Promise.all(promises).then(() => {
                        _this.toggleIsOn[item.index] = true;
                        let num = _this.toggleIsOn.filter(item => item === true).length;
                        _this.permissionNum = num;
                      });
                    } else {
                      let promises = this.list.map(it => new Promise<number>((resolve) => {
                        _this.revokeUserGrantedPermission(item.accessTokenId, it.permission, resolve);
                      }));
                      Promise.all(promises).then(() => {
                        _this.toggleIsOn[item.index] = false;
                        let num = _this.toggleIsOn.filter(item => item === true).length;
                        _this.permissionNum = num;
                      });
                    }
                  })
              } else {
                if (this.currentGroup === 'FOLDER') {
                  Text() {
                    if (this.folderStatusArray[item.index].includes(true)) {
                      ForEach(this.folderStatusArray[item.index], (status: boolean, index) =>{
                        if (status) {
                          if (index !== this.folderStatusArray[item.index].indexOf(true)) {
                            Span($r('app.string.separator'))
                          }
                          Span(index === 0 ? $r('app.string.Download') : index === 1 ? $r('app.string.Desktop') : $r('app.string.Document'))
                        }
                      })
                    } else {
                      Span($r('app.string.ban'))
                    }
                  }
                    .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
                    .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                    .margin({ right: Constants.AUTHORITY_IMAGE_MARGIN_RIGHT })
                } else {
                  Text(this.polymorphismIsOn[item.index] ? $r('app.string.allow') : $r('app.string.ban'))
                    .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
                    .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                    .margin({ right: Constants.AUTHORITY_IMAGE_MARGIN_RIGHT })
                }
                Image($r('app.media.ic_public_arrow_right'))
                  .fillColor($r('sys.color.ohos_id_color_tertiary'))
                  .customizeImage(Constants.IMAGE_WIDTH, Constants.IMAGE_HEIGHT)
              }
            }
            .width(Constants.FULL_WIDTH)
            .height(Constants.AUTHORITY_ROW_HEIGHT)
            .constraintSize({ minHeight: Constants.AUTHORITY_CONSTRAINTSIZE_MINHEIGHT })
          }
        }.onClick(() => {
          if (polymorphismGroup.indexOf(this.currentGroup) !== -1) {
            let permissions: string[] = [];
            this.list.forEach(data => {
              if (data.bundleNames.includes(item.bundleName as string)) {
                permissions.push(data.permission);
              }
            })
            this.allBundleInfo.forEach(bundleInfo => {
              if (bundleInfo.bundleName === item.bundleName) {
                GlobalContext.store('applicationInfo', bundleInfo);
              }
            })
            GlobalContext.store('folderStatus', this.folderStatusArray[item.index]);
            router.pushUrl({
              url: 'pages/application-tertiary',
              params: {
                bundleName: item.bundleName,
                backTitle: this.backTitle,
                permission: permissions,
                status: this.polymorphismIsOn[item.index] ? Constants.RADIO_ALLOW_INDEX : Constants.RADIO_BAN_INDEX,
                tokenId: item.accessTokenId
              }
            });
          }
        })
      }
    }.padding({ left: $r('sys.float.ohos_id_card_margin_start'), right: $r('sys.float.ohos_id_card_margin_end') })
    .enabled(!this.isRisk[item.index])
    .opacity(this.isRisk[item.index] ? $r('sys.float.ohos_id_alpha_disabled') : 1)
    .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
    .linearGradient((this.isTouch === item.bundleName) ? {
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
      if (event.type === TouchType.Down && polymorphismGroup.indexOf(this.currentGroup) !== -1) {
        this.isTouch = item.bundleName ? item.bundleName : '';
      }
      if (event.type === TouchType.Up) {
        this.isTouch = '';
      }
    })
  }

  /**
   * Take the total number of access applications
   */
  getGrantApplicationNumber() {
    if (polymorphismGroup.indexOf(this.currentGroup) !== -1) {
      if (this.currentGroup === 'FOLDER') {
        let sum = this.folderStatusArray.filter(item => item.includes(true));
        return sum.length;
      } else {
        let sum = this.polymorphismIsOn.filter(item => item == true);
        return sum.length;
      }
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
  grantUserGrantedPermission(accessTokenId: number, permission: Permissions, resolve: (value: number) => void) {
    abilityAccessCtrl.createAtManager().grantUserGrantedPermission(accessTokenId, permission, Constants.PERMISSION_FLAG)
    .then(() => {
      resolve(0);
    }).catch((error: BusinessError) => {
      resolve(-1);
      Log.error('grantUserGrantedPermission failed. Cause: ' + JSON.stringify(error));
    })
  }

  /**
   * Deauthorize the app
   * @param {Number} accessTokenId
   * @param {String} permission permission name
   * @param {Number} index Array index to modify permission status
   */
  revokeUserGrantedPermission(accessTokenId: number, permission: Permissions, resolve: (value: number) => void) {
    abilityAccessCtrl.createAtManager().revokeUserGrantedPermission(
      accessTokenId, permission, Constants.PERMISSION_FLAG
    ).then(() => {
      resolve(0);
    }).catch((error: BusinessError) => {
      resolve(-1);
      Log.error('revokeUserGrantedPermission failed. Cause: ' + JSON.stringify(error));
    })
  }

  /**
   * Lifecycle function, executed when the page is initialized
   */
  aboutToAppear() {
    let bundleNames: string[] = [];
    this.applicationList = [];
    this.list.forEach(permissionManager => {
      permissionManager.bundleNames.forEach(bundleName => {
        if (bundleNames.indexOf(bundleName) == -1) {
          bundleNames.push(bundleName);
        }
      })
    })
    groups.forEach(group => {
      if (group.name === this.currentGroup) {
        this.groupInfo = group;
      }
    })

    for (let i = 0; i < bundleNames.length; i++) {
      // Get BundleInfo based on bundle name
      this.allBundleInfo.forEach(bundleInfo => {
        if (bundleInfo.bundleName === bundleNames[i]) {
          this.getApplicationList(bundleInfo, i);
        }
      })
    }

    if (globalGroup.indexOf(this.currentGroup) !== -1) {
      this.globalListen();
    }
  }

  aboutToDisappear() {
    this.privacyDialogController = null;
  }

  getApplicationList(bundleInfo: AppInfo, i: number) {
    this.applicationList.push(
      new ApplicationObj(
        bundleInfo.label,
        bundleInfo.icon,
        i,
        bundleInfo.tokenId,
        this.list[0].permission,
        bundleInfo.zhTag,
        bundleInfo.indexTag,
        bundleInfo.language,
        bundleInfo.bundleName) // Get the first letter in the returned initials array
    );
    this.isRisk[i] = false;
    try {
      abilityAccessCtrl.createAtManager().getPermissionFlags(bundleInfo.tokenId, this.list[0].permission)
        .then(data => {
          if (data == Constants.PERMISSION_POLICY_FIXED) {
            this.isRisk[i] = true;
          }
        })
    } catch (err) {
      Log.error('getPermissionFlags error: ' + JSON.stringify(err));
    }
    // 0: have permission; -1: no permission
    let boole = true;
    this.permissionNum++;
    for (let j = 0; j < this.list.length; j++) {
      if (bundleInfo.permissions.indexOf(this.list[j].permission) == -1) {
        continue;
      }
      verifyAccessToken(bundleInfo.tokenId, this.list[j].permission).then((access) => {
        if (Number(access) === Constants.PERMISSION_INDEX) {
          if (boole) {
            this.toggleIsOn[i] = true;
            this.isFirst[i] = true;
          }
        } else {
          if (boole) {
            this.permissionNum--;
          }
          boole = false;
          this.toggleIsOn[i] = false;
          this.isFirst[i] = false;
        }
      });
    }
  }

  globalListen() {
    this.globalIsOn = globalIsOn;
    if (this.currentGroup == 'CAMERA') {
      let cameraManager = camera.getCameraManager(GlobalContext.load('context'));
      cameraManager.on('cameraMute', (err, curMuted) => {
        Log.info('curMuted: ' + JSON.stringify(curMuted) + ' err: ' + JSON.stringify(err));
        this.globalIsOn = !curMuted;
      })
    } else {
      let audioManager = audio.getAudioManager();
      let audioVolumeManager = audioManager.getVolumeManager();
      let groupId = audio.DEFAULT_VOLUME_GROUP_ID;
      audioVolumeManager.getVolumeGroupManager(groupId).then(audioVolumeGroupManager => {
        audioVolumeGroupManager.on('micStateChange', micStateChange => {
          Log.info('micStateChange: ' + JSON.stringify(micStateChange));
          this.globalIsOn = !micStateChange.mute;
        })
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
          if (globalGroup.indexOf(this.currentGroup) !== -1 && this.isMuteSupported === true) {
            Row() {
              Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
                Text(this.currentGroup == 'CAMERA' ? $r('app.string.camera') : $r('app.string.microphone'))
                  .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE).fontColor($r('sys.color.ohos_id_color_text_primary'))
                  .fontWeight(FontWeight.Medium)
                Row() {
                  Toggle({ type: ToggleType.Switch, isOn: this.globalIsOn })
                    .selectedColor($r('sys.color.ohos_id_color_toolbar_icon_actived'))
                    .switchPointColor($r('sys.color.ohos_id_color_foreground_contrary'))
                    .padding({ right: 0 })
                    .onChange((isOn: boolean) => {
                      if (isOn) {
                        if (this.currentGroup == 'CAMERA') {
                          let cameraManager = camera.getCameraManager(GlobalContext.load('context'));
                          cameraManager.muteCamera(false);
                        } else {
                          let audioManager = audio.getAudioManager();
                          let audioVolumeManager = audioManager.getVolumeManager();
                          let groupId = audio.DEFAULT_VOLUME_GROUP_ID;
                          audioVolumeManager.getVolumeGroupManager(groupId).then(audioVolumeGroupManager => {
                            audioVolumeGroupManager.setMicMute(false)
                          })
                        }
                      }
                    })
                  Row().onClick(() => {
                    if (this.privacyDialogController !== null) {
                      this.privacyDialogController.open()
                    }
                  })
                    .width(Constants.DEFAULT_SLIDER_WIDTH).height(Constants.DEFAULT_SLIDER_HEIGHT)
                    .position({ x: this.globalIsOn ? 0 : Constants.OFFSET, y: 0 })
                }.clip(true)
              }.height(Constants.LISTITEM_ROW_HEIGHT)
              .padding({ left: Constants.DEFAULT_PADDING_START, right: Constants.DEFAULT_PADDING_END })
            }.padding({ top: Constants.LIST_PADDING_TOP, bottom: Constants.LIST_PADDING_BOTTOM })
            .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
            .margin({ top: Constants.TERTIARY_ROW_MARGIN_TOP })
          }
          Flex({ justifyContent: FlexAlign.Start }) {
            if (this.globalIsOn) {
              if (this.getGrantApplicationNumber() > 0) {
                Text(
                  this.groupInfo.enableDescription ?
                  $r(this.groupInfo.enableDescription, String(this.getGrantApplicationNumber())) :
                  ''
                )
                  .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
                  .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                  .margin({ top: Constants.AUTHORITY_TEXT_MARGIN_TOP })
              } else {
                Text(this.groupInfo.forbiddenDescription)
                  .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
                  .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                  .margin({ top: Constants.AUTHORITY_TEXT_MARGIN_TOP })
              }
            } else {
              Text(
                this.currentGroup == 'CAMERA' ?
                $r('app.string.camera_is_off') :
                $r('app.string.microphone_is_off')
              )
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
                  .padding(Constants.LIST_PADDING_TOP)
                  .divider({
                    strokeWidth: Constants.DIVIDER,
                    color: $r('sys.color.ohos_id_color_list_separator'),
                    startMargin: Constants.DIVIDER_MARGIN_RIGHT_APPLICATION,
                    endMargin: Constants.DEFAULT_MARGIN_END
                  })
                  .onScrollIndex((start, end) => {
                    GlobalContext.getContext().set('scroller', this.scroller);
                    if (this.applicationList.length > 0) {
                      let alphabeticalIndex: string = sortByName(this.applicationList)[start].indexTag;
                      let index = indexValue.indexOf(alphabeticalIndex);
                      this.selectedIndex = index >= 0 ? index : 0;
                    }
                  })
                }
              }
            }.width(Constants.FULL_WIDTH)
            .margin({
              bottom: globalGroup.includes(this.currentGroup) && this.isMuteSupported === true ?
                Constants.AUTHORITY_LIST_MARGIN_BOTTOM_GLOBAL :
                Constants.AUTHORITY_LIST_MARGIN_BOTTOM
            })
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

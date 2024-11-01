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
import { CustomContentDialog } from '@ohos.arkui.advanced.Dialog';
import { Log, verifyAccessToken, indexValue, sortByName } from '../common/utils/utils';
import { ApplicationObj, GroupInfo, RouterParams1, PermissionApplications, AppInfo } from '../common/model/typedef';
import { GlobalContext } from '../common/utils/globalContext';
import { Permission, PermissionGroup } from '../common/model/definition';
import Constants from '../common/utils/constant';
import { polymorphismGroup, globalGroup, groups } from '../common/model/permissionGroup';

const locationStatus: Resource[] = [
  $r('app.string.always_allow'),
  $r('app.string.ban'),
  $r('app.string.per_inquiry'),
  $r('app.string.allowed_only_during_use')
];
let globalIsOn: boolean = (router.getParams() as RouterParams1).globalIsOn; // return title name

@Entry
@Component
struct locationInfoPage {
  private backTitle: ResourceStr = (router.getParams() as RouterParams1).backTitle;
  private list: PermissionApplications[] = (router.getParams() as RouterParams1).list;
  @State currentGroup: string = GlobalContext.load('currentPermissionGroup');
  @State polymorphismIsOn: Array<number> = [];
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
        .backgroundColor($r('sys.color.background_secondary'))
      }
    }.backgroundColor($r('sys.color.background_secondary'))
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
    this.polymorphismIsOn[index] = Constants.PERMISSION_BAN;
    this.folderStatusArray[index] = [false, false, false];
    let reqPermissions: string[] = [];
    res.reqPermissionDetails.forEach(item => {
      reqPermissions.push(item.name);
    })
    let acManager = abilityAccessCtrl.createAtManager();
    if (this.currentGroup === 'LOCATION' && reqPermissions.includes(Permission.APPROXIMATELY_LOCATION)) {
      try {
        let fuzzyState = acManager.verifyAccessTokenSync(res.appInfo.accessTokenId, Permission.APPROXIMATELY_LOCATION);
        fuzzyState === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED ?
          this.polymorphismIsOn[index] = Constants.PERMISSION_ALLOWED_ONLY_DURING_USE : null;
        let backgroundState =
          acManager.verifyAccessTokenSync(res.appInfo.accessTokenId, Permission.LOCATION_IN_BACKGROUND);
        backgroundState === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED ?
          this.polymorphismIsOn[index] = Constants.PERMISSION_ALLOW : null;
        acManager.getPermissionFlags(res.appInfo.accessTokenId, Permission.APPROXIMATELY_LOCATION ).then(flag => {
          flag === Constants.PERMISSION_ALLOW_THIS_TIME ?
            this.polymorphismIsOn[index] = Constants.PERMISSION_ONLY_THIS_TIME : null;
        })
      } catch (err) {
        Log.error('change location status error: ' + JSON.stringify(err));
      }
    }
    if (this.currentGroup === 'FOLDER') {
      for (let j = 0; j < this.list.length; j++) {
        if (reqPermissions.indexOf(this.list[j].permission) == -1) {
          continue;
        }
        let access = acManager.verifyAccessTokenSync(res.appInfo.accessTokenId, this.list[j].permission);
        if (Number(access) === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
          this.updateFolderStatus(index, j);
        }
      }
    }
  }

  updateFolderStatus(index: number, idx: number) {
    switch (this.list[idx].permission) {
      case Permission.READ_WRITE_DOWNLOAD_DIRECTORY:
        this.folderStatusArray[index][0] = true;
        break;
      case Permission.READ_WRITE_DESKTOP_DIRECTORY:
        this.folderStatusArray[index][1] = true;
        break;
      case Permission.READ_WRITE_DOCUMENTS_DIRECTORY:
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
  @Link polymorphismIsOn: Array<number>;
  @Link folderStatusArray: Array<Array<boolean>>;
  @State globalIsOn: boolean = true;
  @State selectedIndex: number = 0;
  @State isTouch: string = '';
  @State groupInfo: GroupInfo = new GroupInfo('', '', '', '', [], '', [], [], false);
  @State currentGroup: string = GlobalContext.load('currentPermissionGroup');
  @State isMuteSupported: boolean = GlobalContext.load('isMuteSupported');
  @State allBundleInfo: AppInfo[] = GlobalContext.load('allBundleInfo');
  scroller: Scroller = new Scroller();

  dialogController: CustomDialogController | null = new CustomDialogController({
    builder: CustomContentDialog({
      contentBuilder: () => {
        this.buildContent();
      },
      contentAreaPadding: { left: Constants.PADDING_24, right: Constants.PADDING_24 },
      buttons: [
        {
          value: $r('app.string.cancel'),
          buttonStyle: ButtonStyleMode.TEXTUAL,
          action: () => {
            Log.info('global cancel');
            this.dialogController?.close();
          }
        },
        {
          value: $r('app.string.close'),
          buttonStyle: ButtonStyleMode.TEXTUAL,
          action: () => {
            Log.info('global accept');
            if (this.currentGroup == PermissionGroup.MICROPHONE) {
              let audioManager = audio.getAudioManager();
              let audioVolumeManager = audioManager.getVolumeManager();
              audioVolumeManager.getVolumeGroupManager(audio.DEFAULT_VOLUME_GROUP_ID).then(audioVolumeGroupManager => {
                audioVolumeGroupManager.setMicMutePersistent(true, audio.PolicyType.PRIVACY).then(() => {
                  this.dialogController?.close();
                })
              })
            } else {
              let cameraManager = camera.getCameraManager(GlobalContext.load('context'));
              cameraManager.muteCameraPersistent(true, camera.PolicyType.PRIVACY);
              this.dialogController?.close();
            }
          }
        }
      ],
    }),
    autoCancel: false
  });

  @Builder
  buildContent(): void {
    Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
      Column() {
        Text(this.currentGroup == 'CAMERA' ? $r('app.string.close_camera') : $r('app.string.close_microphone'))
          .fontSize(Constants.TEXT_BIG_FONT_SIZE)
          .fontColor($r('sys.color.font_primary'))
          .fontWeight(FontWeight.Medium)
          .lineHeight(Constants.TEXT_BIG_LINE_HEIGHT)
          .width(Constants.FULL_WIDTH)
          .padding({ top: Constants.PADDING_14, bottom: Constants.PADDING_14 })
        Text(
          this.currentGroup == 'CAMERA' ?
          $r('app.string.close_camera_desc') :
          $r('app.string.close_microphone_desc')
        )
          .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
          .fontColor($r('sys.color.font_primary'))
          .lineHeight(Constants.TEXT_LINE_HEIGHT)
      }
      .clip(true)
    }
  }

  @Builder ListItemLayout(item: ApplicationObj) {
    ListItem() {
      Row() {
        Column() {
          Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
            Row() {
              Image(item.icon)
                .objectFit(ImageFit.Contain)
                .width(Constants.AUTHORITY_IMAGE_WIDTH)
                .height(Constants.AUTHORITY_IMAGE_HEIGHT)
                .draggable(false)
                .margin({ right: Constants.AUTHORITY_IMAGE_MARGIN_RIGHT })
              Column() {
                Text(item.label)
                  .width(Constants.MAXIMUM_HEADER_WIDTH)
                  .maxLines(Constants.MAXIMUM_HEADER_LINES)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('sys.color.font_primary'))
                if (this.isRisk[item.index]) {
                  Text($r('app.string.risk_warning'))
                    .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
                    .fontColor($r('sys.color.font_secondary'))
                }
              }.flexGrow(Constants.FLEX_GROW)
              .alignItems(HorizontalAlign.Start)
              if (polymorphismGroup.indexOf(this.currentGroup) == -1) {
                Toggle({ type: ToggleType.Switch, isOn: this.toggleIsOn[item.index] })
                  .selectedColor($r('sys.color.icon_emphasize'))
                  .switchPointColor($r('sys.color.comp_background_primary_contrary'))
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
                    .fontColor($r('sys.color.font_secondary'))
                    .margin({ right: Constants.AUTHORITY_IMAGE_MARGIN_RIGHT })
                } else {
                  Text(locationStatus[this.polymorphismIsOn[item.index]])
                    .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
                    .fontColor($r('sys.color.font_secondary'))
                    .margin({ right: Constants.AUTHORITY_IMAGE_MARGIN_RIGHT })
                }
                SymbolGlyph($r('sys.symbol.chevron_forward'))
                  .width(Constants.IMAGE_WIDTH)
                  .height(Constants.IMAGE_HEIGHT)
                  .fontSize(Constants.FONT_SIZE_18_vp)
                  .fontColor([$r('sys.color.icon_tertiary')])
                  .fontWeight(FontWeight.Medium)
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
            GlobalContext.store('locationStatus', this.polymorphismIsOn[item.index]);
            router.pushUrl({
              url: 'pages/application-tertiary',
              params: {
                bundleName: item.bundleName,
                backTitle: this.backTitle,
                permission: permissions,
                status: Constants.PERMISSION_BAN,
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
        colors: [[$r('sys.color.comp_background_list_card'), 1], [$r('sys.color.comp_background_list_card'), 1]]
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
        let sum = this.polymorphismIsOn.filter(
          item => item !== Constants.PERMISSION_BAN && item !== Constants.PERMISSION_ONLY_THIS_TIME
        );
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
    this.dialogController = null;
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
          let muteState = audioVolumeGroupManager.isPersistentMicMute();
          Log.info('micStateChange: ' + JSON.stringify(muteState));
          this.globalIsOn = !muteState;
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
                  .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE).fontColor($r('sys.color.font_primary'))
                  .fontWeight(FontWeight.Medium)
                Row() {
                  Toggle({ type: ToggleType.Switch, isOn: this.globalIsOn })
                    .selectedColor($r('sys.color.icon_emphasize'))
                    .switchPointColor($r('sys.color.comp_background_primary_contrary'))
                    .padding({ right: 0 })
                    .onChange((isOn: boolean) => {
                      if (isOn) {
                        if (this.currentGroup == 'CAMERA') {
                          let cameraManager = camera.getCameraManager(GlobalContext.load('context'));
                          cameraManager.muteCameraPersistent(false, camera.PolicyType.PRIVACY);
                        } else {
                          let audioManager = audio.getAudioManager();
                          let audioVolumeManager = audioManager.getVolumeManager();
                          let groupId = audio.DEFAULT_VOLUME_GROUP_ID;
                          audioVolumeManager.getVolumeGroupManager(groupId).then(audioVolumeGroupManager => {
                            audioVolumeGroupManager.setMicMutePersistent(false, audio.PolicyType.PRIVACY);
                          })
                        }
                      }
                    })
                  Row().onClick(() => {
                    this.dialogController?.open();
                  })
                    .width(Constants.DEFAULT_SLIDER_WIDTH).height(Constants.DEFAULT_SLIDER_HEIGHT)
                    .position({ x: this.globalIsOn ? 0 : Constants.OFFSET, y: 0 })
                }.clip(true)
              }.height(Constants.LISTITEM_ROW_HEIGHT)
              .padding({ left: Constants.DEFAULT_PADDING_START, right: Constants.DEFAULT_PADDING_END })
            }.padding({ top: Constants.LIST_PADDING_TOP, bottom: Constants.LIST_PADDING_BOTTOM })
            .backgroundColor($r('sys.color.comp_background_list_card'))
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
                  .fontColor($r('sys.color.font_secondary'))
                  .margin({ top: Constants.AUTHORITY_TEXT_MARGIN_TOP })
              } else {
                Text(this.groupInfo.forbiddenDescription)
                  .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
                  .fontColor($r('sys.color.font_secondary'))
                  .margin({ top: Constants.AUTHORITY_TEXT_MARGIN_TOP })
              }
            } else {
              Text(
                this.currentGroup == 'CAMERA' ?
                $r('app.string.camera_is_off') :
                $r('app.string.microphone_is_off')
              )
                .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
                .fontColor($r('sys.color.font_secondary'))
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
                        .objectFit(ImageFit.Contain)
                        .width(Constants.SEARCHNORESULT_IMAGE_WIDTH)
                        .height(Constants.SEARCHNORESULT_IMAGE_HEIGHT)
                        .draggable(false)
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
                  .backgroundColor($r('sys.color.comp_background_list_card'))
                  .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
                  .padding(Constants.LIST_PADDING_TOP)
                  .divider({
                    strokeWidth: Constants.DIVIDER,
                    color: $r('sys.color.comp_divider'),
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

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
import bundle from "@ohos.bundle.bundleManager";
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import audio from '@ohos.multimedia.audio'
import camera from '@ohos.multimedia.camera'
import { groups, userGrantPermissions, permissionGroupPermissions, globalGroup } from "../common/model/permissionGroup";
import { permissionGroups, permissionGroupIds, showSubpermissionsGrop } from "../common/model/permissionGroup";
import { makePy, appSort, getSortId, indexValue } from "../common/utils/utils";
import Constants from '../common/utils/constant';

var TAG = 'PermissionManager_MainAbility:';

@Extend(Image) function customizeImage(width: number, height: number) {
  .objectFit(ImageFit.Contain)
  .width(width)
  .height(height)
};

interface applicationPermissions {
  'bundleName': string,
  'api': number,
  'icon': string,
  'iconId': string,
  'permissions': string[],
  'label': string,
  'labelId': string,
  'tokenId': number,
  'groupId': number[]
};

interface permissionApplications {
  'permission': string,
  'groupName': string,
  'bundleNames': string[],
  'icon': string
};

interface groupPermission {
  'group': string,
  'permissions': string[],
  'groupName': string,
  'icon': string,
  'isShow':boolean
};

const FUZZY_LOCATION_PERMISSION = 'ohos.permission.APPROXIMATELY_LOCATION';
const PRECISE_LOCATION_PERMISSION = 'ohos.permission.LOCATION';

@Entry
@Component
struct authorityManagementPage {
  @Builder ListItemLayout(item, end) {
    ListItem() {
      Row() {
        Column() {
          Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
            Row() {
              Image(item.icon)
                .fillColor($r('sys.color.ohos_id_color_secondary'))
                .customizeImage(Constants.MANAGEMENT_IMAGE_WIDTH, Constants.MANAGEMENT_IMAGE_HEIGHT)
                .margin({ right: Constants.MANAGEMENT_IMAGE_MARGIN_RIGHT })
              Text(item.groupName)
                .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
                .flexGrow(Constants.FLEX_GROW)
              Image($r('app.media.ic_public_arrow_right'))
                .fillColor($r('sys.color.ohos_id_color_tertiary'))
                .customizeImage(Constants.IMAGE_WIDTH, Constants.IMAGE_HEIGHT)
            }
            .width(Constants.FULL_WIDTH)
            .height(Constants.MANAGEMENT_ROW_HEIGHT)
          }
          if (!end) {
            Row() {
              Flex() {
                Column().width(Constants.MANAGEMENT_TEXT_DECORATION_MARGIN_LEFT)
                Column()
                  .backgroundColor($r('sys.color.ohos_id_color_list_separator'))
                  .height(Constants.TEXT_DECORATION_HEIGHT)
                  .flexGrow(Constants.FLEX_GROW)
              }
            }
          }
        }.onClick(() => {
          if (item.group === 'OTHER' || showSubpermissionsGrop.indexOf(item.group) !== -1) {
            router.pushUrl({
              url: 'pages/authority-secondary',
              params: { routerData: this.allPermissionApplications, backTitle: item.groupName, group: item.group }
            })
          } else {
            var dataList = this.allPermissionApplications.filter((ele) => {
              return ele.groupName === item.group;
            })

            globalThis.currentPermissionGroup = item.group;
            if (globalGroup.indexOf(item.group) == -1) {
              router.pushUrl({
                url: 'pages/authority-tertiary-groups',
                params: { routerData: dataList, backTitle: item.groupName  }
              })
            } else {
              if (item.group == 'MICROPHONE') {
                var audioManager = audio.getAudioManager();
                let audioVolumeManager = audioManager.getVolumeManager();
                let groupid = audio.DEFAULT_VOLUME_GROUP_ID;
                audioVolumeManager.getVolumeGroupManager(groupid).then(audioVolumeGroupManager => {
                  audioVolumeGroupManager.isMicrophoneMute().then(value => {
                    globalThis.ismutesuppotred = true;
                    router.pushUrl({
                      url: 'pages/authority-tertiary-groups',
                      params: { routerData: dataList, backTitle: item.groupName, globalIsOn: !value }
                    })
                  })
                })
              } else {
                let cameraManager = camera.getCameraManager(globalThis.context);
                let mute = cameraManager.isCameraMuted();
                globalThis.ismutesuppotred = cameraManager.isCameraMuteSupported();
                router.pushUrl({
                  url: 'pages/authority-tertiary-groups',
                  params: { routerData: dataList, backTitle: item.groupName, globalIsOn: !mute }
                })
              }
            }
          }
        })
      }
    }.padding({ left: Constants.DEFAULT_PADDING_START, right: Constants.DEFAULT_PADDING_END })
  }

  @State allPermissionApplications: permissionApplications [] = []; // All app permissions
  @State allGroupPermission: groupPermission[] = []; // All group permissions
  @State currentIndex: number = 0;
  @State @Watch("getLabelAndIcon") ready: boolean = false;
  @Builder TabBuilder(index: number) {
    Flex({ alignItems: index ? ItemAlign.Start : ItemAlign.End, justifyContent: FlexAlign.Center, direction: FlexDirection.Column }) {
      Text(index ? $r('app.string.application') : $r('app.string.permission'))
        .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
        .fontColor(this.currentIndex == index ? $r('sys.color.ohos_id_color_subtab_text_on') : $r('sys.color.ohos_id_color_secondary'))
        .fontWeight(this.currentIndex == index ? FontWeight.Bold : FontWeight.Regular)
        .lineHeight(Constants.TEXT_LINE_HEIGHT)
        .baselineOffset(Constants.TAB_DECORATION_POSITION_Y)
      if (this.currentIndex == index) {
        Text(index ? $r('app.string.application') : $r('app.string.permission'))
          .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
          .fontWeight(FontWeight.Bold)
          .height(Constants.TAB_DECORATION_HEIGHT)
          .fontColor($r('sys.color.ohos_id_color_subtab_text_on'))
          .backgroundColor($r('sys.color.ohos_id_color_subtab_text_on'))
      }
    }.height(Constants.TAB_HEIGHT)
    .width(Constants.FULL_WIDTH)
    .padding({ left: Constants.DEFAULT_PADDING_START, right: Constants.DEFAULT_PADDING_END })
  }

  /**
   * Convert the permission array into key, value key-value objects for easy sorting
   * @param {Array} order User rights
   * @return {Object} return the processed object
   */
  orderDict(order) {
    let result = {};
    for (let i = 0; i < order.length; i++) {
      let key = order[i];
      result[key] = i;
    }
    return result;
  }

  /**
   * Compare and sort the permission array according to the permission key value
   * @param {String} prop Sort by permission
   * @param {Object} orderSort objects to be sorted
   * @return {Array} Returns a sorted array of permissions
   */
  compare(prop, orderSort) {
    return function(a, b) {
      let aSortValue = orderSort[a[prop]];
      let bSortValue = orderSort[b[prop]];
      if (aSortValue == undefined) {
        throw new Error('当前的字段不在排序列表里：' + a[prop]);
      }
      if (bSortValue == undefined) {
        throw new Error('当前的字段不在排序列表里：' + b[prop]);
      }
      return aSortValue - bSortValue;
    }
  }

  /**
   * Get all app permission information
   */
  async getAllBundlePermissions() {
      for (let i = 0; i < globalThis.initialGroups.length; i++) {
        await this.deduplicationPermissions(globalThis.initialGroups[i]);
      }
      this.getAllGroupPermission();
      this.getAllPermissionApplications();
      let orderSort = this.orderDict(userGrantPermissions);
      this.allPermissionApplications.sort(this.compare('permission', orderSort));
      this.getPermissionLabel();
  }

  /**
   * Get the corresponding permission group id according to the permission
   * @param {String} permission app name id
   * @return {Number} groupId
   */
  getPermissionGroupByPermission(permission: string) {
    for (let i = 0; i < permissionGroups.length; i++) {
      if (permissionGroups[i].permissionName == permission) {
        return groups[permissionGroups[i].groupId];
      }
    }
  }

  /**
   * Get all permission label
   */
  getPermissionLabel() {
    globalThis.allUserPermissions.forEach(userPermission => {
      permissionGroups.forEach(permissionInfo => {
        if(userPermission == permissionInfo.permissionName) {
          globalThis.context.resourceManager.getString(permissionInfo.label.id).then(val => {
            globalThis.permissionLabels[userPermission] = val;
          })
        }
      })
    })
  }

  /**
   * Get all permission label
   */
  getLabelAndIcon() {
    const this_ = this;
    setTimeout(function() {
      globalThis.allBundleInfo.forEach(bundleInfo => {
        this_.updateAppLabel(bundleInfo);
        this_.updateAppIcon(bundleInfo);
      })
    }, 100)
  }

  /**
   * Get all app permission information
   */
  getAllPermissionApplications() {
    const this_ = this;
    for (let i = 0; i < globalThis.allUserPermissions.length; i++) {
      var permissionGroup = this_.getPermissionGroupByPermission(globalThis.allUserPermissions[i]);
      var icon: string = permissionGroup.icon;
      var bundleNames: string[] = [];
      for (let j = 0; j < globalThis.allBundleInfo.length; j++) {
        if (globalThis.allBundleInfo[j].permissions.indexOf(globalThis.allUserPermissions[i]) != -1) {
          bundleNames.push(globalThis.allBundleInfo[j].bundleName);
        }
      }
      var pa: permissionApplications = {
        'permission': globalThis.allUserPermissions[i],
        'groupName': permissionGroup.name,
        'bundleNames': bundleNames,
        'icon': icon
      };
      this_.allPermissionApplications.push(pa);
    }
  }

  /**
   * Get permission group information
   */
  getAllGroupPermission() {
    const this_ = this;
    groups.forEach((item) => {
      if (item.isShow) {
        globalThis.allGroups.push(item.name);
      }
    })
    globalThis.allUserPermissions.forEach(userPermission => {
      if (globalThis.allGroups.indexOf(groups[permissionGroupIds[userPermission]].name) == -1) {
        globalThis.allGroups.push(groups[permissionGroupIds[userPermission]].name);
      }
    })
    // Permission layout
    for (let i = 0; i < globalThis.allGroups.length; i++) {
      var permissions: string[] = permissionGroupPermissions[globalThis.allGroups[i]];
      var gp: groupPermission = {
        "group": globalThis.allGroups[i],
        "permissions": permissions,
        'groupName': '',
        'icon': '',
        'isShow': false
      };
      this_.allGroupPermission.push(gp);
    }
    this.allGroupPermission.forEach((ele) => {
      groups.forEach((item) => {
        if (ele.group === item.name) {
          ele.groupName = item.groupName;
          ele.icon = item.icon;
          ele.isShow = item.isShow;
        }
      });
    })
  }

  /**
   * Deduplicate permission information and permission group information
   * @param {Object} info bundleInfos Application Information
   */
  async deduplicationPermissions(info) {
    console.log(TAG + 'allBundleInfo start: ' + info.name)
    let reqPermissions: Array<any> = [];
    info.reqPermissionDetails.forEach(item => {
      reqPermissions.push(item.name);
    })
    var reqPermissionsLen = reqPermissions.length;
    var reqUserPermissions: string[] = [];
    var acManager = abilityAccessCtrl.createAtManager()
    if (reqPermissionsLen > 0) {
      for (let j = 0; j < reqPermissions.length; j++) {
        var permission = reqPermissions[j];
        console.log(TAG + 'getPermissionFlags: ' + permission + 'app: ' + info.name)
        if ((info.targetVersion < Constants.API_VERSION_SUPPORT_STAGE) && (permission == FUZZY_LOCATION_PERMISSION)) {
          continue;
        }
        if ((info.targetVersion >= Constants.API_VERSION_SUPPORT_STAGE) && (permission == PRECISE_LOCATION_PERMISSION) && !reqPermissions.includes(FUZZY_LOCATION_PERMISSION)) {
          continue;
        }
        try {
          var flag = await acManager.getPermissionFlags(info.appInfo.accessTokenId, permission);
          console.log(TAG + 'getPermissionFlags: ' + permission + 'app: ' + info.name + 'flag: ' + flag);
          if (flag == Constants.PERMISSION_SYSTEM_FIXED) {
            continue;
          }
        }
        catch(err) {
          console.log(TAG + 'getPermissionFlags error: ' + JSON.stringify(err));
        }
        if (userGrantPermissions.indexOf(permission) != -1) {
          reqUserPermissions.push(permission);
          if (globalThis.allUserPermissions.indexOf(permission) == -1) {
            globalThis.allUserPermissions.push(permission);
          }
        }
      }
    }
    let groupIds = [];
    for (let i = 0; i < reqUserPermissions.length; i++) {
      if (groupIds.indexOf(permissionGroupIds[reqUserPermissions[i]]) == -1) {
        groupIds.push(permissionGroupIds[reqUserPermissions[i]]);
      }
    }

    var ap: applicationPermissions = {
      'bundleName': info.name,
      'api': info.targetVersion,
      'tokenId': info.appInfo.accessTokenId,
      'icon': '',
      'iconId': info.appInfo.iconResource,
      'label': '',
      'labelId': info.appInfo.labelResource,
      'permissions': reqUserPermissions,
      'groupId': groupIds
    };
    console.log(TAG + 'allBundleInfo.push: ' + info.name);
    globalThis.allBundleInfo.push(ap);
  }

  /**
   * Get app name resource
   * @param {Number} index index of all app permissions array
   * @param {String} bundleName Package names
   * @param {String} labelName Application Name
   */
  updateAppLabel(info) {
    globalThis.context.resourceManager.getStringValue(info.labelId, (error, value) => {
        info.label = value;
        if (!isNaN(info.label)) {
          info.alphabeticalIndex = '';
        } else {
          info.alphabeticalIndex = makePy(info.label)[0].slice(0, 1); // Get the first letter in the returned initials array
        }

        info.sortId = getSortId(value)
    })
  }

  /**
   * Get app icon resources
   * @param {Number} index index of all app permissions array
   * @param {String} bundleName Package names
   */
  updateAppIcon(info) {
    try {
      let iconDescriptor = globalThis.context.resourceManager.getDrawableDescriptor(info.iconId);
      info.icon = iconDescriptor?.getPixelMap()
    } catch (error) {
      console.error(`getDrawableDescriptor failed, error code: ${error.code}, message: ${error.message}.`)
    }

    if (info.icon == '') {
      globalThis.context.resourceManager.getMediaContentBase64(info.iconId, (error, value) => {
        info.icon = value;
      })
    }
  }

  /**
   * Lifecycle function, executed when the page is initialized
   */
  aboutToAppear() {
    console.log(TAG + 'on aboutToAppear, version 1.01');
    this.getAllBundlePermissions();
    var acManager = abilityAccessCtrl.createAtManager();
    bundle.getApplicationInfo(Constants.BUNDLE_NAME, bundle.ApplicationFlag.GET_APPLICATION_INFO_DEFAULT).then(data => {
      acManager.grantUserGrantedPermission(data.accessTokenId, "ohos.permission.MICROPHONE", 2);
    })
  }

  getPermissionGroup(allGroup, order) {
    var fixedName: string[] = ['LOCATION', 'CAMERA', 'MICROPHONE'];
    var extraName: string[] = ['ADS'];
    var fixedGroup: any[] = [];
    var extraGroup: any[] = [];
    var changeGroup: any[] = [];
    var otherGroup: any[] = [];

    allGroup.forEach(group => {
      if (fixedName.indexOf(group.group) !== -1) {
        fixedGroup.push(group);
      } else if (extraName.includes(group.group)) {
        extraGroup.push(group);
      } else if (group.group == 'OTHER') {
        otherGroup.push(group);
      } else {
        changeGroup.push(group);
      }
    })

    if (order == Constants.FIXED_GROUP){
      return fixedGroup;
    } else if (order == Constants.CHANGE_GROUP) {
      return changeGroup;
    } else if (order == Constants.OTHER_GROUP) {
      return otherGroup;
    } else if (order == Constants.EXTRA_GROUP) {
      return extraGroup;
    }
  }

  LoadLabelAndIcon() {
    const this_ = this;
    setTimeout(function() { this_.ready = true }, 100)
    return true;
  }

  build() {
    GridRow({ gutter: Constants.GUTTER, columns: {
      xs: Constants.XS_COLUMNS, sm: Constants.SM_COLUMNS, md: Constants.MD_COLUMNS, lg: Constants.LG_COLUMNS } }) {
      GridCol({ span: { xs: Constants.XS_SPAN, sm: Constants.SM_SPAN, md: Constants.MD_SPAN, lg: Constants.LG_SPAN },
        offset: { xs: Constants.XS_OFFSET, sm: Constants.SM_OFFSET, md: Constants.MD_OFFSET, lg: Constants.LG_OFFSET } }) {
        Row() {
          Column() {
            Row() {
              backBar( { title: JSON.stringify($r('app.string.permission_manager')), recordable: true })
            }
            Row() {
              Column() {
                Column() {
                  Stack() {
                    if(this.allGroupPermission.length) {
                      Tabs() {
                        TabContent() {
                          Row() {
                            Column() {
                              Scroll() {
                                Column() {
                                  List() {
                                    ListItem() {
                                      List() {
                                        ForEach(this.getPermissionGroup(this.allGroupPermission, Constants.FIXED_GROUP), (item, index) => {
                                          this.ListItemLayout(item, index == (this.getPermissionGroup(this.allGroupPermission, Constants.FIXED_GROUP).length - 1))
                                        }, item => JSON.stringify(item))
                                      }.backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
                                      .borderRadius(Constants.BORDER_RADIUS)
                                      .padding({ top: Constants.LIST_PADDING_TOP, bottom: Constants.LIST_PADDING_BOTTOM })
                                      .margin({ bottom: Constants.LIST_MARGIN_BOTTOM })
                                    }

                                    ListItem() {
                                      List() {
                                        ForEach(this.getPermissionGroup(this.allGroupPermission, Constants.CHANGE_GROUP), (item, index) => {
                                          this.ListItemLayout(item, index == (this.getPermissionGroup(this.allGroupPermission, Constants.CHANGE_GROUP).length - 1))
                                        }, item => JSON.stringify(item))
                                      }.backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
                                      .borderRadius(Constants.BORDER_RADIUS)
                                      .padding({ top: Constants.LIST_PADDING_TOP, bottom: Constants.LIST_PADDING_BOTTOM })
                                      .margin({ bottom: Constants.LIST_MARGIN_BOTTOM })
                                    }

                                    if(this.getPermissionGroup(this.allGroupPermission, Constants.EXTRA_GROUP).length) {
                                      ListItem() {
                                        List() {
                                          ForEach(this.getPermissionGroup(this.allGroupPermission, Constants.EXTRA_GROUP), (item, index) => {
                                            this.ListItemLayout(item, index == (this.getPermissionGroup(this.allGroupPermission, Constants.EXTRA_GROUP).length - 1))
                                          }, item => JSON.stringify(item))
                                        }.backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
                                        .borderRadius(Constants.BORDER_RADIUS)
                                        .padding({ top: Constants.LIST_PADDING_TOP, bottom: Constants.LIST_PADDING_BOTTOM })
                                        .margin({ bottom: Constants.LIST_MARGIN_BOTTOM })
                                      }
                                    }

                                    ListItem() {
                                      if(this.LoadLabelAndIcon()) {}
                                      List() {
                                        ForEach(this.getPermissionGroup(this.allGroupPermission, Constants.OTHER_GROUP), (item) => {
                                          this.ListItemLayout(item, Constants.SLICE_END_INDEX)
                                        }, item => JSON.stringify(item))
                                      }.backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
                                      .borderRadius(Constants.BORDER_RADIUS)
                                      .padding({ top: Constants.LIST_PADDING_TOP, bottom: Constants.LIST_PADDING_BOTTOM })
                                    }
                                  }.height(Constants.FULL_HEIGHT)
                                  .borderRadius(Constants.BORDER_RADIUS)
                                  .clip(true)
                                }.padding({
                                  left: Constants.MANAGEMENT_ROW_PADDING_LEFT,
                                  right: Constants.MANAGEMENT_ROW_PADDING_RIGHT,
                                })
                              }.scrollBar(BarState.Off)
                              .margin({ top: Constants.MANAGEMENT_ROW_PADDING_TOP })
                            }.width(Constants.FULL_WIDTH)
                          }
                        }.tabBar(this.TabBuilder(0))
                        TabContent() {
                          applicationItem()
                        }.tabBar(this.TabBuilder(1))
                      }
                      .barMode(BarMode.Fixed)
                      .onChange((index) => {
                        this.currentIndex = index
                      })
                    } else {
                      LoadingProgress().width(Constants.LOADING_WIDTH)
                    }
                  }.height(Constants.FULL_HEIGHT)
                }
              }
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
  @State applicationItem: any[] = globalThis.allBundleInfo; // application info array
  @State searchResult: boolean = true; // search results
  @State selectedIndex: number = 0;
  scroller: Scroller = new Scroller();

  @Builder ListItemLayout(item, index) {
    ListItem() {
      Row() {
        Column() {
          Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
            Row() {
              Image(item.icon)
                .customizeImage(Constants.APPLICATION_IMAGE_WIDTH, Constants.APPLICATION_IMAGE_HEIGHT)
                .margin({ right: Constants.APPLICATION_IMAGE_MARGIN_RIGHT })
              Text(item.label)
                .width(Constants.OFFSET)
                .maxLines(Constants.MAXIMUM_HEADER_LINES)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
                .flexGrow(Constants.FLEX_GROW)
              Text(String(item.groupId.length))
                .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              Text($r('app.string.right'))
                .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                .margin({ right: Constants.APPLICATION_TEXT_MARGIN_RIGHT })
              Image($r('app.media.ic_public_arrow_right'))
                .fillColor($r('sys.color.ohos_id_color_tertiary'))
                .customizeImage(Constants.IMAGE_WIDTH, Constants.IMAGE_HEIGHT)
            }
            .width(Constants.FULL_WIDTH)
            .height(Constants.AUTHORITY_ROW_HEIGHT)
            .constraintSize({ minHeight: Constants.AUTHORITY_CONSTRAINTSIZE_MINHEIGHT })
          }
          if (index < this.applicationItem.length - 1) {
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
          globalThis.applicationInfo = item
          router.pushUrl({ url: 'pages/application-secondary' });
        })
      }
    }.padding({
      left: Constants.DEFAULT_PADDING_START,
      right: Constants.DEFAULT_PADDING_END
    })
  }

  build() {
    Column() {
      Row() {
        textInput({
          applicationItem: $applicationItem,
          searchResult: $searchResult
        })
      }.padding({
        left: Constants.APPLICATION_TEXTINPUT_PADDING_LEFT,
        top: Constants.APPLICATION_TEXTINPUT_PADDING_TOP,
        right: Constants.APPLICATION_TEXTINPUT_PADDING_RIGHT
      })
      Row() {
        Flex({ alignItems: ItemAlign.Start }) {
          Column() {
            Column() {
              if (!this.applicationItem.length) {
                Row() {
                  Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
                    Image($r('app.media.searchnoresult'))
                      .customizeImage(Constants.SEARCHNORESULT_IMAGE_WIDTH, Constants.SEARCHNORESULT_IMAGE_HEIGHT)
                  }
                }.margin({ top: Constants.MANAGEMENT_ROW_MARGIN_TOP })
                .padding({ left: Constants.MANAGEMENT_ROW_PADDING_LEFT })
              } else {
                Row() {
                  List({ scroller: this.scroller }) {
                    ForEach(appSort(this.applicationItem), (item, index) => {
                      this.ListItemLayout(item, index)
                    }, item => JSON.stringify(item))
                  }.backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
                  .borderRadius(Constants.BORDER_RADIUS)
                  .padding({ top: Constants.LIST_PADDING_TOP, bottom: Constants.LIST_PADDING_BOTTOM })
                  .onScrollIndex((start, end) => {
                    globalThis.scroller = this.scroller;
                    let alphabeticalIndex = appSort(this.applicationItem)[start].alphabeticalIndex;
                    let index = indexValue.indexOf(alphabeticalIndex.toUpperCase());
                    this.selectedIndex = index >= 0 ? index : 0;
                  })
                }.margin({ left: Constants.MANAGEMENT_ROW_PADDING_LEFT })
                .borderRadius(Constants.BORDER_RADIUS)
                .clip(true)
              }
            }.height(Constants.FULL_HEIGHT)
          }.margin({ top: Constants.MANAGEMENT_ROW_MARGIN_TOP, bottom: Constants.APPLICATION_LIST_MARGIN_BOTTOM })
          Column() {
            alphabetIndexerComponent({ applicationItem: $applicationItem, index: $selectedIndex })
          }.margin({ top: Constants.APPLICATION_ALPHABETINDEX_MARGIN_TOP, bottom: Constants.APPLICATION_LIST_MARGIN_BOTTOM })
          .width(Constants.APPLICATION_ALPHABETINDEX_WIDTH)
        }
      }
    }
  }
}

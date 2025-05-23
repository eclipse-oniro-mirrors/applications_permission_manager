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
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import display from '@ohos.display';
import common from '@ohos.app.ability.common';
import { groups, globalGroup, showSubPermissionsGroup } from '../common/model/permissionGroup';
import {
  Log,
  indexValue,
  addLocalTag,
  sortByName,
  supportPermission,
  getPermissionGroup,
  getGroupIdByPermission,
  getPermissionGroupByName
} from '../common/utils/utils';
import { AppInfo, PermissionApplications, GroupPermission, GroupInfo } from '../common/model/typedef';
import { GlobalContext } from '../common/utils/globalContext';
import { Permission, PermissionGroup } from '../common/model/definition';
import { GlobalDialogModel } from '../GlobalExtAbility/GlobalDialogModel';
import Constants from '../common/utils/constant';
import bundleManager from '@ohos.bundle.bundleManager';

@Extend(Image)function customizeImage(width: number, height: number) {
  .objectFit(ImageFit.Contain)
  .width(width)
  .height(height)
  .draggable(false)
};

@Entry({ useSharedStorage: true })
@Component
struct authorityManagementPage {
  @Builder ListItemLayout(item: GroupPermission) {
    ListItem() {
      Row() {
        Column() {
          Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
            Row() {
              Image(item.icon)
                .fillColor($r('sys.color.icon_secondary'))
                .customizeImage(Constants.MANAGEMENT_IMAGE_WIDTH, Constants.MANAGEMENT_IMAGE_HEIGHT)
                .margin({ right: Constants.MANAGEMENT_IMAGE_MARGIN_RIGHT })
              Text(item.groupName)
                .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('sys.color.font_primary'))
                .flexGrow(Constants.FLEX_GROW)
              SymbolGlyph($r('sys.symbol.chevron_forward'))
                .width(Constants.IMAGE_WIDTH)
                .height(Constants.IMAGE_HEIGHT)
                .fontSize(Constants.FONT_SIZE_18_vp)
                .fontColor([$r('sys.color.icon_tertiary')])
                .fontWeight(FontWeight.Medium)
            }
            .width(Constants.FULL_WIDTH)
            .height(Constants.MANAGEMENT_ROW_HEIGHT)
          }
        }.onClick(() => {
          if (item.group === 'OTHER' || showSubPermissionsGroup.indexOf(item.group) !== -1) {
            this.getUIContext().getRouter().pushUrl({
              url: 'pages/authority-secondary',
              params: { list: this.allPermissionApplications, backTitle: item.groupName, group: item.group }
            })
          } else {
            let dataList = this.allPermissionApplications.filter((ele) => {
              return ele.groupName === item.group;
            })

            GlobalContext.store('currentPermissionGroup', item.group);
            if (globalGroup.indexOf(item.group) == -1) {
              this.getUIContext().getRouter().pushUrl({
                url: 'pages/authority-tertiary-groups',
                params: { list: dataList, backTitle: item.groupName }
              })
            } else {
              GlobalDialogModel.getInstance().getMuteStateAndGoto(
                this.getUIContext(), item.group, item.groupName, dataList
              );
            }
          }
        })
      }
    }.padding({ left: $r('sys.float.ohos_id_card_margin_start'), right: $r('sys.float.ohos_id_card_margin_end') })
    .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
    .linearGradient((this.isTouch === item.group) ? {
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
        this.isTouch = item.group;
      }
      if (event.type === TouchType.Up) {
        this.isTouch = '';
      }
    })
  }

  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;
  @LocalStorageLink('initialGroups') initialGroups: bundleManager.BundleInfo[] = [];
  @State allPermissionApplications: PermissionApplications [] = []; // All app permissions
  @State allGroupPermission: GroupPermission[] = []; // All group permissions
  @State allUserPermissions: Permission[] = [];
  @State allBundleInfo: AppInfo[] = [];
  @State allGroups: PermissionGroup[] = [];
  @State currentIndex: number = 0;
  @State isTouch: string = '';
  @State isVertical: boolean = true;
  @Builder TabBuilder(index: number) {
    Flex({
      alignItems: index ? ItemAlign.Start : ItemAlign.End,
      justifyContent: FlexAlign.Center, direction: FlexDirection.Column
    }) {
      Text(index ? $r('app.string.application') : $r('app.string.permission'))
        .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
        .fontColor(
          this.currentIndex == index ?
          $r('sys.color.ohos_id_color_subtab_text_on') :
          $r('sys.color.icon_secondary')
        )
        .fontWeight(this.currentIndex == index ? FontWeight.Bold : FontWeight.Regular)
        .lineHeight(Constants.TEXT_LINE_HEIGHT)
        .baselineOffset(Constants.TAB_DECORATION_POSITION_Y)
      if (this.currentIndex == index) {
        Text(index ? $r('app.string.application') : $r('app.string.permission'))
          .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
          .fontWeight(FontWeight.Bold)
          .lineHeight(Constants.TAB_LINE_HEIGHT)
          .height(Constants.TAB_DECORATION_HEIGHT)
          .fontColor($r('sys.color.ohos_id_color_subtab_text_on'))
          .backgroundColor($r('sys.color.ohos_id_color_subtab_text_on'))
      }
    }.height(Constants.TAB_HEIGHT)
    .width(Constants.FULL_WIDTH)
    .padding({ left: this.isVertical ? Constants.TAB_INNER_PADDING : Constants.DEFAULT_PADDING_START,
      right: this.isVertical ? Constants.TAB_INNER_PADDING : Constants.DEFAULT_PADDING_END })
  }

  /**
   * Get all app permission information
   */
  async getAllBundlePermissions() {
    for (let i = 0; i < this.initialGroups.length; i++) {
      await this.deduplicationPermissions(this.initialGroups[i]);
    }
    this.getAllGroupPermission();
    this.getAllPermissionApplications();
    this.getLabelAndIcon();
    GlobalContext.store('allBundleInfo', this.allBundleInfo);
  }

  /**
   * Get all permission label
   */
  getLabelAndIcon() {
    this.allBundleInfo.forEach((bundleInfo: AppInfo) => {
      this.updateAppLabel(bundleInfo);
      this.updateAppIcon(bundleInfo);
    })
  }

  /**
   * Get all app permission information
   */
  getAllPermissionApplications() {
    for (let i = 0; i < this.allUserPermissions.length; i++) {
      let permission: Permission = this.allUserPermissions[i];
      let permissionGroup: GroupInfo = getPermissionGroup(permission);
      let icon: ResourceStr = permissionGroup.icon;
      let bundleNames: string[] = [];
      for (let j = 0; j < this.allBundleInfo.length; j++) {
        if (this.allBundleInfo[j].permissions.indexOf(permission) != -1) {
          bundleNames.push(this.allBundleInfo[j].bundleName);
        }
      }
      let pa: PermissionApplications = new PermissionApplications(permission, permissionGroup.name, bundleNames, icon);
      this.allPermissionApplications.push(pa);
    }
  }

  /**
   * Get permission group information
   */
  getAllGroupPermission() {
    groups.forEach((item) => {
      if (item.isShow) {
        this.allGroups.push(item.name);
      }
    })
    this.allUserPermissions.forEach((userPermission: Permission) => {
      let groupId = getGroupIdByPermission(userPermission);
      if (this.allGroups.indexOf(groups[groupId].name) == -1) {
        this.allGroups.push(groups[groupId].name);
      }
    })
    // Permission layout
    for (let i = 0; i < this.allGroups.length; i++) {
      let group = getPermissionGroupByName(this.allGroups[i]);
      let gp: GroupPermission = new GroupPermission(
        this.allGroups[i], group.permissions, group.groupName, group.icon, group.isShow
      );
      this.allGroupPermission.push(gp);
    }
  }

  /**
   * Deduplicate permission information and permission group information
   * @param {Object} info bundleInfos Application Information
   */
  async deduplicationPermissions(info: bundleManager.BundleInfo) {
    Log.info('allBundleInfo start: ' + info.name);
    let reqPermissions: Permission[] = [];
    info.reqPermissionDetails.forEach(item => {
      reqPermissions.push(item.name as Permission);
    })
    let reqPermissionsLen = reqPermissions.length;
    let reqUserPermissions: Permission[] = [];
    let acManager = abilityAccessCtrl.createAtManager()
    if (reqPermissionsLen > 0) {
      for (let j = 0; j < reqPermissions.length; j++) {
        let permission = reqPermissions[j];
        if ((permission == Permission.LOCATION) && !reqPermissions.includes(Permission.APPROXIMATELY_LOCATION)) {
          continue;
        }
        try {
          let flag = await acManager.getPermissionFlags(info.appInfo.accessTokenId, permission);
          if (flag == Constants.PERMISSION_SYSTEM_FIXED) {
            continue;
          }
        } catch (err) {
          Log.error('getPermissionFlags error: ' + JSON.stringify(err));
        }
        let supportPermissions = supportPermission();
        if (supportPermissions.indexOf(permission) != -1) {
          reqUserPermissions.push(permission);
          if (this.allUserPermissions.indexOf(permission) == -1) {
            this.allUserPermissions.push(permission);
          }
        }
      }
    }
    this.getAllBundleInfo(info, reqUserPermissions);
  }

  getAllBundleInfo(info: bundleManager.BundleInfo, reqUserPermissions: Permission[]) {
    let groupIds: number[] = [];
    for (let i = 0; i < reqUserPermissions.length; i++) {
      let groupId = getGroupIdByPermission(reqUserPermissions[i])
      if (groupIds.indexOf(groupId) == -1) {
        groupIds.push(groupId);
      }
    }

    let ap: AppInfo = new AppInfo(
      info.name,
      info.targetVersion,
      info.appInfo.accessTokenId,
      '',
      info.appInfo.iconId,
      info.appInfo.iconResource,
      info.appInfo.label,
      info.appInfo.labelId,
      info.appInfo.labelResource,
      reqUserPermissions,
      groupIds,
      '',
      '',
      ''
    );
    Log.info('allBundleInfo.push: ' + info.name);
    this.allBundleInfo.push(ap);
  }

  /**
   * Get app name resource
   * @param {Number} index index of all app permissions array
   * @param {String} bundleName Package names
   * @param {String} labelName Application Name
   */
  async updateAppLabel(info: AppInfo) {
    Log.info(
      'bundleName: ' + info.bundleName +
      ` labelResource: ` + JSON.stringify(info.labelResource) +
      ' labelId: ' + info.labelId
    );

    try {
      if (info.labelResource.id !== 0) {
        info.label = await this.context.resourceManager.getStringValue(info.labelResource);
      } else {
        let resourceManager = this.context.createBundleContext(info.bundleName).resourceManager;
        info.label = await resourceManager.getStringValue(info.labelId);
      }
    } catch (error) {
      Log.error('getStringValue promise error is ' + error);
    }
    addLocalTag(info);
  }

  /**
   * Get app icon resources
   * @param {Number} index index of all app permissions array
   * @param {String} bundleName Package names
   */
  async updateAppIcon(info: AppInfo) {
    Log.info(
      'bundleName: ' + info.bundleName +
      ` iconResource: ` + JSON.stringify(info.iconResource) +
      ' iconId: ' + info.iconId
    );

    try {
      if (info.iconResource.id !== 0) {
        let iconDescriptor = this.context.resourceManager.getDrawableDescriptor(info.iconResource);
        info.icon = iconDescriptor?.getPixelMap();
      } else {
        let resourceManager = this.context.createBundleContext(info.bundleName).resourceManager;
        let iconDescriptor = resourceManager.getDrawableDescriptor(info.iconId);
        info.icon = iconDescriptor?.getPixelMap();
      }
    } catch (error) {
      Log.error(`getDrawableDescriptor failed, error code: ${error.code}, message: ${error.message}.`);
    }

    if (!info.icon) {
      info.icon = $r('app.media.icon');
    }
  }

  /**
   * Lifecycle function, executed when the page is initialized
   */
  aboutToAppear() {
    this.getAllBundlePermissions();
    try {
      let dis = display.getDefaultDisplaySync();
      this.isVertical = dis.height > dis.width ? true : false;
      GlobalContext.store('isVertical', dis.height > dis.width ? true : false);
    } catch (error) {
      Log.error(`getDefaultDisplaySync failed. ${JSON.stringify(error)}`);
    }
  }

  getPermissionGroup(allGroup: GroupPermission[], order: number): GroupPermission[] {
    let fixedName: string[] = ['LOCATION', 'CAMERA', 'MICROPHONE'];
    let extraName: string[] = ['ADS'];
    let fixedGroup: GroupPermission[] = [];
    let extraGroup: GroupPermission[] = [];
    let changeGroup: GroupPermission[] = [];
    let otherGroup: GroupPermission[] = [];

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

    if (order == Constants.FIXED_GROUP) {
      return fixedGroup;
    } else if (order == Constants.CHANGE_GROUP) {
      return changeGroup;
    } else if (order == Constants.OTHER_GROUP) {
      return otherGroup;
    } else if (order == Constants.EXTRA_GROUP) {
      return extraGroup;
    }
    return [];
  }

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
              backBar( { title: JSON.stringify($r('app.string.permission_manager')), recordable: true })
            }
            Row() {
              Column() {
                Column() {
                  Stack() {
                    if (this.allGroupPermission.length) {
                      Tabs() {
                        TabContent() {
                          Row() {
                            Column() {
                              Scroll() {
                                Column() {
                                  List() {
                                    ListItem() {
                                      List() {
                                        ForEach(
                                          this.getPermissionGroup(this.allGroupPermission, Constants.FIXED_GROUP),
                                          (item: GroupPermission) => { this.ListItemLayout(item) },
                                          (item: GroupPermission) => JSON.stringify(item)
                                        )
                                      }.backgroundColor($r('sys.color.comp_background_list_card'))
                                      .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
                                      .padding(Constants.LIST_PADDING_TOP)
                                      .margin({ bottom: Constants.LIST_MARGIN_BOTTOM })
                                      .divider({
                                        strokeWidth: Constants.DIVIDER,
                                        color: $r('sys.color.comp_divider'),
                                        startMargin: Constants.DIVIDER_MARGIN_RIGHT_PERMISSION,
                                        endMargin: Constants.DEFAULT_MARGIN_END
                                      })
                                    }

                                    ListItem() {
                                      List() {
                                        ForEach(
                                          this.getPermissionGroup(this.allGroupPermission, Constants.CHANGE_GROUP),
                                          (item: GroupPermission) => { this.ListItemLayout(item) },
                                          (item: GroupPermission) => JSON.stringify(item)
                                        )
                                      }.backgroundColor($r('sys.color.comp_background_list_card'))
                                      .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
                                      .padding(Constants.LIST_PADDING_TOP)
                                      .margin({ bottom: Constants.LIST_MARGIN_BOTTOM })
                                      .divider({
                                        strokeWidth: Constants.DIVIDER,
                                        color: $r('sys.color.comp_divider'),
                                        startMargin: Constants.DIVIDER_MARGIN_RIGHT_PERMISSION,
                                        endMargin: Constants.DEFAULT_MARGIN_END
                                      })
                                    }

                                    if (
                                      this.getPermissionGroup(this.allGroupPermission, Constants.EXTRA_GROUP).length
                                    ) {
                                      ListItem() {
                                        List() {
                                          ForEach(
                                            this.getPermissionGroup(this.allGroupPermission, Constants.EXTRA_GROUP),
                                            (item: GroupPermission) => { this.ListItemLayout(item) },
                                            (item: GroupPermission) => JSON.stringify(item)
                                          )
                                        }.backgroundColor($r('sys.color.comp_background_list_card'))
                                        .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
                                        .padding(Constants.LIST_PADDING_TOP)
                                        .margin({ bottom: Constants.LIST_MARGIN_BOTTOM })
                                        .divider({
                                          strokeWidth: Constants.DIVIDER,
                                          color: $r('sys.color.comp_divider'),
                                          startMargin: Constants.DIVIDER_MARGIN_RIGHT_PERMISSION,
                                          endMargin: Constants.DEFAULT_MARGIN_END
                                        })
                                      }
                                    }

                                    ListItem() {
                                      List() {
                                        ForEach(
                                          this.getPermissionGroup(this.allGroupPermission, Constants.OTHER_GROUP),
                                          (item: GroupPermission) => { this.ListItemLayout(item) },
                                          (item: GroupPermission) => JSON.stringify(item)
                                        )
                                      }.backgroundColor($r('sys.color.comp_background_list_card'))
                                      .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
                                      .padding(Constants.LIST_PADDING_TOP)
                                      .divider({
                                        strokeWidth: Constants.DIVIDER,
                                        color: $r('sys.color.comp_divider'),
                                        startMargin: Constants.DIVIDER_MARGIN_RIGHT_PERMISSION,
                                        endMargin: Constants.DEFAULT_MARGIN_END
                                      })
                                    }.margin({ bottom: Constants.AUTHORITY_ROW_MARGIN_BOTTOM })
                                  }.height(Constants.FULL_HEIGHT)
                                  .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
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
                      .barWidth(Constants.BAR_WIDTH)
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
        .backgroundColor($r('sys.color.background_secondary'))
      }
    }.backgroundColor($r('sys.color.background_secondary'))
  }
}

@Component
struct applicationItem {
  @State applicationItem: AppInfo[] = GlobalContext.load('allBundleInfo'); // application info array
  @State searchResult: boolean = true; // search results
  @State selectedIndex: number = 0;
  @State isTouch: string = '';
  scroller: Scroller = new Scroller();

  @Builder ListItemLayout(item: AppInfo) {
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
                .fontColor($r('sys.color.font_primary'))
                .flexGrow(Constants.FLEX_GROW)
              Text(String(item.groupId.length))
                .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
                .fontColor($r('sys.color.font_secondary'))
              Text($r('app.string.right'))
                .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
                .fontColor($r('sys.color.font_secondary'))
                .margin({ right: Constants.APPLICATION_TEXT_MARGIN_RIGHT })
              SymbolGlyph($r('sys.symbol.chevron_forward'))
                .width(Constants.IMAGE_WIDTH)
                .height(Constants.IMAGE_HEIGHT)
                .fontSize(Constants.FONT_SIZE_18_vp)
                .fontColor([$r('sys.color.icon_tertiary')])
                .fontWeight(FontWeight.Medium)
            }
            .width(Constants.FULL_WIDTH)
            .height(Constants.AUTHORITY_ROW_HEIGHT)
            .constraintSize({ minHeight: Constants.AUTHORITY_CONSTRAINTSIZE_MINHEIGHT })
          }
        }.onClick(() => {
          GlobalContext.store('applicationInfo', item);
          this.getUIContext().getRouter().pushUrl({ url: 'pages/application-secondary' });
        })
      }
    }.padding({ left: $r('sys.float.ohos_id_card_margin_start'), right: $r('sys.float.ohos_id_card_margin_end') })
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
      if (event.type === TouchType.Down) {
        this.isTouch = item.bundleName;
      }
      if (event.type === TouchType.Up) {
        this.isTouch = '';
      }
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
                    ForEach(sortByName(this.applicationItem), (item: AppInfo) => {
                      this.ListItemLayout(item)
                    }, (item: AppInfo) => JSON.stringify(item))
                  }.backgroundColor($r('sys.color.comp_background_list_card'))
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
                    if (this.applicationItem.length > 0) {
                      let alphabeticalIndex = sortByName(this.applicationItem)[start].indexTag;
                      let index = indexValue.indexOf(alphabeticalIndex);
                      this.selectedIndex = index >= 0 ? index : 0;
                    }
                  })
                }.margin({ left: Constants.MANAGEMENT_ROW_PADDING_LEFT })
                .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
                .clip(true)
              }
            }.height(Constants.FULL_HEIGHT)
          }.margin({ top: Constants.MANAGEMENT_ROW_MARGIN_TOP, bottom: Constants.APPLICATION_LIST_MARGIN_BOTTOM })
          Column() {
            alphabetIndexerComponent({ applicationItem: $applicationItem, index: $selectedIndex })
          }
          .margin({
            top: Constants.APPLICATION_ALPHABETINDEX_MARGIN_TOP,
            bottom: Constants.APPLICATION_LIST_MARGIN_BOTTOM
          })
          .width(Constants.APPLICATION_ALPHABETINDEX_WIDTH)
        }
      }
    }
  }
}
/*
 * Copyright (c) 2022-2023 Huawei Device Co., Ltd.
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

import bundleManager from '@ohos.bundle.bundleManager';
import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import privacyManager from '@ohos.privacyManager';
import { backBar } from '../common/components/backBar';
import Constants from '../common/utils/constant';
import { userGrantPermissions } from '../common/model/permissionGroup';
import { Log, getPermissionGroup, getGroupIdByPermission } from '../common/utils/utils';
import { StringObj, AppInfoSimple, AppRecordInfo, AppInfo, GroupRecordInfo, AppGroupRecordInfo } from '../common/utils/typedef';
import { GlobalContext } from '../common/utils/globalContext';

@Extend(Image)function customizeImage(width: number, height: number) {
  .objectFit(ImageFit.Contain)
  .width(width)
  .height(height)
  .draggable(false)
};

@Entry
@Component
struct permissionRecordPage {
  private context = getContext(this) as common.UIAbilityContext;
  @State isVertical: boolean = GlobalContext.load('isVertical');
  @State allBundleInfo: AppInfo[] = GlobalContext.load('allBundleInfo');
  @State groups: GroupRecordInfo[] = [];
  @State applicationInfos: AppRecordInfo[] = [];
  @State permissionApplications: AppRecordInfo[] = [];
  @State permissionIndex: number = -1;
  @State applicationIndex: number = -1;
  @State strings: StringObj = new StringObj('', '');
  @State currentIndex: number = 0;
  @State show: boolean = false;
  @State isTouch: string = '';
  @State reqUserRecords: privacyManager.PermissionUsedRecord[] = [];
  @State reqUserPermissions: string[] = [];
  @State permissionGroups: AppGroupRecordInfo[] = [];
  @State groupNames: ResourceStr[] = [];
  @State appLastTime: number = 0;
  @Builder TabBuilder(index: number) {
    Flex({
      alignItems: index ? ItemAlign.Start : ItemAlign.End,
      justifyContent: FlexAlign.Center,
      direction: FlexDirection.Column
    }) {
      Text(index ? $r('app.string.application') : $r('app.string.permission'))
        .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
        .fontColor(
          this.currentIndex == index ?
          $r('sys.color.ohos_id_color_subtab_text_on') :
          $r('sys.color.ohos_id_color_secondary')
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
          .backgroundColor($r('sys.color.ohos_id_color_subtab_line_on'))
      }
    }.height(Constants.TAB_HEIGHT)
    .width(Constants.FULL_WIDTH)
    .padding({ left: this.isVertical ? Constants.TAB_INNER_PADDING : Constants.DEFAULT_PADDING_START,
      right: this.isVertical ? Constants.TAB_INNER_PADDING : Constants.DEFAULT_PADDING_END })
  }

  @Builder PermissionListItemLayout(item: GroupRecordInfo, index: number) {
    ListItem() {
      Column() {
        Column() {
          Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
            Row() {
              Image(item.icon)
                .fillColor($r('sys.color.ohos_id_color_secondary'))
                .customizeImage(Constants.MANAGEMENT_IMAGE_WIDTH, Constants.MANAGEMENT_IMAGE_HEIGHT)
                .margin({
                  right: Constants.MANAGEMENT_IMAGE_MARGIN_RIGHT_RECORD,
                  left: Constants.MANAGEMENT_IMAGE_MARGIN_LEFT
                })
              Column() {
                Text(item.groupName)
                  .width(Constants.MAXIMUM_HEADER_WIDTH)
                  .maxLines(Constants.MAXIMUM_HEADER_LINES)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('sys.color.ohos_id_color_text_primary'))
                  .lineHeight(Constants.TEXT_LINE_HEIGHT)
                  .margin({ bottom: Constants.TERTIARY_LABEL_MARGIN_BOTTOM })
                Text($r('app.string.visits', String(item.sum)))
                  .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
                  .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                  .lineHeight(Constants.TEXT_SMALL_LINE_HEIGHT)
              }.flexGrow(Constants.FLEX_GROW)
              .alignItems(HorizontalAlign.Start)
              Image(index == this.permissionIndex ? $r('app.media.xiangshangjiantou') : $r('app.media.xiangxiajiantou'))
                .fillColor($r('sys.color.ohos_id_color_secondary'))
                .customizeImage(Constants.IMAGE_WIDTH_RECORD, Constants.IMAGE_HEIGHT_RECORD)
            }
            .width(Constants.FULL_WIDTH)
            .height(Constants.LISTITEM_HEIGHT_PERMISSION)
          }
        }.onClick(() => {
          this.permissionIndex = this.permissionIndex == index ? -1 : index
          this.permissionApplications = this.applicationInfos.filter((appInfo) => {
            return appInfo.groupNames.includes(item.groupName);
          })
        })
        .padding({ left: $r('sys.float.ohos_id_card_margin_start'), right: $r('sys.float.ohos_id_card_margin_end') })
        if (index == this.permissionIndex) {
          List() {
            ForEach(this.permissionApplications, (permissionApplication: AppRecordInfo) => {
              ListItem() {
                Row() {
                  Image(permissionApplication.icon)
                    .customizeImage(Constants.APPLICATION_IMAGE_WIDTH, Constants.APPLICATION_IMAGE_HEIGHT)
                    .margin({ right: Constants.MANAGEMENT_IMAGE_MARGIN_RIGHT })
                  Column() {
                    Row().width(Constants.FULL_WIDTH).height(Constants.DIVIDER)
                      .backgroundColor($r('sys.color.ohos_id_color_list_separator'))
                      .position({ x: 0, y: 0 })
                    Text(permissionApplication.groupName)
                      .width(Constants.MAXIMUM_HEADER_WIDTH)
                      .maxLines(Constants.MAXIMUM_HEADER_LINES)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
                      .fontWeight(FontWeight.Medium)
                      .fontColor($r('sys.color.ohos_id_color_text_primary'))
                      .lineHeight(Constants.TEXT_LINE_HEIGHT)
                      .margin({ bottom: Constants.TERTIARY_LABEL_MARGIN_BOTTOM })
                    Text(
                      $r('app.string.recent_visit',
                      String(this.getAppRecords(permissionApplication, item.groupName, true)),
                      this.getTime(this.getAppRecords(permissionApplication, item.groupName, false)))
                    )
                      .padding({ right: Constants.LISTITEM_PADDING_RIGHT_RECORD })
                      .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
                      .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                      .lineHeight(Constants.TEXT_SMALL_LINE_HEIGHT)
                  }.alignItems(HorizontalAlign.Start)
                  .height(Constants.FULL_HEIGHT)
                  .width(Constants.FULL_WIDTH)
                  .justifyContent(FlexAlign.Center)
                }
              }.height(Constants.LISTITEM_HEIGHT_APPLICATION)
              .onClick(() => {
                let info: AppInfoSimple = new AppInfoSimple(
                  permissionApplication.name,
                  permissionApplication.api,
                  permissionApplication.accessTokenId,
                  permissionApplication.icon,
                  permissionApplication.groupName,
                  permissionApplication.reqUserPermissions,
                  permissionApplication.groupIds
                )
                GlobalContext.store('applicationInfo', info);
                router.pushUrl({ url: 'pages/application-secondary' });
              })
              .padding({
                left: $r('sys.float.ohos_id_card_margin_start'),
                right: $r('sys.float.ohos_id_card_margin_end')
              })
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
              .linearGradient((this.isTouch === permissionApplication.name) ? {
                  angle: 90,
                  direction: GradientDirection.Right,
                  colors: [['#DCEAF9', 0.0], ['#FAFAFA', 1.0]]
                } : {
                  angle: 90,
                  direction: GradientDirection.Right,
                  colors: [
                    [$r('sys.color.ohos_id_color_list_card_bg'), 1],
                    [$r('sys.color.ohos_id_color_list_card_bg'), 1]
                  ]
                })
              .onTouch(event => {
                if (event === undefined) {
                  return;
                }
                if (event.type === TouchType.Down) {
                  this.isTouch = permissionApplication.name;
                }
                if (event.type === TouchType.Up) {
                  this.isTouch = '';
                }
              })
            }, (item: AppRecordInfo) => JSON.stringify(item))
          }
        }
      }
    }.padding(Constants.LIST_PADDING_TOP)
    .margin({ bottom: Constants.LISTITEM_MARGIN_BOTTOM })
    .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
    .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
  }

  @Builder ApplicationListItemLayout(item: AppRecordInfo, index: number) {
    ListItem() {
      Column() {
        Column() {
          Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
            Row() {
              Image(item.icon)
                .customizeImage(Constants.APPLICATION_IMAGE_WIDTH, Constants.APPLICATION_IMAGE_HEIGHT)
                .margin({ right: Constants.MANAGEMENT_IMAGE_MARGIN_RIGHT })
              Column() {
                Text(item.groupName)
                  .width(Constants.MAXIMUM_HEADER_WIDTH)
                  .maxLines(Constants.MAXIMUM_HEADER_LINES)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('sys.color.ohos_id_color_text_primary'))
                  .lineHeight(Constants.TEXT_LINE_HEIGHT)
                  .margin({ bottom: Constants.TERTIARY_LABEL_MARGIN_BOTTOM })
                Row() {
                  ForEach(item.permissions, (permission: AppGroupRecordInfo) => {
                    Image(permission.icon)
                      .fillColor($r('sys.color.ohos_id_color_secondary'))
                      .customizeImage(
                        Constants.IMAGE_WIDTH_RECORD_APPLICATION,
                        Constants.IMAGE_HEIGHT_RECORD_APPLICATION
                      )
                      .margin({ right: Constants.APPLICATION_TEXT_MARGIN_RIGHT })
                  }, (item: AppGroupRecordInfo) => JSON.stringify(item))
                }
              }.flexGrow(Constants.FLEX_GROW)
              .alignItems(HorizontalAlign.Start)
              Image(
                index == this.applicationIndex ? $r('app.media.xiangshangjiantou') : $r('app.media.xiangxiajiantou')
              )
                .fillColor($r('sys.color.ohos_id_color_secondary'))
                .customizeImage(Constants.IMAGE_WIDTH_RECORD, Constants.IMAGE_HEIGHT_RECORD)
            }
            .width(Constants.FULL_WIDTH)
            .height(Constants.LISTITEM_HEIGHT_APPLICATION)
          }
        }.onClick(() => {
          this.applicationIndex = this.applicationIndex == index ? -1 : index
        })
        .padding({ left: $r('sys.float.ohos_id_card_margin_start'), right: $r('sys.float.ohos_id_card_margin_end') })
        if (index == this.applicationIndex) {
          List() {
            ForEach(item.permissions, (permission: AppGroupRecordInfo) => {
              ListItem() {
                Row() {
                  Image(permission.icon)
                    .fillColor($r('sys.color.ohos_id_color_secondary'))
                    .customizeImage(Constants.MANAGEMENT_IMAGE_WIDTH, Constants.MANAGEMENT_IMAGE_HEIGHT)
                    .margin({
                      right: Constants.MANAGEMENT_IMAGE_MARGIN_RIGHT_RECORD,
                      left: Constants.MANAGEMENT_IMAGE_MARGIN_LEFT
                    })
                  Column() {
                    Row().width(Constants.FULL_WIDTH).height(Constants.DIVIDER)
                      .backgroundColor($r('sys.color.ohos_id_color_list_separator'))
                      .position({ x: 0, y: 0 })
                    Text(permission.groupName)
                      .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
                      .fontWeight(FontWeight.Medium)
                      .fontColor($r('sys.color.ohos_id_color_text_primary'))
                      .lineHeight(Constants.TEXT_LINE_HEIGHT)
                      .margin({ bottom: Constants.TERTIARY_LABEL_MARGIN_BOTTOM })
                    Text($r('app.string.recent_visit', String(permission.count), this.getTime(permission.lastTime)))
                      .padding({ right: Constants.LISTITEM_PADDING_RIGHT_RECORD })
                      .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
                      .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                      .lineHeight(Constants.TEXT_SMALL_LINE_HEIGHT)
                  }.alignItems(HorizontalAlign.Start)
                  .height(Constants.FULL_HEIGHT)
                  .width(Constants.FULL_WIDTH)
                  .justifyContent(FlexAlign.Center)
                }
              }.height(Constants.LISTITEM_HEIGHT_PERMISSION)
              .onClick(() => {
                let info: AppInfoSimple = new AppInfoSimple(
                  item.name,
                  item.api,
                  item.accessTokenId,
                  item.icon,
                  item.groupName,
                  item.reqUserPermissions,
                  item.groupIds
                );
                GlobalContext.store('applicationInfo', info);
                router.pushUrl({ url: 'pages/application-secondary' });
              })
              .padding({
                left: $r('sys.float.ohos_id_card_margin_start'),
                right: $r('sys.float.ohos_id_card_margin_end')
              })
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
              .linearGradient((this.isTouch === permission.name) ? {
                   angle: 90,
                   direction: GradientDirection.Right,
                   colors: [['#DCEAF9', 0.0], ['#FAFAFA', 1.0]]
                 } : {
                   angle: 90,
                   direction: GradientDirection.Right,
                   colors: [
                     [$r('sys.color.ohos_id_color_list_card_bg'), 1],
                     [$r('sys.color.ohos_id_color_list_card_bg'), 1]
                   ]
                 })
              .onTouch(event => {
                if (event === undefined) {
                  return;
                }
                if (event.type === TouchType.Down) {
                  this.isTouch = permission.name;
                }
                if (event.type === TouchType.Up) {
                  this.isTouch = '';
                }
              })
            }, (item: AppGroupRecordInfo) => JSON.stringify(item))
          }
        }
      }
    }.padding(Constants.LIST_PADDING_TOP)
    .margin({ bottom: Constants.LISTITEM_MARGIN_BOTTOM })
    .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
    .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
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
              backBar( { title: JSON.stringify($r('app.string.permission_access_record')), recordable: false })
            }
            Row() {
              Column() {
                Column() {
                  Flex({ justifyContent: FlexAlign.Start }) {
                    Text($r('app.string.record_time_limit'))
                      .margin({ left: Constants.DEFAULT_MARGIN_START })
                      .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
                      .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                      .lineHeight(Constants.SUBTITLE_LINE_HEIGHT)
                  }.constraintSize({ minHeight: Constants.SUBTITLE_MIN_HEIGHT })
                  .padding({ top: Constants.SUBTITLE_PADDING_TOP, bottom: Constants.SUBTITLE_PADDING_BOTTOM })
                  if (this.groups.length) {
                    Stack() {
                      Tabs() {
                        TabContent() {
                          Row() {
                            Column() {
                              Scroll() {
                                Row() {
                                  List() {
                                    ForEach(this.groups, (item: GroupRecordInfo, index) => {
                                      this.PermissionListItemLayout(item, index as number)
                                    }, (item: GroupRecordInfo) => JSON.stringify(item))
                                  }.padding({ top: Constants.LIST_PADDING_TOP, bottom: Constants.LIST_PADDING_BOTTOM })
                                  .height(Constants.FULL_HEIGHT)
                                }.padding({
                                  left: Constants.MANAGEMENT_ROW_PADDING_LEFT,
                                  right: Constants.MANAGEMENT_ROW_PADDING_RIGHT,
                                  top: Constants.MANAGEMENT_ROW_PADDING_TOP,
                                  bottom: Constants.MANAGEMENT_ROW_PADDING_BOTTOM
                                })
                              }.scrollBar(BarState.Off)
                            }.width(Constants.FULL_WIDTH)
                          }
                        }.tabBar(this.TabBuilder(0))
                        TabContent() {
                          Row() {
                            Column() {
                              Scroll() {
                                Row() {
                                  if (this.show) {
                                    List() {
                                      ForEach(this.applicationInfos, (item: AppRecordInfo, index) => {
                                        this.ApplicationListItemLayout(item, index as number)
                                      }, (item: AppRecordInfo) => JSON.stringify(item))
                                    }
                                    .padding({ top: Constants.LIST_PADDING_TOP, bottom: Constants.LIST_PADDING_BOTTOM })
                                    .height(Constants.FULL_HEIGHT)
                                  }
                                }.padding({
                                  left: Constants.MANAGEMENT_ROW_PADDING_LEFT,
                                  right: Constants.MANAGEMENT_ROW_PADDING_RIGHT,
                                  top: Constants.MANAGEMENT_ROW_PADDING_TOP,
                                  bottom: Constants.MANAGEMENT_ROW_PADDING_BOTTOM
                                })
                              }.scrollBar(BarState.Off)
                            }.width(Constants.FULL_WIDTH)
                          }
                        }.tabBar(this.TabBuilder(1))
                      }
                      .barMode(BarMode.Fixed)
                      .barWidth(Constants.BAR_WIDTH)
                      .onChange((index) => {
                        this.currentIndex = index;
                        if (!this.show) {
                          this.show = true;
                        }
                      })
                    }.height(Constants.FULL_HEIGHT)
                  } else {
                    Flex({
                      justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center, direction: FlexDirection.Column
                    }) {
                      Image($r('app.media.noRecord'))
                        .customizeImage(Constants.NORECORD_IMAGE_WIDTH, Constants.NORECORD_IMAGE_HEIGHT)
                        .margin({ left: Constants.NORECORD_IMAGE_MARGIN_LEFT })
                      Text($r('app.string.no_record')).margin({ top: Constants.DIALOG_REQ_MARGIN_TOP })
                        .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
                        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                    }.width(Constants.FULL_WIDTH).height(Constants.FULL_HEIGHT)
                    .padding({ bottom: Constants.RECORD_PADDING_BOTTOM })
                  }
                }
              }
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

  /**
   * Get time
   * @param {Number} The time stamp
   */
  getTime(time: number, format = 'MM月DD日 NNHH:mm') {
    if (this.strings.morning == 'am') { format = 'HH:mm NN MM/DD' }
    let date = new Date(time);
    let key = ['MM', 'DD', 'NN', 'HH', 'mm'];
    let value = [
      date.getMonth() + 1,
      date.getDate(),
      date.getHours() >= 12 ? this.strings.afternoon : this.strings.morning,
      date.getHours() >= 12 ? date.getHours() - 12 : date.getHours(),
      date.getMinutes() >= 10 ? date.getMinutes() : '0' + date.getMinutes(),
    ];

    for (let i = 0; i < key.length; ++i) {
      format = format.replace(key[i], String(value[i]));
    }
    return format;
  }

  /**
   * Get application record info
   * @param {Object} application info
   * @param {String} groupName
   * @param {Boolean} true: count, false: lastTime
   */
  getAppRecords(appInfo: AppRecordInfo, groupName: ResourceStr, option: boolean): number {
    let record = appInfo.permissions.filter(permission => {
      return permission.groupName == groupName;
    })
    if (record.length > 0) {
      return option ? record[0].count : record[0].lastTime;
    } else {
      return 0;
    }
  }

  getStrings() {
    this.context.resourceManager.getStringValue($r('app.string.morning').id, (err, val) => {
      this.strings.morning = val;
    })
    this.context.resourceManager.getStringValue($r('app.string.afternoon').id, (err, val) => {
      this.strings.afternoon = val;
    })
  }

  async getReqUserRecords(record: privacyManager.BundleUsedRecord, info: bundleManager.BundleInfo) {
    for (let j = 0; j < record.permissionRecords.length; j++) {
      let permission = record.permissionRecords[j].permissionName;
      try {
        let flag = await abilityAccessCtrl.createAtManager().getPermissionFlags(info.appInfo.accessTokenId, permission);
        if (flag == Constants.PERMISSION_SYSTEM_FIXED) {
          continue;
        }
      } catch (err) {
        Log.error('getPermissionFlags error: ' + JSON.stringify(err));
      }
      if (userGrantPermissions.indexOf(permission) != -1) {
        this.reqUserRecords.push(record.permissionRecords[j]);
      }
    }
  }

  async getReqUserPermissions(reqPermissions: Permissions[], info: bundleManager.BundleInfo) {
    let acManager = abilityAccessCtrl.createAtManager();
    for (let k = 0; k < reqPermissions.length; k++) {
      let reqPermission = reqPermissions[k];
      try {
        let reqFlag = await acManager.getPermissionFlags(info.appInfo.accessTokenId, reqPermission);
        if (reqFlag == Constants.PERMISSION_SYSTEM_FIXED) {
          continue;
        }
      } catch (err) {
        Log.error('getPermissionFlags error: ' + JSON.stringify(err));
      }
      if (userGrantPermissions.indexOf(reqPermission) != -1) {
        this.reqUserPermissions.push(reqPermission);
      }
    }
  }

  getPermissionGroups() {
    this.reqUserRecords.forEach(reqUserRecord => {
      let group = getPermissionGroup(reqUserRecord.permissionName);
      if (!group) {
        Log.info('permission not find:' + reqUserRecord.permissionName);
      } else {
        let existing = this.permissionGroups.find(permissionGroup => permissionGroup.name == group.name);
        let lastTime = reqUserRecord.lastAccessTime;
        lastTime > this.appLastTime ? this.appLastTime = lastTime : '';
        if (!existing) {
          let appGroupRecord: AppGroupRecordInfo = new AppGroupRecordInfo(
            group.name,
            group.groupName,
            group.label,
            group.icon,
            reqUserRecord.accessCount,
            lastTime
          );
          this.permissionGroups.push(appGroupRecord);
          this.groupNames.push(group.groupName);
        } else {
          existing.count += reqUserRecord.accessCount;
          lastTime > existing.lastTime ? existing.lastTime = lastTime : '';
        }
      }
    })
  }

  getInfo(record: privacyManager.BundleUsedRecord, sortFlag: boolean) {
    bundleManager.getBundleInfo(record.bundleName, bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION |
    bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_REQUESTED_PERMISSION).then(async (info): Promise<boolean> => {
      let appInfo: AppRecordInfo = new AppRecordInfo('', '', '', 0, 0, [], [], [], [], 0);
      let reqPermissions: Permissions[] = [];
      let groupIds: number[] = [];
      this.reqUserPermissions = [];
      this.reqUserRecords = [];
      this.permissionGroups = [];
      this.groupNames = [];
      this.appLastTime = 0;
      info.reqPermissionDetails.forEach(item => {
        reqPermissions.push(item.name as Permissions);
      });
      await this.getReqUserRecords(record, info);
      await this.getReqUserPermissions(reqPermissions, info);
      if (this.reqUserRecords.length == 0) {
        return false;
      }
      this.getPermissionGroups();
      for (let i = 0; i < this.reqUserPermissions.length; i++) {
        let groupId = getGroupIdByPermission(this.reqUserPermissions[i])
        if (groupIds.indexOf(groupId) == -1) {
          groupIds.push(groupId);
        }
      }
      this.allBundleInfo.forEach(bundleInfo => {
        if (bundleInfo.bundleName === info.name) {
          appInfo.groupName = bundleInfo.label;
          appInfo.icon = bundleInfo.icon;
        }
      })
      appInfo.name = info.name;
      appInfo.api = info.targetVersion;
      appInfo.accessTokenId = info.appInfo.accessTokenId;
      appInfo.reqUserPermissions = this.reqUserPermissions;
      appInfo.permissions = this.permissionGroups;
      appInfo.groupNames = this.groupNames;
      appInfo.groupIds = groupIds;
      appInfo.appLastTime = this.appLastTime;
      this.applicationInfos.push(appInfo);
      if (sortFlag) {
        let appInfos: AppRecordInfo[] = [];
        this.applicationInfos.forEach(item => { appInfos.push(item) });
        appInfos.sort((a, b) => { return b.appLastTime - a.appLastTime });
        this.applicationInfos = appInfos;
      }
      return true;
    })
  }

  getAllRecords() {
    let request: privacyManager.PermissionUsedRequest = {
      tokenId: 0,
      isRemote: false,
      deviceId: '',
      bundleName: '',
      permissionNames: [],
      beginTime: 0,
      endTime: 0,
      flag: 1
    }
    privacyManager.getPermissionUsedRecord(request).then(records => {
      this.getRecord(records);
    })
  }

  async getRecord(records: privacyManager.PermissionUsedResponse) {
    let groupArray: GroupRecordInfo[] = [];
    let acManager = abilityAccessCtrl.createAtManager();
    for (let i = 0; i < records.bundleRecords.length; i++) {
      let record = records.bundleRecords[i];
      Log.info('bundleName: ' + record.bundleName + 'permissionRecords: ' + JSON.stringify(record.permissionRecords));
      try {
        await bundleManager.queryAbilityInfo({
          bundleName: record.bundleName,
          action: 'action.system.home',
          entities: ['entity.system.home']
        }, bundleManager.AbilityFlag.GET_ABILITY_INFO_WITH_APPLICATION);
      } catch (e) {
        continue;
      }
      this.getInfo(record, (i + 1) == records.bundleRecords.length);
      for (let j = 0; j < record.permissionRecords.length; j++) {
        let permissionRecord = record.permissionRecords[j];
        try {
          let reqFlag = await acManager.getPermissionFlags(record.tokenId, permissionRecord.permissionName);
          if (reqFlag == Constants.PERMISSION_SYSTEM_FIXED) {
            continue;
          }
        } catch (err) {
          Log.error('getPermissionFlags error: ' + JSON.stringify(err));
        }
        let group = getPermissionGroup(permissionRecord.permissionName);
        if (group) {
          let exist = groupArray.find(permissionGroup => permissionGroup.name == group.name);
          let lastTime = permissionRecord.lastAccessTime;
          if (!exist) {
            let groupRecord: GroupRecordInfo = new GroupRecordInfo(
              group.name,
              group.groupName,
              group.label,
              group.icon,
              group.permissions,
              permissionRecord.accessCount,
              lastTime);
            groupArray.push(groupRecord);
          } else {
            exist.sum += permissionRecord.accessCount;
            lastTime > exist.recentVisit ? exist.recentVisit = lastTime : '';
          }
        }
      }
    }
    groupArray.sort((a, b) => { return b.recentVisit - a.recentVisit });
    this.groups = groupArray;
  }

  aboutToAppear() {
    this.getStrings();
    this.getAllRecords();
  }
}

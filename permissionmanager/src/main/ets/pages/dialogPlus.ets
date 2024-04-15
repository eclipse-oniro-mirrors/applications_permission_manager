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

import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import bundleManager from '@ohos.bundle.bundleManager';
import rpc from '@ohos.rpc';
import window from '@ohos.window';
import common from '@ohos.app.ability.common';
import display from '@ohos.display';
import deviceInfo from '@ohos.deviceInfo';
import pasteboard from '@ohos.pasteboard';
import { BusinessError } from '@ohos.base';
import { Log, getPermissionGroup, titleTrim, getPermissionLabel } from '../common/utils/utils';
import { GroupInfo, WantInfo } from '../common/utils/typedef';
import { GlobalContext } from '../common/utils/globalContext';
import Constants from '../common/utils/constant';
import { showSubPermissionsGroup, userGrantPermissions } from '../common/model/permissionGroup';
import { LocationCanvas } from '../common/components/location';

@Extend(Button)function customizeButton() {
  .backgroundColor($r('sys.color.ohos_id_color_dialog_bg'))
  .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
  .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
  .fontWeight(FontWeight.Medium)
  .height(Constants.BUTTON_HEIGHT)
  .width(Constants.HALF_LENGTH)
}

const FUZZY_LOCATION_PERMISSION = 'ohos.permission.APPROXIMATELY_LOCATION';
const PRECISE_LOCATION_PERMISSION = 'ohos.permission.LOCATION';
const PASTE = 'ohos.permission.READ_PASTEBOARD';
const DOWNLOAD_PERMISSION = 'ohos.permission.READ_WRITE_DOWNLOAD_DIRECTORY';
const DESKTOP_PERMISSION = 'ohos.permission.READ_WRITE_DESKTOP_DIRECTORY';
const DOCUMENTS_PERMISSION = 'ohos.permission.READ_WRITE_DOCUMENTS_DIRECTORY';
const fuzzyMarks = [Constants.LOCATION_FUZZY, Constants.LOCATION_BOTH_FUZZY, Constants.LOCATION_BOTH_PRECISE];
const preciseMarks = [Constants.LOCATION_UPGRADE, Constants.LOCATION_BOTH_PRECISE];
let bottomPopoverTypes = ['default', 'phone'];

let win: window.Window;
let want: WantInfo;
let storage = LocalStorage.getShared();

@Entry(storage)
@Component
struct dialogPlusPage {
  @LocalStorageLink('want') want: WantInfo = new WantInfo([]);
  @LocalStorageLink('win') win: window.Window = {} as window.Window;
  @State isUpdate: number = -1;

  privacyDialogController: CustomDialogController | null = new CustomDialogController({
    builder: PermissionDialog({ isUpdate: $isUpdate }),
    autoCancel: false,
    alignment: DialogAlignment.Center,
    customStyle: true
  })

  build() {}

  aboutToAppear() {
    win = this.win
    want = this.want
    if (this.privacyDialogController !== null) {
      this.privacyDialogController.open();
    }
  }

  aboutToDisappear() {
    this.privacyDialogController = null;
  }

  onPageShow() {
    this.isUpdate ++;
  }
}

@CustomDialog
struct PermissionDialog {
  private context = getContext(this) as common.ServiceExtensionContext;
  @State isBottomPopover: boolean = true;
  @State count: number = 0;
  @State result: Array<number> = [];
  @State accessTokenId: number = 0;
  @State initStatus: number = Constants.INIT_NEED_TO_WAIT;
  @State reqPerms: Array<string> = [];
  @State grantGroups: Array<GroupInfo> = [];
  @State userFixedFlag: number = 2; // means user fixed
  @State grantStatus: number = -1;
  @State appName: string = '';
  @State locationFlag: number = Constants.LOCATION_NONE;
  @State targetVersion: number = 0;
  @State reqPermissionDetails: bundleManager.ReqPermissionDetail[] = [];
  @State naviHeight: number = 0
  @State refresh: number = 0;
  @State pasteBoardName: string = '';
  @State sureButton: Resource = $r('app.string.ALLOW');
  @Link @Watch('updateReason') isUpdate: number;
  controller?: CustomDialogController

  build() {
    GridRow({
      columns: {
        xs: Constants.XS_COLUMNS,
        sm: Constants.SM_COLUMNS,
        md: Constants.MD_COLUMNS,
        lg: Constants.LG_COLUMNS
      },
      gutter: Constants.DIALOG_GUTTER
    }) {
      GridCol({
        span: {
          xs: Constants.XS_SPAN,
          sm: Constants.SM_SPAN,
          md: Constants.DIALOG_MD_SPAN,
          lg: Constants.DIALOG_LG_SPAN
        },
        offset: {
          xs: Constants.XS_OFFSET,
          sm: Constants.SM_OFFSET,
          md: Constants.DIALOG_MD_OFFSET,
          lg: Constants.DIALOG_LG_OFFSET
        }
      }) {
        Flex({
          justifyContent: FlexAlign.Center, alignItems: this.isBottomPopover ? ItemAlign.End : ItemAlign.Center
        }) {
          Column() {
            if ((this.initStatus != Constants.INIT_NEED_TO_WAIT) && this.verify()) {
              Image(
                this.grantGroups[this.count >= this.grantGroups.length ?
                this.grantGroups.length - 1 :
                this.count].icon
              )
                .width(Constants.DIALOG_ICON_WIDTH)
                .height(Constants.DIALOG_ICON_HEIGHT)
                .fillColor($r('sys.color.ohos_id_color_text_primary'))
                .margin({
                  top: Constants.DIALOG_ICON_MARGIN_TOP
                })
              if (this.grantGroups.length > 1) {
                Text(`${this.count + 1} / ${this.grantGroups.length}`)
                  .fontSize(Constants.DIALOG_LABEL_FONT_SIZE)
                  .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                  .lineHeight(Constants.DIALOG_LABEL_LINE_HEIGHT)
                  .margin({
                    top: Constants.DIALOG_LABEL_MARGIN_TOP
                  })
              }
              Scroll() {
                Column() {
                  Row() {
                    Flex({ justifyContent: FlexAlign.Start }) {
                      Text() {
                        Span($r('app.string.whether_to_allow'))
                        Span(this.appName)
                        Span($r('app.string.quotes'))
                        Span(this.showTitle())
                      }
                        .fontSize(Constants.DIALOG_REQ_FONT_SIZE)
                        .fontColor($r('sys.color.ohos_id_color_text_primary'))
                        .fontWeight(FontWeight.Medium)
                        .fontSize(Constants.DIALOG_REQ_FONT_SIZE)
                        .lineHeight(Constants.DIALOG_REQ_LINE_HEIGHT)
                        .margin({
                          top: Constants.DIALOG_REQ_MARGIN_TOP,
                          left: Constants.DIALOG_REQ_MARGIN_LEFT,
                          right: Constants.DIALOG_REQ_MARGIN_RIGHT
                        })
                    }
                  }

                  Row() {
                    Flex({ justifyContent: FlexAlign.Start }) {
                      Text() {
                        if (this.currentGroup() === 'LOCATION') {
                          Span($r('app.string.close_exact_position'))
                        } else if (this.currentGroup() === 'PASTEBOARD') {
                          if (this.pasteBoardName) {
                            Span($r('app.string.pasteBoard_app', this.pasteBoardName))
                          }
                          Span($r('app.string.pasteBoard_desc'))
                        } else {
                          if (
                            this.grantGroups[this.count >= this.grantGroups.length ?
                            this.grantGroups.length - 1 :
                            this.count].description.length > 0
                          ) {
                            ForEach(
                              this.grantGroups[this.count >= this.grantGroups.length ?
                              this.grantGroups.length - 1 :
                              this.count].description,
                              (item: ResourceStr) => {
                                Span(item)
                              }
                            )
                            Span(this.punctuation())
                          }
                          Span(this.grantGroups[this.count >= this.grantGroups.length ?
                            this.grantGroups.length - 1 :
                            (this.count + this.refresh - this.refresh)].reason)
                        }
                      }
                        .fontSize(Constants.DIALOG_DESP_FONT_SIZE)
                        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                        .fontSize(Constants.DIALOG_DESP_FONT_SIZE)
                        .lineHeight(Constants.DIALOG_DESP_LINE_HEIGHT)
                        .margin({
                          top: Constants.DIALOG_DESP_MARGIN_TOP,
                          left: Constants.DIALOG_DESP_MARGIN_LEFT,
                          right: Constants.DIALOG_DESP_MARGIN_RIGHT,
                          bottom: Constants.DIALOG_DESP_MARGIN_BOTTOM
                        })
                    }
                  }

                  if (
                    this.locationFlag > Constants.LOCATION_NONE &&
                    this.grantGroups[this.count >= this.grantGroups.length ?
                    this.grantGroups.length - 1 :
                    this.count].name === 'LOCATION'
                  ) {
                    LocationCanvas({ locationFlag: $locationFlag })
                  }
                }
              }.constraintSize({ maxHeight: Constants.MAXIMUM_HEADER_HEIGHT })
              Row() {
                Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
                  Button($r('app.string.BAN'))
                    .onClick(() => {
                      this.privacyCancel(
                        this.grantGroups[this.count], this.accessTokenId, this.reqPerms, this.userFixedFlag
                      )
                    }).customizeButton()
                  Divider()
                    .color($r('sys.color.ohos_id_color_list_separator'))
                    .vertical(true)
                    .strokeWidth(Constants.DIALOG_DIVIDER)
                    .height(Constants.DIVIDER_HEIGHT)
                    .opacity(0.2)
                  Button(this.sureButton)
                    .onClick(() => {
                      this.privacyAccept(
                        this.grantGroups[this.count],
                        this.accessTokenId,
                        this.reqPerms,
                        this.currentGroup() === 'PASTEBOARD' ? Constants.PERMISSION_ALLOW_THIS_TIME : this.userFixedFlag
                      )
                    }).customizeButton()
                }.margin({ left: Constants.BUTTON_MARGIN_LEFT, right: Constants.BUTTON_MARGIN_RIGHT })
              }
            }
          }
          .backgroundColor($r('sys.color.ohos_id_color_dialog_bg'))
          .borderRadius(Constants.DIALOG_PRIVACY_BORDER_RADIUS)
          .width(Constants.FULL_WIDTH)
          .padding({ bottom: Constants.DIALOG_PADDING_BOTTOM })
          .margin({ bottom: $r('sys.float.ohos_id_dialog_margin_bottom') })
          .clip(true)
        }.width(Constants.FULL_WIDTH)
        .height(Constants.FULL_HEIGHT)
      }
    }.margin({ left: this.isBottomPopover ? Constants.DIALOG_MARGIN_VERTICAL : Constants.DIALOG_MARGIN,
      right: this.isBottomPopover ? Constants.DIALOG_MARGIN_VERTICAL : Constants.DIALOG_MARGIN,
      bottom: this.isBottomPopover ? this.naviHeight + 'px' : 0})
  }

  showTitle(): ResourceStr {
    let index = this.count >= this.grantGroups.length ? this.grantGroups.length - 1 : this.count;
    if (this.grantGroups[index].name == 'LOCATION') {
      if (this.locationFlag == Constants.LOCATION_FUZZY) {
        return $r('app.string.access_general_location');
      }
      if (this.locationFlag == Constants.LOCATION_UPGRADE) {
        return $r('app.string.fuzzy_to_exact');
      }
    }
    return this.grantGroups[index].label;
  }

  currentGroup() {
    let index = this.count >= this.grantGroups.length ? this.grantGroups.length - 1 : this.count;
    if (this.grantGroups[index].name == 'LOCATION') {
      this.sureButton = $r('app.string.ALLOWED_ONLY_DURING_USE');
      if ((this.locationFlag == Constants.LOCATION_FUZZY) || (this.locationFlag == Constants.LOCATION_BOTH_FUZZY)) {
        return 'LOCATION';
      }
      return 'LOCATION_PRECISE';
    }
    if (this.grantGroups[index].name == 'PASTEBOARD') {
      this.sureButton = $r('app.string.THIS_TIME_ONLY');
      return 'PASTEBOARD';
    }
    this.sureButton = $r('app.string.ALLOW');
    return 'Normal';
  }

  punctuation() {
    let reason = this.grantGroups[this.count >= this.grantGroups.length ?
      this.grantGroups.length - 1 : this.count].reason;
    return reason ? $r('app.string.comma') : $r('app.string.period');
  }

  verify() {
    if ((this.initStatus == Constants.INIT_NEED_TO_TERMINATED) || (this.count >= this.grantGroups.length)) {
      this.answerRequest();
      this.initStatus = Constants.INIT_NEED_TO_WAIT;
      return false;
    }
    return true;
  }

  answerRequest() {
    let ret: number = Constants.RESULT_SUCCESS;
    if (this.initStatus == Constants.INIT_NEED_TO_TERMINATED) {
      ret = Constants.RESULT_FAILURE;
    }
    this.answer(ret, this.reqPerms);
  }

  answer(ret: number, reqPerms: string[]) {
    Log.info('code:' + ret + ', perms=' + JSON.stringify(reqPerms) + ', result=' + JSON.stringify(this.result));
    let perms: string[] = [];
    let results: number[] = [];
    reqPerms.forEach(perm => {
      perms.push(perm);
    })
    this.result.forEach(result => {
      results.push(result);
    })
    let option = new rpc.MessageOption();
    let data = new rpc.MessageSequence();
    let setDialogData = new rpc.MessageSequence();
    let reply = new rpc.MessageSequence();
    Promise.all([data.writeInterfaceToken(Constants.ACCESS_TOKEN),
      data.writeStringArray(perms),
      data.writeIntArray(results),
      setDialogData.writeInterfaceToken(Constants.ACCESS_TOKEN),
    ]).then(() => {
      let proxy = want.parameters['ohos.ability.params.callback'].value as rpc.RemoteObject;
      proxy.sendMessageRequest(Constants.RESULT_CODE, data, reply, option);
      proxy.sendMessageRequest(Constants.RESULT_CODE_1, setDialogData, reply, option);
      this.destruction();
    }).catch(() => {
      Log.error('write result failed!');
      this.destruction();
    })
  }

  destruction() {
    let windowNum: number = GlobalContext.load('windowNum');
    windowNum --;
    Log.info('windowNum:' + windowNum);
    GlobalContext.store('windowNum', windowNum);
    win.destroyWindow();
    if (windowNum == 0) {
      this.context.terminateSelf();
    }
  }

  async privacyAccept(group: GroupInfo, accessTokenId: number, permissionList: string[], userFixedFlag: number) {
    let num = 0;
    group.permissions.forEach(async permission => {
      this.grantStatus = -1;
      if (showSubPermissionsGroup.indexOf(group.name) == -1) {
        if (group.name == 'LOCATION' && this.targetVersion >= Constants.API_VERSION_SUPPORT_STAGE) {
          if (fuzzyMarks.includes(this.locationFlag) && permission === FUZZY_LOCATION_PERMISSION) {
            await this.operationPermission(true, accessTokenId, permission, userFixedFlag);
          }
          if (preciseMarks.includes(this.locationFlag) && permission === PRECISE_LOCATION_PERMISSION) {
            await this.operationPermission(true, accessTokenId, permission, userFixedFlag);
          }
        } else {
          await this.operationPermission(true, accessTokenId, permission, userFixedFlag);
        }
      } else {
        if (permissionList.includes(permission)) {
          await this.operationPermission(true, accessTokenId, permission, userFixedFlag);
        }
      }
      if (this.grantStatus == abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        permissionList.forEach((req, idx) => {
          if (req == permission) {
            this.result[idx] = abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
          }
        })
      }
      num ++;
      if (num == group.permissions.length) {
        this.count ++;
      }
    })
  }

  async privacyCancel(group: GroupInfo, accessTokenId: number, permissionList: string[], userFixedFlag: number) {
    group.permissions.forEach(async permission => {
      if (showSubPermissionsGroup.indexOf(group.name) == -1) {
        if (group.name == 'LOCATION') {
          if (permissionList.includes(permission) && this.locationFlag !== Constants.LOCATION_UPGRADE) {
            await this.operationPermission(false, accessTokenId, permission, userFixedFlag);
          }
        } else {
          await this.operationPermission(false, accessTokenId, permission, userFixedFlag);
        }
      } else {
        if (permissionList.includes(permission)) {
          await this.operationPermission(false, accessTokenId, permission, userFixedFlag);
        }
      }
    })
    this.count ++;
  }

  async operationPermission(status: boolean, token: number, permission: Permissions, flag: number) {
    if (status) {
      try {
        Log.info('grantUserGrantedPermission: ' + permission);
        await abilityAccessCtrl.createAtManager().grantUserGrantedPermission(token, permission, flag).then(() => {
          this.grantStatus = abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
        })
      } catch (err) {
        Log.error('failed to grant permission: ' + permission);
      }
    } else {
      try {
        Log.info('revokeUserGrantedPermission: ' + permission)
        await abilityAccessCtrl.createAtManager().revokeUserGrantedPermission(token, permission, flag);
      } catch (err) {
        Log.error('failed to revoke permission:' + permission);
      }
    }
  }

  getGrantGroups(stateGroup: number[]) {
    //Processing of positioning
    if (this.targetVersion >= Constants.API_VERSION_SUPPORT_STAGE) {
      if (this.reqPerms.includes(FUZZY_LOCATION_PERMISSION)) {
        this.locationFlag = Constants.LOCATION_FUZZY;
        if (this.reqPerms.includes(PRECISE_LOCATION_PERMISSION)) {
          this.locationFlag = Constants.LOCATION_BOTH_PRECISE;
          let fuzzyIndex = this.reqPerms.indexOf(FUZZY_LOCATION_PERMISSION);
          if (stateGroup[fuzzyIndex] == Constants.PASS_OPER) {
            this.locationFlag = Constants.LOCATION_UPGRADE;
          }
        }
      }
    }

    this.reqPerms.forEach((permission, idx) => {
      //已授权
      if (stateGroup[idx] == Constants.PASS_OPER) {
        Log.info('permission has been fixed:' + permission);
        this.result[idx] = abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
        //待授权
      } else if (stateGroup[idx] == Constants.DYNAMIC_OPER) {
        if (!userGrantPermissions.includes(permission)) {
          Log.info('permission not find:' + permission);
        } else {
          this.addGroup(permission);
        }
      }
    })
    this.initStatus = Constants.INIT_NEED_TO_VERIFY;
  }

  addGroup(permission: string) {
    let group = getPermissionGroup(permission);
    if (group.name === 'FOLDER') {
      switch (permission) {
        case DOWNLOAD_PERMISSION:
          let downloadGroup = new GroupInfo(group.name, group.groupName, $r('app.string.group_label_download_folder'),
            group.icon, group.description, group.reason, [DOWNLOAD_PERMISSION], group.isShow)
          this.grantGroups.push(downloadGroup);
          break;
        case DESKTOP_PERMISSION:
          let desktopGroup = new GroupInfo(group.name, group.groupName, $r('app.string.group_label_desktop_folder'),
            group.icon, group.description, group.reason, [DESKTOP_PERMISSION], group.isShow)
          this.grantGroups.push(desktopGroup);
          break;
        case DOCUMENTS_PERMISSION:
          let documentGroup = new GroupInfo(group.name, group.groupName, $r('app.string.group_label_document_folder'),
            group.icon, group.description, group.reason, [DOCUMENTS_PERMISSION], group.isShow)
          this.grantGroups.push(documentGroup);
          break;
      }
      return
    }
    let exist = this.grantGroups.find(grantGroup => grantGroup.name == group.name);
    if (showSubPermissionsGroup.indexOf(group.name) != -1) {
      let label = getPermissionLabel(permission)
      if (!exist) {
        group.description.push(label);
        this.grantGroups.push(group);
      } else {
        if (exist.description.indexOf(label) == -1) {
          exist.description.push($r('app.string.and'));
          exist.description.push(label);
        }
      }
    } else {
      if (!exist) {
        this.grantGroups.push(group);
      }
    }
  }

  getApplicationName(bundleName: string) {
    Log.info('getApplicationName bundleName:' + bundleName);
    bundleManager.getApplicationInfo(bundleName, bundleManager.ApplicationFlag.GET_APPLICATION_INFO_DEFAULT)
    .then(applicationInfo => {
      let context = this.context.createBundleContext(bundleName);
      context.resourceManager.getStringValue(applicationInfo.labelId, (err, value) => {
        if (value == undefined) {
          this.appName = titleTrim(applicationInfo.label);
        } else {
          this.appName = titleTrim(value);
        }
        Log.info('hap label:' + applicationInfo.label + ', value:' + this.appName);
      })
    }).catch((err: BusinessError) => {
      Log.error('applicationInfo error :' + err);
      this.initStatus = Constants.INIT_NEED_TO_TERMINATED;
    })
    this.grantGroups.forEach((group) => {
      this.getReason(group, bundleName);
    })
  }

  getReason(group: GroupInfo, bundleName: string) {
    group.permissions.forEach(permission => {
      if (this.reqPerms.indexOf(permission) != -1) {
        this.reqPermissionDetails.forEach(reqPermissionDetail => {
          if (reqPermissionDetail.name == permission) {
            Log.info('reqPermissionDetail: ' + JSON.stringify(reqPermissionDetail));
            let context = this.context.createModuleContext(bundleName, reqPermissionDetail.moduleName);
            context.resourceManager.getStringValue(reqPermissionDetail.reasonId, (err, value) => {
              if (value !== undefined && group.reason === '') {
                group.reason = value.slice(Constants.START_SUBSCRIPT, Constants.END_SUBSCRIPT);
                this.refresh ++;
              }
              this.initStatus = Constants.INIT_NEED_TO_REFRESH;
            })
          }
        })
      }
    })
  }

  getAvoidWindow() {
    let type = window.AvoidAreaType.TYPE_SYSTEM;
    try {
      win.on('avoidAreaChange', (data) => {
        if (data.type == window.AvoidAreaType.TYPE_SYSTEM) {
          Log.info('avoidAreaChange: ' + JSON.stringify(data));
          this.naviHeight = data.area.bottomRect.height;
        }
      });
      let avoidArea = win.getWindowAvoidArea(type);
      Log.info('avoidArea: ' + JSON.stringify(avoidArea));
      this.naviHeight = avoidArea.bottomRect.height;
    } catch (exception) {
      Log.error('Failed to obtain the area. Cause:' + JSON.stringify(exception));
    }
  }

  getPopupPosition() {
    try {
      let dis = display.getDefaultDisplaySync();
      let isVertical = dis.width > dis.height ? false : true;
      this.isBottomPopover = (bottomPopoverTypes.includes(deviceInfo.deviceType) && isVertical) ? true : false;
    } catch (exception) {
      Log.error('Failed to obtain the default display object. Code: ' + JSON.stringify(exception));
    };
  }

  getPasteBoardInfo() {
    if (this.reqPerms.includes(PASTE)) {
      let systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
      this.pasteBoardName = systemPasteboard.getDataSource();
    }
  }

  updateReason() {
    if (this.isUpdate > 0) {
      this.getApplicationName(want.parameters['ohos.aafwk.param.callerBundleName'])
    }
  }

  aboutToAppear() {
    this.count = 0;
    this.initStatus = Constants.INIT_NEED_TO_WAIT;
    this.result = [];
    this.reqPerms = want.parameters['ohos.user.grant.permission'];
    this.accessTokenId = want.parameters['ohos.aafwk.param.callerToken'];
    if (this.reqPerms == undefined || this.accessTokenId == undefined || this.reqPerms.length == 0) {
      Log.info('invalid parameters');
      this.initStatus = Constants.INIT_NEED_TO_TERMINATED;
      return;
    }
    Log.info('request permission=' + JSON.stringify(this.reqPerms) + ', tokenId = ' + this.accessTokenId);
    Log.info('permission state=' + JSON.stringify(want.parameters['ohos.user.grant.permission.state']));
    this.result = new Array(this.reqPerms.length).fill(-1);
    this.getAvoidWindow();
    this.getPopupPosition();
    this.getPasteBoardInfo();
    let bundleName: string = want.parameters['ohos.aafwk.param.callerBundleName'];
    bundleManager.getBundleInfo(bundleName, bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_REQUESTED_PERMISSION)
      .then(bundleInfo => {
        this.targetVersion = bundleInfo.targetVersion;
        this.reqPermissionDetails = bundleInfo.reqPermissionDetails;
        this.getGrantGroups(want.parameters['ohos.user.grant.permission.state']);
        this.getApplicationName(bundleName);
    }).catch((err: BusinessError) => {
      Log.error('getBundleInfo error :' + JSON.stringify(err));
      this.initStatus = Constants.INIT_NEED_TO_TERMINATED;
    })
  }
}


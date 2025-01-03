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
import pasteboard from '@ohos.pasteboard';
import { BusinessError } from '@ohos.base';
import { CustomContentDialog } from '@ohos.arkui.advanced.Dialog';
import {
  Log,
  getPermissionGroup,
  titleTrim,
  getPermissionLabel,
  getFontSizeScale,
  supportPermission
} from '../common/utils/utils';
import { Permission, ButtonStatus } from '../common/model/definition';
import { GroupInfo, WantInfo } from '../common/model/typedef';
import { GlobalContext } from '../common/utils/globalContext';
import Constants from '../common/utils/constant';
import { showSubPermissionsGroup, buttonResource } from '../common/model/permissionGroup';
import { LocationCanvas } from '../common/components/location';
import { MeasureText } from '@kit.ArkUI';

@Extend(Button)function customizeButton() {
  .buttonStyle(ButtonStyleMode.TEXTUAL)
  .fontColor($r('sys.color.font_emphasize'))
  .width(Constants.HALF_LENGTH)
}

@Extend(Text)function titleText() {
  .fontWeight(FontWeight.Bold)
  .fontColor($r('sys.color.font_primary'))
  .textAlign(TextAlign.Center)
  .textOverflow({ overflow: TextOverflow.Ellipsis })
  .maxLines(Constants.SECURITY_HEADER_MAX_LINES)
}

const fuzzyMarks = [Constants.LOCATION_FUZZY, Constants.LOCATION_BOTH_FUZZY, Constants.LOCATION_BOTH_PRECISE];
const preciseMarks = [Constants.LOCATION_UPGRADE, Constants.LOCATION_BOTH_PRECISE];
let storage = LocalStorage.getShared();

@Entry(storage)
@Component
struct dialogPlusPage {
  @LocalStorageLink('want') want: WantInfo = new WantInfo([]);
  @LocalStorageLink('win') win: window.Window = {} as window.Window;
  private context = getContext(this) as common.ServiceExtensionContext;
  @State count: number = 0;
  @State result: Array<number> = [];
  @State accessTokenId: number = 0;
  @State initStatus: number = Constants.INIT_NEED_TO_WAIT;
  @State reqPerms: Array<Permission> = [];
  @State grantGroups: Array<GroupInfo> = [];
  @State userFixedFlag: number = 2; // means user fixed
  @State grantStatus: number = -1;
  @State appName: string = '';
  @State locationFlag: number = Constants.LOCATION_NONE;
  @State reqPermissionDetails: bundleManager.ReqPermissionDetail[] = [];
  @State refresh: number = 0;
  @State pasteBoardName: string = '';
  @State isUpdate: number = -1;

  dialogController: CustomDialogController | null = new CustomDialogController({
    builder: CustomContentDialog({
      contentBuilder: () => {
        this.buildContent();
      },
      contentAreaPadding: { right: 0 }
    }),
    autoCancel: false
  });

  @Builder
  DialogTitle() {
    Row() {
      Column() {
        if (getFontSizeScale()) {
          Text($r(this.showTitle(), this.appName))
            .titleText()
            .fontSize($r('sys.float.Title_S'))
        } else {
          Text($r(this.showTitle(), this.appName))
            .titleText()
            .minFontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
            .maxFontSize($r('sys.float.Title_S'))
            .heightAdaptivePolicy(TextHeightAdaptivePolicy.MIN_FONT_SIZE_FIRST)
        }
      }
      .constraintSize({ minHeight: Constants.HEADLINE_HEIGHT })
      .justifyContent(FlexAlign.Center)
      .padding({
        top: Constants.DEFAULT_PADDING_TOP,
        bottom: Constants.DEFAULT_PADDING_BOTTOM,
        left: Constants.PADDING_24,
        right: Constants.PADDING_24
      })
    }
  }

  @Builder
  buildContent(): void {
    Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
      Column() {
        if ((this.initStatus != Constants.INIT_NEED_TO_WAIT) && this.verify()) {
          Image(this.currentGroup().icon)
            .width(Constants.DIALOG_ICON_WIDTH)
            .height(Constants.DIALOG_ICON_HEIGHT)
            .fillColor($r('sys.color.font_primary'))
            .margin({ top: Constants.DIALOG_ICON_MARGIN_TOP })
          if (this.grantGroups.length > 1) {
            Text(`${this.count + 1} / ${this.grantGroups.length}`)
              .fontSize(Constants.DIALOG_LABEL_FONT_SIZE)
              .fontColor($r('sys.color.font_secondary'))
              .lineHeight(Constants.DIALOG_LABEL_LINE_HEIGHT)
              .margin({ top: Constants.DIALOG_LABEL_MARGIN_TOP })
          }
          Scroll() {
            Column() {
              this.DialogTitle();

              Row() {
                Flex({ justifyContent: FlexAlign.Center }) {
                  Text() {
                    if (
                      this.currentGroup().name === 'LOCATION' &&
                      ((this.locationFlag == Constants.LOCATION_FUZZY) ||
                      (this.locationFlag == Constants.LOCATION_BOTH_FUZZY))
                    ) {
                      Span($r('app.string.close_exact_position'))
                    } else if (this.currentGroup().name === 'PASTEBOARD') {
                      if (this.pasteBoardName) {
                        Span($r('app.string.pasteBoard_app', this.pasteBoardName))
                      } else {
                        Span($r('app.string.pasteBoard_desc'))
                      }
                    } else {
                      if (this.currentGroup().description.length > 0) {
                        ForEach(this.currentGroup().description, (item: ResourceStr) => {
                          Span(item)
                        })
                        Span(this.currentGroup().reason ? $r('app.string.comma') : $r('app.string.period'))
                      }
                      Span(this.refresh >= 0 ? this.currentGroup().reason : '')
                    }
                  }
                  .textAlign(TextAlign.Start)
                  .fontColor($r('sys.color.font_primary'))
                  .fontSize($r('sys.float.Body_L'))
                  .maxFontScale(Constants.DIALOG_TEXT_MAX_SCALE)
                  .margin({
                    left: Constants.DIALOG_DESP_MARGIN_LEFT,
                    right: Constants.DIALOG_DESP_MARGIN_RIGHT,
                    bottom: Constants.DIALOG_DESP_MARGIN_BOTTOM
                  })
                }
              }

              if (this.locationFlag > Constants.LOCATION_NONE && this.currentGroup().name === 'LOCATION') {
                LocationCanvas({ locationFlag: $locationFlag })
              }
            }
          }.constraintSize({ maxHeight: Constants.MAXIMUM_HEADER_HEIGHT })
          if (this.currentGroup().buttons.length <= 2 && this.calculateButtonWidth(this.currentGroup().buttons)) {
            //横向布局
            Row() {
              Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
                Button(buttonResource.get(this.currentGroup().buttons[0]))
                  .customizeButton()
                  .onClick(() => {
                    this.clickHandle(this.currentGroup().buttons[0]);
                  })
                Divider()
                  .color($r('sys.color.comp_divider'))
                  .vertical(true)
                  .strokeWidth(Constants.DIALOG_DIVIDER)
                  .height(Constants.DIVIDER_HEIGHT)
                  .opacity(0.2)
                  .margin({ left: Constants.MARGIN_8, right: Constants.MARGIN_8 })
                Button(buttonResource.get(this.currentGroup().buttons[1]))
                  .customizeButton()
                  .onClick(() => {
                    this.clickHandle(this.currentGroup().buttons[1]);
                  })
              }.margin({
                left: Constants.BUTTON_MARGIN_LEFT,
                right: Constants.BUTTON_MARGIN_RIGHT,
                bottom: Constants.MARGIN_8
              })
            }
          } else {
            //纵向布局
            Column() {
              ForEach(this.currentGroup().buttons, (buttonStatus: ButtonStatus, idx: number) => {
                Button(buttonResource.get(buttonStatus))
                  .customizeButton()
                  .width(Constants.FULL_WIDTH)
                  .margin({ bottom: idx + 1 < this.currentGroup().buttons.length ? Constants.MARGIN_4 : 0 })
                  .onClick(() => {
                    this.clickHandle(buttonStatus);
                  })
              })
            }
            .padding({ left: Constants.PADDING_16, right: Constants.PADDING_16 })
          }
        }
      }
      .padding({ bottom: Constants.PADDING_8 })
      .clip(true)
    }
  }

  build() {}

  showTitle(): string {
    let index = this.count >= this.grantGroups.length ? this.grantGroups.length - 1 : this.count;
    if (this.grantGroups[index].name == 'LOCATION') {
      if (this.locationFlag == Constants.LOCATION_FUZZY) {
        return 'app.string.access_general_location';
      }
      if (this.locationFlag == Constants.LOCATION_UPGRADE) {
        return 'app.string.fuzzy_to_exact';
      }
    }
    return this.grantGroups[index].label;
  }

  currentGroup(): GroupInfo {
    let index = this.count >= this.grantGroups.length ? this.grantGroups.length - 1 : this.count;
    return this.grantGroups[index];
  }

  calculateButtonWidth(buttonStatus: ButtonStatus[]): boolean {
    let denyText = buttonResource.get(buttonStatus[0]);
    let allowText = buttonResource.get(buttonStatus[1]);
    let maxButtonTextLength = Math.max(
      MeasureText.measureText({ textContent: denyText }),
      MeasureText.measureText({ textContent: allowText })
    )

    Log.info(`px2vp(maxButtonTextLength): ${px2vp(maxButtonTextLength)}`);
    if (px2vp(maxButtonTextLength) > Constants.DIALOG_BUTTON_MAX_WIDTH) {
      return false;
    }

    return true;
  }

  clickHandle(buttonStatus: ButtonStatus) {
    switch (buttonStatus) {
      case ButtonStatus.ALLOW:
        this.privacyAccept(this.grantGroups[this.count], this.accessTokenId, this.reqPerms, this.userFixedFlag);
        return;
      case ButtonStatus.DENY:
        this.privacyCancel(this.grantGroups[this.count], this.accessTokenId, this.reqPerms, this.userFixedFlag);
        return;
      case ButtonStatus.CANCEL:
        this.count ++;
        return;
      case ButtonStatus.THIS_TIME_ONLY:
        this.privacyAccept(
          this.grantGroups[this.count], this.accessTokenId, this.reqPerms, Constants.PERMISSION_ALLOW_THIS_TIME
        );
        return;
      case ButtonStatus.ALLOW_THIS_TIME:
        this.privacyAccept(
          this.grantGroups[this.count], this.accessTokenId, this.reqPerms, Constants.PERMISSION_ALLOW_THIS_TIME
        );
        return;
      case ButtonStatus.ALLOW_ONLY_DURING_USE:
        this.privacyAccept(this.grantGroups[this.count], this.accessTokenId, this.reqPerms, this.userFixedFlag);
        return;
    }
  }

  async privacyAccept(group: GroupInfo, accessTokenId: number, permissionList: string[], userFixedFlag: number) {
    let num = 0;
    group.permissions.forEach(async permission => {
      this.grantStatus = -1;
      if (showSubPermissionsGroup.indexOf(group.name) == -1) {
        if (group.name == 'LOCATION') {
          if (fuzzyMarks.includes(this.locationFlag) && permission === Permission.APPROXIMATELY_LOCATION) {
            await this.operationPermission(true, accessTokenId, permission, userFixedFlag);
          }
          if (preciseMarks.includes(this.locationFlag) && permission === Permission.LOCATION) {
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
        await this.operationPermission(false, accessTokenId, permission, userFixedFlag);
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

  aboutToAppear() {
    this.count = 0;
    this.initStatus = Constants.INIT_NEED_TO_WAIT;
    this.result = [];
    this.reqPerms = this.want.parameters['ohos.user.grant.permission'];
    this.accessTokenId = this.want.parameters['ohos.aafwk.param.callerToken'];
    if (this.reqPerms == undefined || this.accessTokenId == undefined || this.reqPerms.length == 0) {
      Log.info('invalid parameters');
      this.initStatus = Constants.INIT_NEED_TO_TERMINATED;
      return;
    }
    Log.info(`request permission: ${JSON.stringify(this.reqPerms)}.`);
    Log.info('permission state=' + JSON.stringify(this.want.parameters['ohos.user.grant.permission.state']));
    this.result = new Array(this.reqPerms.length).fill(-1);
    this.getPasteBoardInfo();
    let bundleName: string = this.want.parameters['ohos.aafwk.param.callerBundleName'];
    try {
      bundleManager.getBundleInfo(bundleName, bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_REQUESTED_PERMISSION)
        .then(bundleInfo => {
          this.reqPermissionDetails = bundleInfo.reqPermissionDetails;
          this.getGrantGroups(this.want.parameters['ohos.user.grant.permission.state']);
          this.getApplicationName(bundleName);
          this.dialogController?.open();
        }).catch((err: BusinessError) => {
          Log.error('getBundleInfo error :' + JSON.stringify(err));
          this.initStatus = Constants.INIT_NEED_TO_TERMINATED;
        })
    } catch (err) {
      Log.error('getBundleInfo error :' + JSON.stringify(err));
      this.initStatus = Constants.INIT_NEED_TO_TERMINATED;
    }
  }

  aboutToDisappear() {
    this.dialogController = null;
  }

  onPageShow() {
    if (this.isUpdate > 0) {
      this.getApplicationName(this.want.parameters['ohos.aafwk.param.callerBundleName'])
    }
    this.isUpdate ++;
  }

  getPasteBoardInfo() {
    if (this.reqPerms.includes(Permission.READ_PASTEBOARD)) {
      let systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
      this.pasteBoardName = systemPasteboard.getDataSource();
    }
  }

  getGrantGroups(stateGroup: number[]) {
    if (this.reqPerms.includes(Permission.APPROXIMATELY_LOCATION)) {
      this.locationFlag = Constants.LOCATION_FUZZY;
      if (this.reqPerms.includes(Permission.LOCATION)) {
        this.locationFlag = Constants.LOCATION_BOTH_PRECISE;
        let fuzzyIndex = this.reqPerms.indexOf(Permission.APPROXIMATELY_LOCATION);
        if (stateGroup[fuzzyIndex] == Constants.PASS_OPER) {
          this.locationFlag = Constants.LOCATION_UPGRADE;
        }
      }
    } else if (this.reqPerms.includes(Permission.LOCATION)) {
      this.locationFlag = Constants.LOCATION_UPGRADE;
    }

    this.reqPerms.forEach(async (permission, idx) => {
      if (permission === Permission.APP_TRACKING_CONSENT) {
        let toggleStatus = await this.appTrackHandle(idx);
        if (toggleStatus === abilityAccessCtrl.PermissionRequestToggleStatus.CLOSED) {
          return;
        }
      }
      if (stateGroup[idx] == Constants.PASS_OPER) {
        Log.info('permission has been fixed:' + permission);
        this.result[idx] = abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
      } else if (stateGroup[idx] == Constants.DYNAMIC_OPER) {
        let supportPermissions = supportPermission();
        if (!supportPermissions.includes(permission)) {
          Log.info('The permission does not exist or is not supported by the current device: ' + permission);
        } else {
          this.addGroup(permission);
        }
      }
    })
    this.initStatus = Constants.INIT_NEED_TO_VERIFY;
  }

  async appTrackHandle(index: number): Promise<abilityAccessCtrl.PermissionRequestToggleStatus> {
    try {
      let acManager = abilityAccessCtrl.createAtManager();
      let toggleStatus = await acManager.getPermissionRequestToggleStatus(Permission.APP_TRACKING_CONSENT);
      Log.info(`APP_TRACKING_CONSENT toggleStatus: ${toggleStatus}.`);
      if (toggleStatus === abilityAccessCtrl.PermissionRequestToggleStatus.CLOSED) {
        await acManager.grantUserGrantedPermission(
          this.accessTokenId, Permission.APP_TRACKING_CONSENT, this.userFixedFlag
        );
        this.result[index] = abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
        Log.info('APP_TRACKING_CONSENT grant success.');
      }
      return toggleStatus;
    } catch (err) {
      Log.error(`APP_TRACKING_CONSENT getToggleStatus or grant fail: ${JSON.stringify(err)}`);
      return abilityAccessCtrl.PermissionRequestToggleStatus.OPEN;
    }
  }

  addGroup(permission: Permission) {
    let group = getPermissionGroup(permission);
    if (group.name === 'FOLDER') {
      switch (permission) {
        case Permission.READ_WRITE_DOWNLOAD_DIRECTORY:
          let downloadGroup = new GroupInfo(
            group.name, group.groupName, 'app.string.group_label_download_folder', group.icon, group.description,
            group.reason, [Permission.READ_WRITE_DOWNLOAD_DIRECTORY], group.buttons, group.isShow
          )
          this.grantGroups.push(downloadGroup);
          break;
        case Permission.READ_WRITE_DESKTOP_DIRECTORY:
          let desktopGroup = new GroupInfo(
            group.name, group.groupName, 'app.string.group_label_desktop_folder', group.icon, group.description,
            group.reason, [Permission.READ_WRITE_DESKTOP_DIRECTORY], group.buttons, group.isShow
          )
          this.grantGroups.push(desktopGroup);
          break;
        case Permission.READ_WRITE_DOCUMENTS_DIRECTORY:
          let documentGroup = new GroupInfo(
            group.name, group.groupName, 'app.string.group_label_document_folder', group.icon, group.description,
            group.reason, [Permission.READ_WRITE_DOCUMENTS_DIRECTORY], group.buttons, group.isShow
          )
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
      group.reason = '';
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
    Promise.all([
      data.writeInterfaceToken(Constants.ACCESS_TOKEN),
      data.writeStringArray(perms),
      data.writeIntArray(results),
      setDialogData.writeInterfaceToken(Constants.ACCESS_TOKEN),
    ]).then(() => {
      let proxy = this.want.parameters['ohos.ability.params.callback'].value as rpc.RemoteObject;
      proxy.sendMessageRequest(Constants.RESULT_CODE, data, reply, option);
      proxy.sendMessageRequest(Constants.RESULT_CODE_1, setDialogData, reply, option);
    }).catch(() => {
      Log.error('write result failed!');
    }).finally(() => {
      data.reclaim();
      reply.reclaim();
      setDialogData.reclaim();
      this.destruction();
    })
  }

  destruction() {
    let windowNum: number = GlobalContext.load('windowNum');
    windowNum --;
    Log.info('windowNum:' + windowNum);
    GlobalContext.store('windowNum', windowNum);
    this.win.destroyWindow();
    if (windowNum == 0) {
      this.context.terminateSelf();
    }
  }
}
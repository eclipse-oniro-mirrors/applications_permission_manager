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

import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import bundleManager from '@ohos.bundle.bundleManager';
import rpc from '@ohos.rpc';
import window from '@ohos.window';
import { Log, getPermissionGroup, titleTrim, getPermissionLabel } from '../common/utils/utils';
import Constants from '../common/utils/constant';
import { showSubpermissionsGrop } from '../common/model/permissionGroup';
import { LocationCanvas } from '../common/components/location';

@Extend(Button) function customizeButton() {
  .backgroundColor($r('sys.color.ohos_id_color_dialog_bg'))
  .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
  .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
  .fontWeight(FontWeight.Medium)
  .height(Constants.BUTTON_HEIGHT)
  .flexGrow(Constants.FLEX_GROW)
}

const FUZZY_LOCATION_PERMISSION = 'ohos.permission.APPROXIMATELY_LOCATION';
const PRECISE_LOCATION_PERMISSION = 'ohos.permission.LOCATION';

let win: any = "";
let proxy: any = '';
let want: any = '';
let storage = LocalStorage.GetShared();

class BundleInfo {
  targetVersion: number
  reqPermissionDetails: Array<any>
  constructor(targetVersion: number, reqPermissionDetails: Array<any>) {
    this.targetVersion = targetVersion
    this.reqPermissionDetails = reqPermissionDetails
  }
}

@Entry(storage)
@Component
struct dialogPlusPage {
  @LocalStorageLink('want') want: Object = {};
  @LocalStorageLink('win') win: Object = {};
  @State isUpdate: number = -1;

  privacyDialogController: CustomDialogController = new CustomDialogController({
    builder: PermissionDialog({ isUpdate: $isUpdate }),
    autoCancel: false,
    alignment: DialogAlignment.Center,
    customStyle: true
  })

  build() {}

  aboutToAppear() {
    win = this.win
    want = this.want
    this.privacyDialogController.open();
  }

  onPageShow() {
    this.isUpdate ++;
  }
}

@CustomDialog
struct PermissionDialog {
  @State count: number = 0;
  @State result: Array<any> = [];
  @State accessTokenId: number = 0;
  @State initStatus: number = Constants.INIT_NEED_TO_WAIT;
  @State reqPerms: Array<string> = [];
  @State grantGroups: Array<any> = [];
  @State userFixedFlag: number = 2; // means user fixed
  @State appName: string = "";
  @State locationFlag: number = Constants.LOCATION_NONE;
  @State bundleInfo: BundleInfo = new BundleInfo(0, []);
  @State naviHeight: number = 0
  @State refresh: number = 0;
  @Link @Watch('updateReason') isUpdate: number;
  controller: CustomDialogController

  build() {
    GridRow({ columns: { xs: Constants.XS_COLUMNS, sm: Constants.SM_COLUMNS, md: Constants.MD_COLUMNS, lg: Constants.LG_COLUMNS }, gutter: Constants.DIALOG_GUTTER }) {
      GridCol({ span: { xs: Constants.XS_SPAN, sm: Constants.SM_SPAN, md: Constants.DIALOG_MD_SPAN, lg: Constants.DIALOG_LG_SPAN },
        offset: {xs: Constants.XS_OFFSET, sm: Constants.SM_OFFSET, md: Constants.DIALOG_MD_OFFSET, lg: Constants.DIALOG_LG_OFFSET} }) {
        Flex({ justifyContent: FlexAlign.Center, alignItems: globalThis.isBottomPopover ? ItemAlign.End : ItemAlign.Center }) {
          Column() {
            if ((this.initStatus != Constants.INIT_NEED_TO_WAIT) && this.verify()) {
              Image(this.grantGroups[this.count >= this.grantGroups.length ? this.grantGroups.length - 1 : this.count].icon)
                .width(Constants.DIALOG_ICON_WIDTH)
                .height(Constants.DIALOG_ICON_HEIGHT)
                .fillColor($r("sys.color.ohos_id_color_text_primary"))
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
                        Span($r("app.string.quotes"))
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
                        if (this.showReason()) {
                          Span($r('app.string.close_exact_position'))
                        } else {
                          if (this.grantGroups[this.count >= this.grantGroups.length ? this.grantGroups.length - 1 : this.count].description) {
                            ForEach(this.grantGroups[this.count >= this.grantGroups.length ? this.grantGroups.length - 1 : this.count].description, item => {
                              Span(item)
                            })
                            Span(this.grantGroups[this.count >= this.grantGroups.length ? this.grantGroups.length - 1 : this.count].reason ? $r("app.string.comma") : $r("app.string.period"))
                          }
                          Span(this.grantGroups[this.count >= this.grantGroups.length ? this.grantGroups.length - 1 : (this.count + this.refresh - this.refresh)].reason)
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

                  if (this.locationFlag > Constants.LOCATION_NONE && this.grantGroups[this.count >= this.grantGroups.length ? this.grantGroups.length - 1 : this.count].name === 'LOCATION') {
                    LocationCanvas({ locationFlag: $locationFlag })
                  }
                }
              }.constraintSize({ maxHeight: Constants.MAXIMUM_HEADER_HEIGHT })
              Row() {
                Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
                  Button($r('app.string.BAN'))
                    .onClick(() => {
                      this.privacyCancel(this.grantGroups[this.count], this.accessTokenId, this.reqPerms, this.userFixedFlag)
                    }).customizeButton()
                  Divider()
                    .color($r('sys.color.ohos_id_color_list_separator'))
                    .vertical(true)
                    .height(Constants.DIVIDER_HEIGHT)
                    .opacity(.2)
                  Button($r('app.string.ALLOW'))
                    .onClick(() => {
                      this.privacyAccept(this.grantGroups[this.count], this.accessTokenId, this.reqPerms, this.userFixedFlag)
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
    }.margin({ left: globalThis.isBottomPopover ? Constants.DIALOG_MARGIN_VERTICAL : Constants.DIALOG_MARGIN,
      right: globalThis.isBottomPopover ? Constants.DIALOG_MARGIN_VERTICAL : Constants.DIALOG_MARGIN,
      bottom: globalThis.isBottomPopover ? this.naviHeight : 0})
  }

  showTitle() {
    let index = this.count >= this.grantGroups.length ? this.grantGroups.length - 1 : this.count;
    if (this.grantGroups[index].name == 'LOCATION') {
      if (this.locationFlag == Constants.LOCATION_FUZZY) {
        return $r("app.string.access_general_location");
      }
      if (this.locationFlag == Constants.LOCATION_UPGRADE) {
        return $r("app.string.fuzzy_to_exact");
      }
    }
    return this.grantGroups[index].label;
  }

  showReason() {
    let index = this.count >= this.grantGroups.length ? this.grantGroups.length - 1 : this.count;
    if (this.grantGroups[index].name == 'LOCATION') {
      if ((this.locationFlag == Constants.LOCATION_FUZZY) || (this.locationFlag == Constants.LOCATION_BOTH_FUZZY)) {
        return true;
      }
    }
    return false;
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
    var ret: number = Constants.RESULT_SUCCESS;
    if (this.initStatus == Constants.INIT_NEED_TO_TERMINATED) {
      ret = Constants.RESULT_FAILURE;
    }
    this.answer(ret, this.reqPerms);
  }

  answer(ret, reqPerms) {
    Log.info("code:" + ret + ", perms="+ JSON.stringify(reqPerms) +", result=" + JSON.stringify(this.result));
    var perms = [];
    var results = [];
    reqPerms.forEach(perm => {
      perms.push(perm);
    })
    this.result.forEach(result => {
      results.push(result);
    })
    let option = new rpc.MessageOption();
    let data = new rpc.MessageSequence();
    let reply = new rpc.MessageSequence();
    Promise.all([data.writeInterfaceToken(Constants.ACCESS_TOKEN),
      data.writeStringArray(perms),
      data.writeIntArray(results)
    ]).then(() => {
      proxy.sendRequest(Constants.RESULT_CODE, data, reply, option);
      this.destruction();
    }).catch(() => {
      Log.error('write result failed!');
      this.destruction();
    })
  }

  destruction() {
    win.destroy();
    globalThis.windowNum --;
    Log.info("windowNum:" + globalThis.windowNum);
    if (globalThis.windowNum == 0) {
      globalThis.extensionContext.terminateSelf();
    }
  }

  async privacyAccept(group, accessTokenId, permissionList, userFixedFlag) {
    var acManager = abilityAccessCtrl.createAtManager();
    var num = 0;
    group.permissions.forEach(async permission => {
      let result;
      if (showSubpermissionsGrop.indexOf(group.name) == -1) {
        if (group.name == 'LOCATION' && this.bundleInfo.targetVersion >= Constants.API_VERSION_SUPPORT_STAGE) {
          if (!(((this.locationFlag == Constants.LOCATION_BOTH_FUZZY) || (this.locationFlag == Constants.LOCATION_FUZZY))
            && (permission == PRECISE_LOCATION_PERMISSION))) {
            try {
              await acManager.grantUserGrantedPermission(accessTokenId, permission, userFixedFlag).then(() => {
                result = abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
              })
            }
            catch(err) {
              Log.error("failed to grant permission:" + permission + " ret:" + result);
            }
          }
        } else {
          try {
            await acManager.grantUserGrantedPermission(accessTokenId, permission, userFixedFlag).then(() => {
              result = abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
            })
          }
          catch(err) {
            Log.error("failed to grant permission:" + permission + " ret:" + result);
          }
        }
      } else {
        if (permissionList.includes(permission)) {
          try {
            await acManager.grantUserGrantedPermission(accessTokenId, permission, userFixedFlag).then(() => {
              result = abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
            })
          }
          catch(err) {
            Log.error("failed to grant permission:" + permission + " ret:" + result);
          }
        }
      }
      num ++;
      Log.info("grant permission result:" + result + "permission" + permission);
      if (result == abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        permissionList.forEach((req, idx) => {
          if (req == permission) {
            this.result[idx] = abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
          }
        })
        Log.info("grant permission success:" + permission);
      } else {
        Log.error("failed to grant permission:" + permission + " ret:" + result);
      }
      if (num == group.permissions.length) {
        this.count ++;
      }
    })
  }

  async privacyCancel(group, accessTokenId, permissionList, userFixedFlag) {
    var acManager = abilityAccessCtrl.createAtManager();
    group.permissions.forEach(async permission => {
      if (showSubpermissionsGrop.indexOf(group.name) == -1) {
        if (!(this.locationFlag == Constants.LOCATION_UPGRADE && group.name == 'LOCATION') || permission == PRECISE_LOCATION_PERMISSION) {
          try {
            await acManager.revokeUserGrantedPermission(accessTokenId, permission, userFixedFlag);
          }
          catch(err) {
            Log.error("failed to revoke permission:" + permission);
          }
        }
      } else {
        if (permissionList.includes(permission)) {
          try {
            await acManager.revokeUserGrantedPermission(accessTokenId, permission, userFixedFlag);
          }
          catch(err) {
            Log.error("failed to revoke permission:" + permission);
          }
        }
      }
      Log.info("revoke permission " + permission);
    })
    this.count ++;
  }

  getgrantGroups(stateGroup) {
    //Processing of positioning
    if (this.bundleInfo.targetVersion >= Constants.API_VERSION_SUPPORT_STAGE) {
      if (this.reqPerms.includes(FUZZY_LOCATION_PERMISSION)) {
        this.locationFlag = Constants.LOCATION_FUZZY;
        if (this.reqPerms.includes(PRECISE_LOCATION_PERMISSION)) {
          this.locationFlag = Constants.LOCATION_BOTH_PRECISE;
          var fuzzyIndex = this.reqPerms.indexOf(FUZZY_LOCATION_PERMISSION);
          if (stateGroup[fuzzyIndex] == Constants.PASS_OPER) {
            this.locationFlag = Constants.LOCATION_UPGRADE;
          }
        }
      }
    }

    this.reqPerms.forEach((permission, idx) => {
      //已授权
      if (stateGroup[idx] == Constants.PASS_OPER) {
        Log.info("permission has been fixed:" + permission);
        this.result[idx] = abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
        //待授权
      } else if (stateGroup[idx] == Constants.DYNAMIC_OPER) {
        var group = getPermissionGroup(permission);
        if (!group) {
          Log.info("permission not find:" + permission);
        } else {
          var exist = this.grantGroups.find(grantGroup => grantGroup.name == group.name);
          //判断是否为需要展示子权限的权限组
          if (showSubpermissionsGrop.indexOf(group.name) != -1) {
            let label = getPermissionLabel(permission)
            if (!exist) {
              group.description = [label];
              this.grantGroups.push(group);
            } else {
              if (exist.description.indexOf(label) == -1) {
                exist.description.push($r("app.string.and"));
                exist.description.push(label);
              }
            }
          } else {
            if (!exist) {
              this.grantGroups.push(group);
            }
          }
        }
      }
    })
    this.initStatus = Constants.INIT_NEED_TO_VERIFY;
  }

  getApplicationName(bundleName) {
    Log.info("getApplicationName bundleName:" + bundleName);
    bundleManager.getApplicationInfo(bundleName, bundleManager.ApplicationFlag.GET_APPLICATION_INFO_DEFAULT).then(applicationInfo => {
      let context = globalThis.extensionContext.createBundleContext(bundleName);
      context.resourceManager.getString(applicationInfo.labelId, (err, value) => {
        if (value == undefined) {
          this.appName = titleTrim(applicationInfo.label);
        } else {
          this.appName = titleTrim(value);
        }
        Log.info("hap label:" + applicationInfo.label + ", value:"+this.appName);
      })
    }).catch(err => {
      Log.error("applicationInfo error :" + err);
      this.initStatus = Constants.INIT_NEED_TO_TERMINATED;
    })
    this.grantGroups.forEach((group) => {
      group.hasReason = false;
      this.getReason(group, bundleName);
    })
  }

  getReason(group, bundleName) {
    group.permissions.forEach(permission => {
      if (this.reqPerms.indexOf(permission) != -1) {
        this.bundleInfo.reqPermissionDetails.forEach(reqPermissionDetail => {
          if (reqPermissionDetail.name == permission) {
            Log.info("reqPermissionDetail: " + JSON.stringify(reqPermissionDetail));
            let context = globalThis.extensionContext.createModuleContext(bundleName, reqPermissionDetail.moduleName);
            context.resourceManager.getString(reqPermissionDetail.reasonId, (err, value) => {
              if (value !== undefined && !group.hasReason) {
                group.reason = value.slice(Constants.START_SUBSCRIPT, Constants.END_SUBSCRIPT);
                group.hasReason = true;
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
    proxy = want.parameters['ohos.ability.params.callback'].value;
    if (this.reqPerms == undefined || this.accessTokenId == undefined || this.reqPerms.length == 0) {
      Log.info("invalid parameters");
      this.initStatus = Constants.INIT_NEED_TO_TERMINATED;
      return;
    }
    Log.info("request permission=" + JSON.stringify(this.reqPerms) + ", tokenId = " + this.accessTokenId);
    Log.info("permission state=" + JSON.stringify(want.parameters['ohos.user.grant.permission.state']));
    this.result = new Array(this.reqPerms.length).fill(-1);
    this.getAvoidWindow();
    let uid = want.parameters['ohos.aafwk.param.callerUid'];
    bundleManager.getBundleNameByUid(uid).then((data) => {
      bundleManager.getBundleInfo(data, bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_REQUESTED_PERMISSION).then(bundleInfo => {
        this.bundleInfo = bundleInfo;
        this.getgrantGroups(want.parameters['ohos.user.grant.permission.state']);
        this.getApplicationName(data);
      }).catch(err => {
        Log.error("getBundleInfo error :" + JSON.stringify(err));
        this.initStatus = Constants.INIT_NEED_TO_TERMINATED;
      })
    }).catch(err => {
      Log.error("getNameForUid error :" + JSON.stringify(err));
      this.initStatus = Constants.INIT_NEED_TO_TERMINATED;
    })
  }
}


/*
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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
import Constants from '../common/utils/constant';
import common from '@ohos.app.ability.common';
import { BusinessError } from '@ohos.base';
import {
  checkPermissionGroup,
  getGroupIdByPermission, getPermissionLabel, Log,
  PermissionDialogException,
  PermissionDialogReturn,
  verifyAccessToken } from '../common/utils/utils';
import { AppInfo, CallerBundleInfo,
  CheckboxInfo,
  MediaDocObj,
  WantInfo } from '../common/model/typedef';
import { GlobalContext } from '../common/utils/globalContext';
import { Permission, PermissionGroup } from '../common/model/definition';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import { groups, showSubPermissionsGroup } from '../common/model/permissionGroup';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import { CustomContentDialog } from '@ohos.arkui.advanced.Dialog'

let accessTokenId: number = 0;
let session: UIExtensionContentSession;
let results: Map<string, number> = new Map();
let terminating: boolean = false;

export function ReportDialogResult(wantPermissions: Permissions[]) {
  let resultArray: number[] = [];
  Log.info('processed result:' + JSON.stringify(results));
  for (const permission of wantPermissions) {
    // check if corresponding result is set
    if (results.has(permission)) {
      resultArray.push(results.get(permission)!);
    } else {
      Log.error(permission + ' is not processed!');
      resultArray.push(Constants.ERR_PERMISSION_GRANT_EXCEPTION);
    }
  }
  Log.info('terminating session with return array ' + JSON.stringify(resultArray));
  PermissionDialogReturn(resultArray, session);
}

export function getCallerBundleInfo(want: WantInfo): CallerBundleInfo {
  let bundleName: string = want.parameters['ohos.aafwk.param.callerBundleName'];
  let uId: number = want.parameters['ohos.aafwk.param.callerUid'] ?? 0;
  let token: number = want.parameters['ohos.aafwk.param.callerToken'] ?? 0;
  let permissions: Permissions[] = want.parameters['ohos.user.setting.permission'];
  let globSwitch: number = want.parameters['ohos.user.setting.global_switch'];

  const callerBundle: CallerBundleInfo = {
    bundleName: bundleName,
    uId: uId,
    permissionGroup: permissions,
    token: token,
    globSwitch: globSwitch
  }

  return callerBundle;
}

@Entry({ useSharedStorage: true })
@Component
struct PermissionStateSheetDialog {
  private context = this.getUIContext().getHostContext() as common.ServiceExtensionContext;
  @LocalStorageLink('want') want: Want | null = null;
  @LocalStorageLink('session') session: UIExtensionContentSession = {} as UIExtensionContentSession;
  @State applicationInfo: AppInfo | undefined = undefined;
  @State folderStatus: boolean[] = [false, false, false];
  @State reqUserPermissions: Permission[] = [];
  @State bundleName: string = '';
  @State isGranted: number = Constants.PERMISSION_ALLOW;
  @State groupName: ResourceStr = '';
  @State currentGroup: PermissionGroup = PermissionGroup.OTHER;

  dialogController: CustomDialogController | null = new CustomDialogController({
    builder: CustomContentDialog({
      contentBuilder: () => {
        this.buildDialog();
      },
      contentAreaPadding: {left: 0, right: 0}
    }),
    offset: { dx: 0, dy: `-${GlobalContext.load('avoidAreaHeight') as string}` }, // unit included in globalContext
    alignment: DialogAlignment.Bottom,
    customStyle: false,
    isModal: true,
    width: '100%',
    autoCancel: false,
    cornerRadius: {topLeft: 32, topRight: 32, bottomLeft: 0, bottomRight: 0},
    cancel: () => {
      ReportDialogResult(this.reqUserPermissions);
      this.context.terminateSelf();
      this.dialogController?.close();
    }
  });

  @Builder
  buildDialog() {
    mediaDocumentItem({
      bundleName: this.bundleName,
      backTitle: this.groupName,
      permissions: this.reqUserPermissions,
      status: this.isGranted,
      tokenId: this.applicationInfo?.tokenId,
      applicationInfo: this.applicationInfo,
      currentGroup: this.currentGroup
    })
  }

  build() {

  }

  async aboutToAppear() {
    session = this.session;
    await this.GetAppInfo();

    if (!this.applicationInfo) {
      this.context.terminateSelf();
    }

    if (this.dialogController !== null && terminating == false) {
      this.dialogController.open();
    }
  }

  async getSpecifiedApplication(bundleName: string): Promise<AppInfo | undefined> {
    const flag =
      bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION |
      bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_REQUESTED_PERMISSION;
    let promise = new Promise<AppInfo | undefined>(async (resolve, reject) => {
      try {
        let info = await this.getBundleInfo(bundleName, flag);
        resolve(info);
      } catch (e) {
        resolve(undefined);
      }
    })
    return promise;
  }

  async getBundleInfo(bundleName: string, flag: number): Promise<AppInfo | undefined> {
    return new Promise<AppInfo | undefined>(async (resolve, reject) => {
      let info: AppInfo | undefined = undefined;
      let permissionGrantMap: Map<string, number> = new Map();
      let bundleInfo = await bundleManager.getBundleInfo(bundleName, flag);
      let appPermissions = bundleInfo.reqPermissionDetails;
      let granted = bundleInfo.permissionGrantStates;
      info = new AppInfo(bundleInfo.name, bundleInfo.targetVersion,
        bundleInfo.appInfo.accessTokenId, '', bundleInfo.appInfo.iconId, bundleInfo.appInfo.iconResource,
        '', bundleInfo.appInfo.labelId, bundleInfo.appInfo.labelResource, [], [], '', '', ''
      );
      resolve(info);
      // check if all permissions passed from want has been claimed by app config
      for (const wantPermission of this.reqUserPermissions) {
        if (terminating) {
          continue;
        }
        let idx = appPermissions.findIndex((item) => {
          return item.name == wantPermission;
        });
        if (idx == -1) {
          Log.error('permission ' + wantPermission + ' not claimed by ' + this.bundleName + ' in module.json');
          PermissionDialogException(Constants.ERR_PERMISSIONS_NOT_IN_CONFIG, session);
          terminating = true;
          this.context.terminateSelf();
          return;
        }
        permissionGrantMap.set(appPermissions[idx].name, granted[idx]);
      }
      // check if all permissions are already granted
      let permissionsAllGranted = true;
      for (const key of permissionGrantMap.keys()) {
        if (permissionGrantMap.get(key) === -1) { // -1 means not granted
          permissionsAllGranted = false;
        }
      }
      // check if all permissions are already granted
      if (permissionsAllGranted) {
        Log.error('terminating : ' + terminating + ' requested permissions are all already granted');
        if (terminating == false) {
          PermissionDialogException(Constants.ERR_PERMISSIONS_ALL_GRANTED, session);
          terminating = true;
          this.context.terminateSelf();
        }
      }
    })
  }

  aboutToDisappear() {
    Log.info('permission dialog about to disappear');
    this.dialogController = null;
  }

  async GetAppInfo() {
    let callerBundle: CallerBundleInfo = getCallerBundleInfo(this.want as Object as WantInfo);
    this.bundleName = callerBundle.bundleName;
    this.reqUserPermissions = callerBundle.permissionGroup as Permission[]; // user permission is passed from wantInfo
    // check if wanted permissions are in the same permission group
    let groupName = checkPermissionGroup(this.reqUserPermissions);
    if (groupName == null) {
      terminating = true;
      PermissionDialogException(Constants.ERR_PERMISSIONS_NOT_SAME_GROUP, session);
      this.context.terminateSelf();
    }
    this.currentGroup = groupName!;
    // check app infos, check if permissions are claimed , check if permissions are granted
    this.applicationInfo = await this.getSpecifiedApplication(callerBundle.bundleName);
    if (this.applicationInfo === undefined) {
      Log.error('application info is undefined');
    }
    // get application detailed info
    await this.initApplicationInfo(this.applicationInfo!);
    // initialize permission states
    await this.initialPermissions();
    // store application info after initialization is done
    GlobalContext.store('applicationInfo', this.applicationInfo);
  }

  async initApplicationInfo(info: AppInfo) {
    Log.info('labelResource: ' + JSON.stringify(info.labelResource));
    let resourceManager = this.context.createBundleContext(info.bundleName).resourceManager;

    if (info.labelResource.id !== 0) {
      info.label = await this.context.resourceManager.getStringValue(info.labelResource);
    } else {
      info.label = await resourceManager.getStringValue(info.labelId);
    }

    try {
      if (info.iconResource.id !== 0) {
        let iconDescriptor = this.context.resourceManager.getDrawableDescriptor(info.iconResource);
        info.icon = iconDescriptor?.getPixelMap();
      } else {
        let iconDescriptor = resourceManager.getDrawableDescriptor(info.iconId);
        info.icon = iconDescriptor?.getPixelMap();
      }
    } catch (error) {
      Log.error(`getDrawableDescriptor failed, error code: ${error.code}, message: ${error.message}.`);
    }

    if (!info.icon) {
      info.icon = $r('app.media.icon');
    }

    let groupIds: number[] = [];
    for (let i = 0; i < this.reqUserPermissions.length; i++) {
      let groupId = getGroupIdByPermission(this.reqUserPermissions[i]);
      if (groupIds.indexOf(groupId) == -1) {
        groupIds.push(groupId);
      }
    }
    info.permissions = this.reqUserPermissions;
    info.groupId = groupIds;
  }

  async getStatus(groupReqPermissions: Permissions[], group: string) {
    if (group === 'LOCATION') {
      try {
        let acManager = abilityAccessCtrl.createAtManager();
        let fuzzyState = acManager.verifyAccessTokenSync(
          this.applicationInfo?.tokenId, Permission.APPROXIMATELY_LOCATION
        );
        fuzzyState === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED ?
          this.isGranted = Constants.PERMISSION_ALLOWED_ONLY_DURING_USE : null;
        let backgroundState =
          acManager.verifyAccessTokenSync(this.applicationInfo?.tokenId, Permission.LOCATION_IN_BACKGROUND);
        backgroundState === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED ?
          this.isGranted = Constants.PERMISSION_ALLOW : null;
        await acManager.getPermissionFlags(this.applicationInfo?.tokenId, Permission.APPROXIMATELY_LOCATION )
        .then(flag => {
          flag === Constants.PERMISSION_ALLOW_THIS_TIME ? this.isGranted = Constants.PERMISSION_ONLY_THIS_TIME : null;
        })
      } catch (err) {
        Log.error('change location status error: ' + JSON.stringify(err));
      }
      GlobalContext.store('locationStatus', this.isGranted);
      return true;
    }
    for (let i = 0; i < groupReqPermissions.length; i++) {
      let permission = groupReqPermissions[i];
      let res = await verifyAccessToken(this.applicationInfo!.tokenId, permission);
      if (res != abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        this.isGranted = Constants.PERMISSION_BAN;
      }
      if (group === 'FOLDER' && res === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        switch (permission) {
          case Permission.READ_WRITE_DOWNLOAD_DIRECTORY:
            this.folderStatus[0] = true;
            break;
          case Permission.READ_WRITE_DESKTOP_DIRECTORY:
            this.folderStatus[1] = true;
            break;
          case Permission.READ_WRITE_DOCUMENTS_DIRECTORY:
            this.folderStatus[2] = true;
            break;
        }
      }
    }
    return true;
  }

  /**
   * Initialize permission status information and group permission information
   */
  async initialPermissions() {
    if (this.bundleName && !this.applicationInfo?.groupId.length) {
      await this.initApplicationInfo(this.applicationInfo!);
    }
    let reqPermissions = this.applicationInfo!.permissions;
    let reqGroupIds = this.applicationInfo!.groupId;

    for (let i = 0; i < reqGroupIds.length; i++) {
      let id = reqGroupIds[i];
      let groupName = groups[id].groupName;
      let group = groups[id].name;
      let groupReqPermissions: Permissions[] = [];

      for (let j = 0; j < reqPermissions.length; j++) {
        let permission = reqPermissions[j];
        if (groups[id].permissions.indexOf(permission) != -1) {
          groupReqPermissions.push(permission);
          this.groupName = groupName;
        }
      }
      this.isGranted = group === 'LOCATION' ? Constants.PERMISSION_BAN : Constants.PERMISSION_ALLOW;
      this.folderStatus = [false, false, false];
      await this.getStatus(groupReqPermissions, group);

      GlobalContext.store('folderStatus', this.folderStatus);
    }
  }
}

@CustomDialog
struct mediaDocumentItem {
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;
  private backTitle: ResourceStr = '';
  private bundleName: string = '';
  private permissions: Permission[] = [];
  private status: number = 0;
  private tokenId: number = 0;
  private controller: CustomDialogController;
  @State hidden: boolean = false;
  @State currentGroup: PermissionGroup = PermissionGroup.OTHER;
  @State applicationInfo: AppInfo = GlobalContext.load('applicationInfo');
  @State folderStatus: boolean[] = [];
  @State mediaDocListItem: MediaDocObj[] = []; // Permission information array
  @State selected: number = 0;
  @State accurateIsOn: boolean = true;
  @State api: number = 0;
  @State isRisk: boolean = false; // Whether it is a risky application
  @State noForeground: boolean = false;
  @State isTouch: number = -1;
  @State isCheck: string = '';
  @State reason: string = '';
  @State label: string = '';
  @State version: string = '';
  @State permissionLabels: Array<ResourceStr> = [];
  @LocalStorageLink('bundleInfo') bundleInfo: Want = {} as Want;

  /**
   * Grant permissions to the app
   * @param {Number} accessTokenId
   * @param {String} permission permission name
   */
  async grantUserGrantedPermission(accessTokenId: number, permission: Permissions) {
    Log.info('granting permission ' + permission);
    try {
      await abilityAccessCtrl.createAtManager()
        .grantUserGrantedPermission(accessTokenId, permission, Constants.PERMISSION_FLAG);
        Log.info('grantUserGrantedPermission ' + permission + ' success.');
        results.set(permission, Constants.PERMISSION_DIALOG_SUCCESS);
    } catch (e) {
        results.set(permission, Constants.ERR_PERMISSION_GRANT_EXCEPTION);
        Log.error('grantUserGrantedPermission failed. Cause: ' + JSON.stringify(e));
    }
  }

  /**
   * Deauthorize the app
   * @param {Number} accessTokenId
   * @param {String} permission permission name
   */
  async revokeUserGrantedPermission(accessTokenId: number, permission: Permissions, flag: number) {
    abilityAccessCtrl.createAtManager().revokeUserGrantedPermission(accessTokenId, permission, flag)
      .then(() => {
        Log.error('revokeUserGrantedPermission ' + permission + ' success');
      })
      .catch((error: BusinessError) => {
        Log.error('revokeUserGrantedPermission failed. Cause: ' + JSON.stringify(error));
      })
  }

  onPageShow(): void {
    this.refreshStatus();
  }

  async refreshStatus() {
    Log.info('Refresh permission status');
    let isGranted = this.currentGroup === 'LOCATION' ? Constants.PERMISSION_BAN : Constants.PERMISSION_ALLOW;
    let folderStatus = [false, false, false];
    let atManager = abilityAccessCtrl.createAtManager();
    for (let i = 0; i < this.permissions.length; i++) {
      let permission = this.permissions[i];
      if (this.currentGroup === 'LOCATION') {
        continue;
      }
      let res = atManager.verifyAccessTokenSync(this.tokenId, permission);
      if (res != abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        isGranted = Constants.PERMISSION_BAN;
      }
      if (this.currentGroup === 'FOLDER' && res === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        switch (permission) {
          case Permission.READ_WRITE_DOWNLOAD_DIRECTORY:
            folderStatus[0] = true;
            break;
          case Permission.READ_WRITE_DESKTOP_DIRECTORY:
            folderStatus[1] = true;
            break;
          case Permission.READ_WRITE_DOCUMENTS_DIRECTORY:
            folderStatus[2] = true;
            break;
        }
        results.set(permission, Constants.PERMISSION_DIALOG_SUCCESS);
      }
    }
    this.folderStatus = folderStatus;
    await this.refreshSelected(isGranted);
  }

  async refreshSelected(isGranted: number) {
    this.selected = isGranted;
    if (this.currentGroup === 'PASTEBOARD') {
      try {
        let acManager = abilityAccessCtrl.createAtManager();
        acManager.getPermissionFlags(this.tokenId, Permission.READ_PASTEBOARD).then(flag => {
          flag === Constants.PERMISSION_ALLOW_THIS_TIME ? this.selected = Constants.PERMISSION_ONLY_THIS_TIME : null;
        });
      } catch (err) {
        Log.error('getPermissionFlags error: ' + JSON.stringify(err));
      }
    } else if (this.currentGroup === 'LOCATION') {
      try {
        let acManager = abilityAccessCtrl.createAtManager();
        let fuzzyState = acManager.verifyAccessTokenSync(this.tokenId, Permission.APPROXIMATELY_LOCATION);
        fuzzyState === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED ?
          this.selected = Constants.PERMISSION_ALLOWED_ONLY_DURING_USE : null;
        let accurateStatus = acManager.verifyAccessTokenSync(this.tokenId, Permission.LOCATION);
        this.accurateIsOn = (accurateStatus == abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) ? true : false;
        let backgroundState = acManager.verifyAccessTokenSync(this.tokenId, Permission.LOCATION_IN_BACKGROUND);
        backgroundState === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED ?
          this.selected = Constants.PERMISSION_ALLOW : null;
        acManager.getPermissionFlags(this.tokenId, Permission.APPROXIMATELY_LOCATION).then(flag => {
          flag === Constants.PERMISSION_ALLOW_THIS_TIME ? this.selected = Constants.PERMISSION_ONLY_THIS_TIME : null;
        })
      } catch (err) {
        Log.error('change location status error: ' + JSON.stringify(err));
      }
    } else {
      await this.checkPermissionFlag();
    }
  }

  async checkPermissionFlag() {
    try {
      for (const permission of this.permissions) {
        let acManager = abilityAccessCtrl.createAtManager();
        let flag = await acManager.getPermissionFlags(this.tokenId, permission);
        Log.error('permission Flag is ' + flag);
        if (flag === Constants.PERMISSION_DEFAULT && terminating == false) {
          PermissionDialogException(Constants.ERR_PERMISSIONS_FLAG_DEFAULT, session);
          terminating = true;
          this.context.terminateSelf();
          return;
        }
      }
    } catch (err) {
      Log.error('getPermissionFlags error: ' + JSON.stringify(err));
    }
  }

  getCheckboxInfo(permission: Permissions): CheckboxInfo {
    switch (permission) {
      case Permission.READ_WRITE_DOWNLOAD_DIRECTORY:
        return new CheckboxInfo($r('app.string.Download_folder'), 0);
      case Permission.READ_WRITE_DESKTOP_DIRECTORY:
        return new CheckboxInfo($r('app.string.Desktop_folder'), 1);
      case Permission.READ_WRITE_DOCUMENTS_DIRECTORY:
        return new CheckboxInfo($r('app.string.Document_folder'), 2);
      default:
        return new CheckboxInfo($r('app.string.Download_folder'), 0);
    }
  }

  getMediaDocList() {
    Log.info('current group ' + this.currentGroup);
    Log.info('current permissions ' + this.permissions);

    if (this.currentGroup == 'PASTEBOARD') {
      this.mediaDocListItem.push(
        new MediaDocObj($r('app.string.per_use_query'), this.permissions, Constants.PERMISSION_ONLY_THIS_TIME)
      );
      this.mediaDocListItem.push(
        new MediaDocObj($r('app.string.always_allow'), this.permissions, Constants.PERMISSION_ALLOW)
      );
    } else if (this.currentGroup == 'LOCATION') {
      this.selected = GlobalContext.load('locationStatus');
      this.mediaDocListItem.push(
        new MediaDocObj($r('app.string.per_inquiry'), this.permissions, Constants.PERMISSION_ONLY_THIS_TIME)
      );
      if (this.permissions.includes(Permission.LOCATION_IN_BACKGROUND)) {
        this.mediaDocListItem.push(
          new MediaDocObj($r('app.string.always_allow'), this.permissions, Constants.PERMISSION_ALLOW)
        );
      }
      if (this.permissions.includes(Permission.APPROXIMATELY_LOCATION)) {
        this.mediaDocListItem.push(
          new MediaDocObj(
            $r('app.string.allowed_only_during_use'),
            [Permission.APPROXIMATELY_LOCATION],
            Constants.PERMISSION_ALLOWED_ONLY_DURING_USE
          )
        );
      } else {
        this.noForeground = true;
      }
    } else {
      this.mediaDocListItem.push(
        new MediaDocObj($r('app.string.allow'), this.permissions, Constants.PERMISSION_ALLOW)
      );
    }
    this.mediaDocListItem.push(
      new MediaDocObj($r('app.string.ban'), this.permissions, Constants.PERMISSION_BAN)
    );
  }

  async getReason() {
    this.label = this.applicationInfo.label;
    if (showSubPermissionsGroup.indexOf(this.currentGroup) != -1) {
      this.permissions.forEach((permission, idx) => {
        if (idx > 0) {
          this.permissionLabels.push($r('app.string.and'));
        }
        let label = getPermissionLabel(permission);
        this.permissionLabels.push(label);
      });
    }
    let hasReason = false;
    let info = await
      bundleManager.getBundleInfo(this.bundleName, bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_REQUESTED_PERMISSION)
    for (const permission of this.permissions) {
      for (const reqPermissionDetail of info.reqPermissionDetails) {
        if (reqPermissionDetail.name != permission) {
          continue;
        }
        Log.info('reqPermissionDetail: ' + JSON.stringify(reqPermissionDetail));
        let context = this.context.createModuleContext(this.bundleName, reqPermissionDetail.moduleName);
        let reason = await context.resourceManager.getStringValue(reqPermissionDetail.reasonId);
        if (reason !== undefined && !hasReason) {
          this.reason = reason.slice(Constants.START_SUBSCRIPT, Constants.END_SUBSCRIPT);
          hasReason = true;
        }
      }
    }
  }

  aboutToAppear() {
    this.refreshStatus();
    this.getMediaDocList();
    this.getReason();
    this.setState();
  }

  setState() {
    this.hidden = false;
    this.selected = this.status;
    bundleManager.getBundleInfo(this.bundleName, bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
    .then(async res => {
        this.api = res.targetVersion;
        this.version = res.versionName;
        accessTokenId = res.appInfo.accessTokenId;
        let acManager = abilityAccessCtrl.createAtManager();
        let accurateStatus = acManager.verifyAccessTokenSync(res.appInfo.accessTokenId, Permission.LOCATION);
        this.accurateIsOn = (accurateStatus == abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) ? true : false;
        try {
          let getFlagPermission =
            this.currentGroup === 'LOCATION' ? Permission.APPROXIMATELY_LOCATION : this.permissions[0];
          let flag = await acManager.getPermissionFlags(res.appInfo.accessTokenId, getFlagPermission);
          Log.info(`getPermissionFlags success, data->${JSON.stringify(flag)}`);
          this.isRisk = (flag == Constants.PERMISSION_POLICY_FIXED) ? true : false;
          if (flag === Constants.PERMISSION_ALLOW_THIS_TIME) {
            this.selected = Constants.PERMISSION_ONLY_THIS_TIME;
          }
        } catch (err) {
          Log.error('acManager.getPermissionFlags failed. Cause: ' + JSON.stringify(err));
        }
      }).catch((error: BusinessError) => {
      Log.error('bundle.getBundleInfo failed. Cause: ' + JSON.stringify(error));
    });
  }

  async grantFolderPermission(permission: Permissions) {
    if (this.folderStatus[this.getCheckboxInfo(permission).index]) {
      this.revokeUserGrantedPermission(accessTokenId, permission, Constants.PERMISSION_FLAG);
      this.folderStatus[this.getCheckboxInfo(permission).index] = false;
      results.set(permission, Constants.ERR_PERMISSION_GRANT_EXCEPTION);
    } else {
      await this.grantUserGrantedPermission(accessTokenId, permission);
      this.folderStatus[this.getCheckboxInfo(permission).index] = true;
    }
    // check if every permission has been granted
    let allGranted = true;
    for (const permission of this.permissions) {
      if (!results.has(permission)) {
        Log.info('permission ' + permission + ' not granted, continue');
        return;
      }
      if (results.get(permission) !== Constants.PERMISSION_DIALOG_SUCCESS) {
        allGranted = false;
      }
    }
    // if all granted , return status
    if (allGranted) {
      ReportDialogResult(this.permissions);
    }
  }

  async grantOtherPermissions(item: MediaDocObj) {
    this.selected = item.index;
    for (const permission of item.permissions) {
      Log.info('item click index:' + item.index);
      if (item.index === Constants.PERMISSION_ALLOW) {
        if (permission !== Permission.LOCATION) {
          await this.grantUserGrantedPermission(accessTokenId, permission);
        }
      } else if (item.index === Constants.PERMISSION_BAN) {
        if (permission == Permission.LOCATION && this.accurateIsOn) {
          this.revokeUserGrantedPermission(accessTokenId, permission, Constants.PERMISSION_FLAG);
          this.accurateIsOn = false;
        } else {
          this.revokeUserGrantedPermission(accessTokenId, permission, Constants.PERMISSION_FLAG);
        }
      } else if (item.index === Constants.PERMISSION_ONLY_THIS_TIME) {
        if (permission !== Permission.LOCATION) {
          await this.revokeUserGrantedPermission(
            accessTokenId, permission, Constants.PERMISSION_ALLOW_THIS_TIME
          );
        }
      } else if (item.index === Constants.PERMISSION_ALLOWED_ONLY_DURING_USE) {
        await this.grantUserGrantedPermission(accessTokenId, permission);
        await this.revokeUserGrantedPermission(
          accessTokenId, Permission.LOCATION_IN_BACKGROUND, Constants.PERMISSION_FLAG
        );
      }
    }
    ReportDialogResult(this.permissions);
    return true;
  }

  build() {
    Column() {
      Row() {
        Column() {
          Row() {
            Text(this.backTitle)
              .align(Alignment.Start)
              .fontColor($r('sys.color.font_primary'))
              .maxLines(Constants.MAXIMUM_HEADER_LINES)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .fontSize(Constants.TEXT_BIG_FONT_SIZE)
              .flexGrow(Constants.FLEX_GROW)
              .fontWeight(FontWeight.Bold)
              .padding({ left: Constants.PADDING_24, top: Constants.PADDING_20, bottom: Constants.PADDING_20 })
              .width('80%')
          }.width(Constants.FULL_WIDTH)
        }
        .alignItems(HorizontalAlign.Start)
        .width(Constants.FULL_WIDTH)
      }
      Row() {
        Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
          Image(this.applicationInfo.icon)
            .width(Constants.TERTIARY_IMAGE_WIDTH)
            .height(Constants.TERTIARY_IMAGE_HEIGHT)
            .margin({ left: Constants.TERTIARY_IMAGE_MARGIN_LEFT, right: Constants.TERTIARY_IMAGE_MARGIN_RIGHT })
          Column() {
            Row() {
              Text(this.label)
                .maxLines(Constants.MAXIMUM_HEADER_LINES)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
                .fontColor($r('sys.color.font_primary'))
                .fontWeight(FontWeight.Bold)
                .textAlign(TextAlign.Start)
            }
            .width(Constants.TERTIARY_HALF_WIDTH)
            .margin({ bottom: Constants.TERTIARY_LABEL_MARGIN_BOTTOM })

            Row() {
              Text($r('app.string.version'))
                .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
                .fontColor($r('sys.color.font_secondary'))
                .textAlign(TextAlign.Start)
              Text(this.version)
                .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
                .fontColor($r('sys.color.font_secondary'))
                .textAlign(TextAlign.Start)
            }
            .width(Constants.TERTIARY_HALF_WIDTH)
          }
        }.margin({ left: Constants.TERTIARY_MARGIN_LEFT })
      }
      if (this.isRisk) {
        Row() {
          Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
            Row() {
              Image($r('app.media.ic_public_fail'))
                .fillColor($r('sys.color.icon_secondary'))
                .width(Constants.TERTIARY_RADIO_IMAGE_WIDTH)
                .height(Constants.TERTIARY_RADIO_IMAGE_HEIGHT)
                .margin({ right: Constants.TERTIARY_IMAGE_MARGIN_RIGHT })
              Text($r('app.string.risk_warning'))
                .fontColor($r('sys.color.font_primary'))
                .fontSize($r('sys.float.ohos_id_text_size_body1'))
                .fontWeight(FontWeight.Regular)
            }.margin({ left: Constants.DEFAULT_PADDING_START, right: Constants.DEFAULT_PADDING_END })
          }
        }.backgroundColor($r('sys.color.interactive_click'))
        .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
        .padding({ top: Constants.DEFAULT_PADDING_TOP, bottom: Constants.DEFAULT_PADDING_BOTTOM })
        .margin({ left: Constants.DEFAULT_MARGIN_START, right: Constants.DEFAULT_MARGIN_END })
      }
      Row() {
        Text() {
          Span(this.backTitle)
          Span($r('app.string.access_permission'))
        }
        .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
        .fontColor($r('sys.color.icon_secondary'))
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Start)
        .lineHeight(Constants.SUBTITLE_LINE_HEIGHT)
      }.width(Constants.FULL_WIDTH)
      .constraintSize({ minHeight: Constants.SUBTITLE_MIN_HEIGHT })
      .padding({ top: Constants.SUBTITLE_PADDING_TOP, bottom: Constants.SUBTITLE_PADDING_BOTTOM,
        left: Constants.TERTIARY_TEXT_MARGIN_LEFT, right: Constants.TERTIARY_IMAGE_MARGIN_RIGHT })

      Column() {
        List() {
          if (this.currentGroup === 'FOLDER') {
            ForEach(this.permissions, (permission: Permissions) => {
              ListItem() {
                Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
                  Row() {
                    Text(this.getCheckboxInfo(permission).label)
                      .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
                      .fontColor($r('sys.color.font_primary'))
                      .fontWeight(FontWeight.Medium)
                      .flexGrow(Constants.FLEX_GROW)
                    Checkbox()
                      .select(this.folderStatus[this.getCheckboxInfo(permission).index])
                      .hitTestBehavior(HitTestMode.None)
                  }
                  .width(Constants.FULL_WIDTH)
                  .height(Constants.LISTITEM_ROW_HEIGHT)
                  .onClick(async () => {
                      await this.grantFolderPermission(permission)
                  })
                }
              }
              .padding({
                left: $r('sys.float.ohos_id_card_margin_start'),
                right: $r('sys.float.ohos_id_card_margin_end')
              })
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
              .margin({ top: Constants.TERTIARY_LISTITEM_MARGIN_TOP })
              .linearGradient((this.isCheck === permission) ? {
                angle: 90,
                direction: GradientDirection.Right,
                colors: [['#DCEAF9', 0.0], ['#FAFAFA', 1.0]]
              } : {
                angle: 90,
                direction: GradientDirection.Right,
                colors: []
              })
              .onTouch(event => {
                if (event === undefined) {
                  return;
                }
                if (event.type === TouchType.Down) {
                  this.isCheck = permission;
                }
                if (event.type === TouchType.Up) {
                  this.isCheck = '';
                }
              })
            }, (permission: Permissions) => JSON.stringify(permission))
          } else {
            ForEach(this.mediaDocListItem, (item: MediaDocObj) => {
              ListItem() {
                Column() {
                  Row() {
                    Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
                      Row() {
                        Text(item.name)
                          .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
                          .fontColor($r('sys.color.font_primary'))
                          .fontWeight(FontWeight.Medium)
                          .flexGrow(Constants.FLEX_GROW)
                        Radio({ value: 'Radio', group: 'radioGroup' })
                          .checked(item.index === this.selected)
                          .hitTestBehavior(HitTestMode.None)
                          .height(Constants.SHAPE_DIA)
                          .width(Constants.SHAPE_DIA)
                      }
                      .width(Constants.FULL_WIDTH)
                      .height(Constants.LISTITEM_ROW_HEIGHT)
                      .onClick(async () => {
                        await this.grantOtherPermissions(item);
                      })
                    }
                  }
                }
              }
              .padding({
                left: $r('sys.float.ohos_id_card_margin_start'),
                right: $r('sys.float.ohos_id_card_margin_end')
              })
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
              .linearGradient((this.isTouch === item.index) ? {
                angle: 90,
                direction: GradientDirection.Right,
                colors: [['#DCEAF9', 0.0], ['#FAFAFA', 1.0]]
              } : {
                angle: 90,
                direction: GradientDirection.Right,
                colors: []
              })
              .onTouch(event => {
                if (event === undefined) {
                  return;
                }
                if (event.type === TouchType.Down) {
                  this.isTouch = item.index;
                }
                if (event.type === TouchType.Up) {
                  this.isTouch = -1;
                }
              })
              .margin({ top: Constants.TERTIARY_LISTITEM_MARGIN_TOP })
            }, (item: MediaDocObj) => JSON.stringify(item))
          }
        }
        .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
        .backgroundColor($r('sys.color.comp_background_list_card'))
        .padding(Constants.LIST_PADDING_TOP)
        .divider({
          strokeWidth: Constants.DIVIDER,
          color: $r('sys.color.comp_divider'),
          startMargin: Constants.DEFAULT_MARGIN_START,
          endMargin: Constants.DEFAULT_MARGIN_END
        })

        if (this.permissions.includes(Permission.LOCATION)) {
          Column() {
            Row() {
              Text($r('app.string.precise_location'))
                .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
                .fontColor($r('sys.color.font_primary'))
                .fontWeight(FontWeight.Medium)
                .flexGrow(Constants.FLEX_GROW)
              Toggle({ type: ToggleType.Switch, isOn: this.accurateIsOn })
                .selectedColor($r('sys.color.icon_emphasize'))
                .switchPointColor($r('sys.color.comp_background_primary_contrary'))
                .onChange((isOn: boolean) => {
                  let acManager = abilityAccessCtrl.createAtManager()
                  if (isOn) {
                    acManager.grantUserGrantedPermission(accessTokenId, Permission.LOCATION, Constants.PERMISSION_FLAG)
                    .then(() => {
                      this.accurateIsOn = true
                    })
                  } else {
                    acManager.revokeUserGrantedPermission(accessTokenId, Permission.LOCATION, Constants.PERMISSION_FLAG)
                    .then(() => {
                      this.accurateIsOn = false
                    })
                  }
                })
                .padding({ right: 0 })
                .enabled(this.selected !== Constants.PERMISSION_BAN)
            }.width(Constants.FULL_WIDTH)
            .height(Constants.LISTITEM_ROW_HEIGHT)
          }.margin({ top: Constants.LOCATION_MARGIN_TOP, bottom: Constants.LOCATION_MARGIN_BOTTOM })
          .padding({
            left: Constants.DEFAULT_PADDING_START,
            right: Constants.DEFAULT_PADDING_END,
            top: Constants.TERTIARY_LIST_PADDING_TOP,
            bottom: Constants.TERTIARY_LIST_PADDING_BOTTOM
          })
          .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
          .backgroundColor($r('sys.color.comp_background_list_card'))

          Row() {
            Text($r('app.string.get_the_exact_position'))
              .fontSize(Constants.TEXT_SMALL_FONT_SIZE)
              .fontColor($r('sys.color.font_secondary'))
              .lineHeight(Constants.TEXT_SMALL_LINE_HEIGHT)
          }.width(Constants.FULL_WIDTH)
          .padding({
            left: Constants.DEFAULT_PADDING_START,
            right: Constants.DEFAULT_PADDING_END,
          })
        }
      }
      .padding({
        left: Constants.LIST_PADDING_LEFT,
        right: Constants.LIST_PADDING_LEFT
      })
      .width(Constants.FULL_WIDTH)
      .enabled(!this.isRisk && !this.noForeground)
      .opacity((!this.isRisk && !this.noForeground) ? 1 : $r('sys.float.ohos_id_alpha_disabled'))
    }
    .visibility(this.hidden ? Visibility.None : Visibility.Visible)
    .width(Constants.FULL_WIDTH)
  }
}

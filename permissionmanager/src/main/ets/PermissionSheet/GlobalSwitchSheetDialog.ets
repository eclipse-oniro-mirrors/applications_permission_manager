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

import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import { BusinessError } from '@ohos.base';
import audio from '@ohos.multimedia.audio';
import camera from '@ohos.multimedia.camera';
import { CustomContentDialog } from '@ohos.arkui.advanced.Dialog';
import { Log, PermissionDialogException, PermissionDialogReturn } from '../common/utils/utils';
import { GroupInfo, WantInfo } from '../common/model/typedef';
import { GlobalContext } from '../common/utils/globalContext';
import Constants from '../common/utils/constant';
import { globalGroup, groups } from '../common/model/permissionGroup';
import bundleManager from '@ohos.bundle.bundleManager';
import { getCallerBundleInfo } from './PermissionStateSheetDialog';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import common from '@ohos.app.ability.common';
import { PermissionGroup } from '../common/model/definition';


let globalIsOn: boolean;
let session: UIExtensionContentSession;
let storage = LocalStorage.getShared();
let bundleName = '';

@Entry(storage)
@Component
struct GlobalSwitchSheetDialog {
  @LocalStorageLink('want') want: Want | null = storage.get<Want>('want') || null;
  @LocalStorageLink('session') session: UIExtensionContentSession =
    storage.get<UIExtensionContentSession>('session') as UIExtensionContentSession;
  private context = getContext(this) as common.UIExtensionContext;
  private muteSuppoted = false;
  private groupName: PermissionGroup = PermissionGroup.OTHER;
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
    cornerRadius: {
      topLeft: 32,
      topRight: 32,
      bottomLeft: 0,
      bottomRight: 0
    },
    cancel: () => {
      PermissionDialogReturn([Constants.ERR_GLOBAL_SWITCH_EXCEPTION], session);
      this.context.terminateSelf();
      this.dialogController?.close();
    }
  });

  @Builder
  buildDialog() {
    applicationItem({
      isMuteSupported: this.muteSuppoted,
      currentGroup: this.groupName
    })
  }

  async aboutToAppear() {
    session = this.session;
    Log.info('GlobalSwitchSheetDialog aboutToAppear');
    Log.info('GlobalSwitchSheetDialog getWant' + JSON.stringify(this.want));
    let callerBundle = getCallerBundleInfo(this.want as Object as WantInfo);
    Log.info('GlobalSwitchSheetDialog bundleName ' + callerBundle.bundleName);
    let globalSwitch = callerBundle.globSwitch;
    bundleName = callerBundle.bundleName;

    if (globalSwitch === Constants.GLOBAL_SWITCH_CAMERA) {
      this.groupName = PermissionGroup.CAMERA;
    } else if (globalSwitch === Constants.GLOBAL_SWITCH_MICROPHONE) {
      this.groupName = PermissionGroup.MICROPHONE;
    } else {
      Log.error('global switch not suppoted');
      PermissionDialogException(Constants.ERR_GLOBAL_SWITCH_NOT_SUPPORTED, session);
      this.context.terminateSelf();
      return;
    }

    if (this.groupName == 'MICROPHONE') {
      let audioManager = audio.getAudioManager();
      let audioVolumeManager = audioManager.getVolumeManager();
      let groupid = audio.DEFAULT_VOLUME_GROUP_ID;
      let audioVolumeGroupManager = await audioVolumeManager.getVolumeGroupManager(groupid);
      this.muteSuppoted = true;
      globalIsOn = !audioVolumeGroupManager.isPersistentMicMute();
    } else {
      let cameraManager = camera.getCameraManager(this.context);
      this.muteSuppoted = cameraManager.isCameraMuteSupported();
      globalIsOn = !cameraManager.isCameraMuted();
    }

    if (this.muteSuppoted == false) {
      Log.error('global switch muted');
      PermissionDialogException(Constants.ERR_GLOBAL_SWITCH_NOT_SUPPORTED, session);
      this.context.terminateSelf();
      return;
    }

    if (globalIsOn) {
      Log.error('global switch is on');
      PermissionDialogException(Constants.ERR_GLOBAL_SWITCH_IS_ON, session);
      this.context.terminateSelf();
      return;
    }

    Log.info('isMuted ' + globalIsOn);
    this.dialogController?.open();
  }

  onPageShow(): void {
    Log.info('GlobalSwitchSheetDialog onPageShow' );
  }

  build() {
  }
}

@CustomDialog
struct applicationItem {
  private context = getContext(this) as common.UIExtensionContext;
  @State globalIsOn: boolean = false;
  @State backTitle: string = '';
  @State groupInfo: GroupInfo = new GroupInfo(PermissionGroup.OTHER, '', '', '', [], '', [], [], false);
  @State currentGroup: PermissionGroup = PermissionGroup.OTHER;
  @State isMuteSupported: boolean = false;
  @State appName: ResourceStr = '';
  private controller: CustomDialogController;

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
            if (this.dialogController !== null) {
              this.dialogController.close();
            }
          }
        },
        {
          value: $r('app.string.close'),
          buttonStyle: ButtonStyleMode.TEXTUAL,
          action: () => {
            Log.info('global accept');
            if (this.currentGroup == 'MICROPHONE') {
              let audioManager = audio.getAudioManager();
              let audioVolumeManager = audioManager.getVolumeManager();
              audioVolumeManager.getVolumeGroupManager(audio.DEFAULT_VOLUME_GROUP_ID).then(audioVolumeGroupManager => {
                audioVolumeGroupManager.setMicMutePersistent(true, audio.PolicyType.PRIVACY).then(() => {
                  Log.info('microphone muted');
                  if (this.dialogController !== null) {
                    this.dialogController.close();
                  }
                })
              })
            } else {
              let cameraManager = camera.getCameraManager(this.context);
              cameraManager.muteCamera(true);
              if (this.dialogController !== null) {
                this.dialogController.close();
              }
            }
          }
        }
      ],
    }),
    autoCancel: false
  });

  globalListen() {
    if (this.currentGroup == 'CAMERA') {
      let cameraManager = camera.getCameraManager(this.context);
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
  async aboutToAppear() {
    try {
      let bundleInfo = await bundleManager.getBundleInfo(
        bundleName,
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      let manager = this.context.createBundleContext(bundleName).resourceManager;
      this.appName = await manager.getStringValue(bundleInfo.appInfo.labelId);
    } catch (e) {
      Log.error('get appName failed ' + JSON.stringify(e));
    }
    groups.forEach(group => {
      if (group.name === this.currentGroup) {
        this.groupInfo = group;
      }
    })
    this.backTitle = this.groupInfo.label;
    this.globalIsOn = globalIsOn;
    if (globalGroup.indexOf(this.currentGroup) !== -1) {
      this.globalListen();
    }
  }

  aboutToDisappear() {
    this.dialogController = null;
  }

  build() {
    Column() {
      Row() {
        Flex({ alignItems: ItemAlign.Start, justifyContent: FlexAlign.Start }) {
          Column() {
            Column() {
              Text($r(this.backTitle, this.appName))
                .align(Alignment.Start)
                .fontColor($r('sys.color.font_primary'))
                .maxLines(Constants.MAXIMUM_HEADER_LINES)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .fontSize(Constants.TEXT_BIG_FONT_SIZE)
                .flexGrow(Constants.FLEX_GROW)
                .fontWeight(FontWeight.Bold)
                .padding({left: Constants.PADDING_10, top: Constants.PADDING_20})
            }
            .width(Constants.FULL_WIDTH)
            .alignItems(HorizontalAlign.Start)
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
                      .onChange((isOn: boolean) => {
                        if (isOn) {
                          if (this.currentGroup == 'CAMERA') {
                            let cameraManager = camera.getCameraManager(this.context);
                            cameraManager.muteCamera(false);
                            PermissionDialogReturn([Constants.PERMISSION_DIALOG_SUCCESS], session);
                            this.context.terminateSelf();
                          } else {
                            let audioManager = audio.getAudioManager();
                            let audioVolumeManager = audioManager.getVolumeManager();
                            let groupId = audio.DEFAULT_VOLUME_GROUP_ID;
                            audioVolumeManager.getVolumeGroupManager(groupId).then(audioVolumeGroupManager => {
                              audioVolumeGroupManager.setMicMutePersistent(false, audio.PolicyType.PRIVACY);
                              PermissionDialogReturn([Constants.PERMISSION_DIALOG_SUCCESS], session);
                              this.context.terminateSelf();
                            })
                          }
                        }
                      })
                    Row().onClick(() => {
                      if (this.dialogController !== null) {
                        this.dialogController.open();
                      }
                    })
                      .width(Constants.DEFAULT_SLIDER_WIDTH).height(Constants.DEFAULT_SLIDER_HEIGHT)
                      .position({ x: this.globalIsOn ? 0 : Constants.OFFSET, y: 0 })
                  }.clip(true)
                }.height(Constants.LISTITEM_ROW_HEIGHT)
                .padding({ left: Constants.DEFAULT_PADDING_START, right: Constants.DEFAULT_PADDING_END })
              }.padding({ top: Constants.LIST_PADDING_TOP, bottom: Constants.LIST_PADDING_BOTTOM })
              .backgroundColor($r('sys.color.comp_background_list_card'))
              .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
              .margin({ top: Constants.MARGIN_16 })
            }
          }.padding({ left: Constants.AUTHORITY_LISTITEM_PADDING_LEFT })
        }.flexGrow(Constants.FLEX_GROW)
      }
    }
  }
}
/*
 * Copyright (c) 2025 Huawei Device Co., Ltd.
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

import window from '@ohos.window';
import display from '@ohos.display';
import accessibility from '@ohos.accessibility';
import { Log } from '../common/utils/utils';
import { DeviceUtil } from '../common/utils/deviceUtil';
import Constants from '../common/utils/constant';
import { WantInfo } from '../common/model/typedef';

@Entry({ useSharedStorage: true })
@Component
struct SecurityToast {
  @LocalStorageLink('want') want: WantInfo = new WantInfo([]);
  @LocalStorageLink('win') win: window.Window = {} as window.Window;
  @State alpha: number = 0;
  @State positionY: number = 0;
  @State setPosition: boolean = false;
  @State setOffset: number = Constants.TOAST_ANIMATION_OFFSET;
  @State windowWidth: number = 0;
  @State windowHeight: number = 0;
  @State rotationInit: number = 0;
  @State densityDPIInit: number = 0;
  @State topRectHeight: number = 0;

  getAnnounceForAccessibility() {
    try {
      let textAnnounce =
        this.getUIContext().getHostContext()?.resourceManager.getStringSync($r('app.string.SecurityTitle_mediaFiles')
          .id);
      let eventInfo: accessibility.EventInfo = ({
        type: 'announceForAccessibility',
        bundleName: 'com.ohos.permissionmanager',
        triggerAction: 'common',
        textAnnouncedForAccessibility: textAnnounce
      });
      accessibility.sendAccessibilityEvent(eventInfo)
        .catch((error: Error) => {
          Log.error(`sendAnnounceForAccessibilityEvent fail: ${error.message}`);
          return false;
        });
    } catch (error) {
      Log.error(`sendAccessibilityEvent failed, error code: ${error.code}, message: ${error.message}.`);
    }
  }

  getWinAvoidArea() {
    let type = window.AvoidAreaType.TYPE_SYSTEM;
    let avoidArea = this.win?.getWindowAvoidArea(type);
    this.topRectHeight = avoidArea.topRect.height;
  }

  aboutToAppear(): void {
    Log.info('onAboutToAppear');
    this.rotationInit = display.getDefaultDisplaySync().orientation;
    this.densityDPIInit = display.getDefaultDisplaySync().densityDPI;
    this.setPosition = this.want.parameters['ohos.toast.position'] ?? false;
    this.positionY = this.setPosition ? Constants.TOAST_POSITION_Y_UP : Constants.TOAST_POSITION_Y_UNDER;
    this.setOffset = this.want.parameters['ohos.toast.offset'] ?? Constants.TOAST_ANIMATION_OFFSET;
    this.screenMonitor();
    this.getWinAvoidArea();
    let timeoutStart = setTimeout(() => {
      this.alpha = 1;
      this.positionY = 0;
      clearTimeout(timeoutStart);
    }, Constants.TOAST_ANIMATION_TIMEOUT_START);
    let timeoutEnd = setTimeout(() => {
      this.alpha = 0;
      this.positionY = this.setPosition ? Constants.TOAST_POSITION_Y_UP : Constants.TOAST_POSITION_Y_UNDER;
      clearTimeout(timeoutEnd);
    }, Constants.TOAST_ANIMATION_TIMEOUT_END);
    let timeoutID = setTimeout(() => {
      this.win?.destroyWindow();
      clearTimeout(timeoutID);
    }, Constants.TOAST_ANIMATION_TIMEOUT_ID);
  }

  aboutToDisappear(): void {
    try {
      display.off('foldStatusChange');
      display.off('change');
    } catch (exception) {
      Log.error(`Failed to unregister callback. Cause code: ${exception.code}, message: ${exception.message}`);
    }
  }

  screenMonitor() {
    try {
      display.on('foldStatusChange', (data: display.FoldStatus) => {
        Log.info(`Listening enabled. Data: ${JSON.stringify(data)}`);
        this.win?.destroyWindow();
      });
    } catch (exception) {
      Log.error(`Failed to register callback. Code: ${JSON.stringify(exception)}`);
    }

    try {
      display.on('change', (data: number) => {
        Log.info(`Listening enabled. Data: ${JSON.stringify(data)}`);
        let rotation: number = display.getDefaultDisplaySync().orientation;
        let densityDPI = display.getDefaultDisplaySync().densityDPI;
        if (rotation !== this.rotationInit) {
          this.rotationInit = rotation;
          this.win?.destroyWindow();
          return;
        }
        if (this.densityDPIInit !== densityDPI) {
          this.densityDPIInit = densityDPI;
          this.win?.destroyWindow();
        }
      });
    } catch (exception) {
      Log.error(`Failed to register callback. Code: ${JSON.stringify(exception)}`);
    }
  }

  build() {
    Column() {
      Flex({ alignItems: ItemAlign.Center }) {
        SymbolGlyph($r('sys.symbol.security_shield'))
          .fontSize(Constants.TOAST_SYMBOLGLYPH_FONTSIZE)
          .fontColor([$r('sys.color.icon_primary'), $r('sys.color.icon_emphasize')])
          .renderingStrategy(SymbolRenderingStrategy.MULTIPLE_COLOR)
        Blank()
          .width('4vp')
        Text($r('app.string.SecurityTitle_mediaFiles'))
          .fontColor($r('sys.color.font_primary'))
          .minFontSize(Constants.TOAST_TEXT_MIDDLE_FONT_SIZE)
          .maxFontSize($r('sys.float.Body_M'))
          .fontSize($r('sys.float.Body_M'))
          .maxLines(Constants.SECURITY_HEADER_MAX_LINES)
          .heightAdaptivePolicy(TextHeightAdaptivePolicy.MAX_LINES_FIRST)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .onAppear(() => {
            this.getAnnounceForAccessibility();
          })
      }
      .opacity(this.alpha)
      .offset({ bottom: this.positionY })
      .animation({
        duration: Constants.TOAST_ANIMATION_TIMEOUT_START,
        curve: 'cubic-bezier(0.2, 0, 0.1, 1)',
      })
      .width('auto')
      .constraintSize({
        maxWidth: Constants.TOAST_CONSTRAINT_SIZE_MAX_WIDTH,
        minHeight: Constants.TOAST_CONSTRAINT_SIZE_MIN_HEIGHT
      })
      .margin(this.setPosition ? { top: this.setOffset - px2vp(this.topRectHeight) } : { bottom: this.setOffset })
      .padding(DeviceUtil.isPC() ? $r('sys.float.padding_level4') : {
        top: Constants.PADDING_8,
        right: Constants.PADDING_16,
        bottom: Constants.PADDING_8,
        left: Constants.PADDING_16
      })
      .shadow(DeviceUtil.isPC() ? {
        radius: Constants.TOAST_FLEX_SHADOW_RADIUS_40,
        color: $r('app.color.outerDefaultSMColor'),
        offsetX: Constants.TOAST_FLEX_SHADOW_OFFSET_X,
        offsetY: Constants.TOAST_FLEX_SHADOW_OFFSET_Y
      } : {
        radius: Constants.TOAST_FLEX_SHADOW_RADIUS_60,
        color: $r('app.color.outerDefaultMDColor'),
        offsetX: Constants.TOAST_FLEX_SHADOW_OFFSET_X,
        offsetY: Constants.TOAST_FLEX_SHADOW_OFFSET_Y
      })
      .borderRadius(DeviceUtil.isPC() ? $r('sys.float.corner_radius_level4') : $r('sys.float.corner_radius_level9'))
      .backgroundBlurStyle(DeviceUtil.isPC() ? BlurStyle.COMPONENT_REGULAR : BlurStyle.COMPONENT_ULTRA_THICK)
      .border(DeviceUtil.isPC() ? { width: '1px', color: '#33ffffff' } : {})
      .outline(DeviceUtil.isPC() ?
        { width: '1px', color: $r('app.color.outline'), radius: $r('sys.float.corner_radius_level4') } : {})
    }
    .width(Constants.TOAST_COLUMN_WIDTH)
    .height(Constants.TOAST_COLUMN_HEIGHT)
    .justifyContent(this.setPosition ? FlexAlign.Start : FlexAlign.End)
    .padding({
      left: (DeviceUtil.isPC() || DeviceUtil.isTablet()) ? Constants.PADDING_24 : Constants.PADDING_16,
      right: (DeviceUtil.isPC() || DeviceUtil.isTablet()) ? Constants.PADDING_24 : Constants.PADDING_16
    })
  }
}
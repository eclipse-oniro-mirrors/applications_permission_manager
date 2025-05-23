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

import Constants from '../utils/constant';
import { GrantDialogViewState } from '../../ServiceExtAbility/GrantDialogViewState';

@Extend(Button)function locationButton() {
  .backgroundColor($r('sys.color.ohos_id_color_dialog_bg'))
  .fontWeight(FontWeight.Medium)
  .fontSize(Constants.TEXT_SMALLER_FONT_SIZE)
  .height(Constants.LOCATION_BUTTON_HEIGHT)
  .borderRadius(Constants.LOCATION_BUTTON_RADIUS)
}

@Component
export struct LocationCanvas {
  @Link viewState: GrantDialogViewState;

  build() {
    Column() {
      Image($r('app.media.img_location_map'))
        .opacity($r('app.float.opacity_location'))
        .width(Constants.FULL_WIDTH)
        .height(Constants.FULL_HEIGHT)
        .scale({
          x: (
               (this.viewState.locationFlag == Constants.LOCATION_UPGRADE) ||
               (this.viewState.locationFlag == Constants.LOCATION_BOTH_PRECISE)
             )
          ? Constants.LOCATION_CANVAS_ZOOM_SCALE : Constants.LOCATION_CANVAS_INITIAL_SCALE,
          y: (
               (this.viewState.locationFlag == Constants.LOCATION_UPGRADE) ||
               (this.viewState.locationFlag == Constants.LOCATION_BOTH_PRECISE)
             )
            ? Constants.LOCATION_CANVAS_ZOOM_SCALE : Constants.LOCATION_CANVAS_INITIAL_SCALE
        })
        .animation({
          duration: Constants.LOCATION_ANIMATION_DURATION, // Animation duration
          curve: Curve.Smooth, // The animation curve
          playMode: PlayMode.Normal // The animation mode
        })
      Image($r('app.media.ic_public_gps_filled'))
        .fillColor($r('sys.color.brand'))
        .width(Constants.LOCATION_ICON_WIDTH)
        .height(Constants.LOCATION_ICON_HEIGHT)
        .position({ x: Constants.LOCATION_ICON_POSITION_X, y: Constants.LOCATION_ICON_POSITION_Y })
        .opacity(
          (
            (this.viewState.locationFlag == Constants.LOCATION_UPGRADE) ||
            (this.viewState.locationFlag == Constants.LOCATION_BOTH_PRECISE)
          ) ? 1 : 0
        )
        .scale({
          x: (
               (this.viewState.locationFlag == Constants.LOCATION_UPGRADE) ||
               (this.viewState.locationFlag == Constants.LOCATION_BOTH_PRECISE)
             ) ? 1 : 0.8,
          y: (
               (this.viewState.locationFlag == Constants.LOCATION_UPGRADE) ||
               (this.viewState.locationFlag == Constants.LOCATION_BOTH_PRECISE)
             ) ? 1 : 0.8
        })
        .animation({
          duration: Constants.LOCATION_ANIMATION_DURATION / 2, // Animation duration
          delay: this.viewState.locationFlag == Constants.LOCATION_BOTH_PRECISE ?
            (Constants.LOCATION_ANIMATION_DURATION / 2) : 0,
          curve: Curve.Smooth, // The animation curve
          playMode: PlayMode.Normal // The animation mode
        })
      Circle({ width: Constants.LOCATION_CIRCLE_DIA, height: Constants.LOCATION_CIRCLE_DIA })
        .position({ x: Constants.LOCATION_CIRCLE_POSITION_X, y: Constants.LOCATION_CIRCLE_POSITION_Y })
        .fill($r('app.color.location_circle_color'))
        .fillOpacity(Constants.LOCATION_CIRCLE_OPACITY)
        .stroke($r('app.color.location_circle_color'))
        .scale({
          x: (
               (this.viewState.locationFlag == Constants.LOCATION_UPGRADE) ||
               (this.viewState.locationFlag == Constants.LOCATION_BOTH_PRECISE)
             ) ? 0 : 1,
          y: (
               (this.viewState.locationFlag == Constants.LOCATION_UPGRADE) ||
               (this.viewState.locationFlag == Constants.LOCATION_BOTH_PRECISE)
             ) ? 0 : 1
        })
        .animation({
          duration: Constants.LOCATION_ANIMATION_DURATION, // Animation duration
          curve: Curve.Smooth, // The animation curve
          playMode: PlayMode.Normal // The animation mode
        })
      Row() {
        if (this.viewState.locationFlag == Constants.LOCATION_BOTH_PRECISE) {
          Button($r('app.string.precise_location_on'))
            .locationButton()
            .fontColor($r('sys.color.font_emphasize'))
            .onClick(() => { this.viewState.locationFlag = Constants.LOCATION_BOTH_FUZZY })
        }
        if (this.viewState.locationFlag == Constants.LOCATION_BOTH_FUZZY) {
          Button($r('app.string.precise_location_off'))
            .locationButton()
            .fontColor($r('sys.color.font_secondary'))
            .onClick(() => { this.viewState.locationFlag = Constants.LOCATION_BOTH_PRECISE })
        }
      }.position({ x: 0, y: 0 })
      .width(Constants.FULL_WIDTH)
      .height(Constants.FULL_HEIGHT)
      .alignItems(VerticalAlign.Top)
      .justifyContent(FlexAlign.Center)
      .padding({ top: Constants.LOCATION_BUTTON_POSITION_Y })
    }.width(Constants.FULL_WIDTH)
    .height(Constants.LOCATION_CANVAS_HEIGHT)
    .margin({ top: Constants.LOCATION_CANVAS_MARGIN_TOP, bottom: Constants.LOCATION_CANVAS_MARGIN_BOTTOM })
    .clip(true)
  }
}

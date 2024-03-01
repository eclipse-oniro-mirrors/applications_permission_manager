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

import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import Constants from '../utils/constant';

@Component
export struct backBar {
  private context = getContext(this) as common.UIAbilityContext;
  @Prop title: string = ''; // return title name
  @Prop recordable: boolean = false;
  @State record: string = '';
  @State isTouch: string = '';
  @State isBack: boolean = false;
  @State isMore: boolean = false;

  build() {
    Column() {
      Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
        Row() {
          Image($r('app.media.ic_public_back'))
            .fillColor($r('sys.color.ohos_id_color_primary'))
            .objectFit(ImageFit.Contain)
            .height(Constants.BACKBAR_IMAGE_HEIGHT)
            .width(Constants.BACKBAR_IMAGE_WIDTH)
            .draggable(false)
        }.width(Constants.CLICK_SHADOW_LENGTH)
        .height(Constants.CLICK_SHADOW_LENGTH)
        .borderRadius($r('sys.float.ohos_id_corner_radius_clicked'))
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .margin({
          left: Constants.DEFAULT_MARGIN_START,
          right: Constants.BACKBAR_MARGIN_RIGHT
        })
        .backgroundColor(this.isBack ? $r('sys.color.ohos_id_color_click_effect') : '')
        .onTouch(event => {
          if (event === undefined) {
            return;
          }
          if (event.type === TouchType.Down) {
            this.isBack = true;
          }
          if (event.type === TouchType.Up) {
            this.isBack = false;
          }
        })
        .onClick(() => {
          let length = router.getLength();
          Number(length) == 1 ? this.context.terminateSelf() : router.back();
        })
        Text(JSON.parse(this.title))
          .align(Alignment.Start)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .maxLines(Constants.MAXIMUM_HEADER_LINES)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .fontSize(Constants.TEXT_BIG_FONT_SIZE)
          .flexGrow(Constants.FLEX_GROW)
          .fontWeight(FontWeight.Bold)
        if (this.recordable) {
          Row() {
            Image($r('sys.media.ohos_ic_public_more'))
              .fillColor($r('sys.color.ohos_id_color_primary'))
              .objectFit(ImageFit.Contain)
              .height(Constants.BACKBAR_IMAGE_WIDTH)
              .width(Constants.BACKBAR_IMAGE_HEIGHT)
              .draggable(false)
          }.width(Constants.CLICK_SHADOW_LENGTH)
          .height(Constants.CLICK_SHADOW_LENGTH)
          .borderRadius($r('sys.float.ohos_id_corner_radius_clicked'))
          .alignItems(VerticalAlign.Center)
          .justifyContent(FlexAlign.Center)
          .margin({
            right: Constants.DEFAULT_MARGIN_END
          })
          .bindMenu(this.MenuBuilder())
          .backgroundColor(this.isMore ? $r('sys.color.ohos_id_color_click_effect') : '')
          .onTouch(event => {
            if (event === undefined) {
              return;
            }
            if (event.type === TouchType.Down) {
              this.isMore = true;
            }
            if (event.type === TouchType.Up) {
              this.isMore = false;
            }
          })
        }
      }
    }
    .height(Constants.BACKBAR_HEIGHT)
    .constraintSize({ minHeight: Constants.BACKBAR_MINHEIGHT })
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
  }

  @Builder MenuBuilder() {
    Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
      Row() {
        Text($r('app.string.permission_access_record'))
          .fontSize(Constants.TEXT_MIDDLE_FONT_SIZE)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
      }.constraintSize({ minWidth: Constants.MAXIMUM_HEADER_WIDTH })
      .height(Constants.LISTITEM_ROW_HEIGHT)
      .padding({ left: $r('sys.float.ohos_id_card_margin_start'), right: $r('sys.float.ohos_id_card_margin_end') })
      .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
      .linearGradient((this.isTouch === 'true') ? {
          angle: 90,
          direction: GradientDirection.Right,
          colors: [['#DCEAF9', 0.0], ['#FAFAFA', 1.0]]
        } : {
          angle: 90,
          direction: GradientDirection.Right,
          colors: [[$r('sys.color.ohos_id_color_list_card_bg'), 1], [$r('sys.color.ohos_id_color_list_card_bg'), 1]]
        })
      .onTouch(event => {
        if (event === undefined) {
          return;
        }
        if (event.type === TouchType.Down) {
          this.isTouch = 'true';
        }
        if (event.type === TouchType.Up) {
          this.isTouch = '';
        }
      })
      .onClick(() => {
        router.pushUrl({ url: 'pages/permission-access-record' })
      })
    }
  }
}
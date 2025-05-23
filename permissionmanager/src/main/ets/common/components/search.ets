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

import Constants from '../utils/constant';
import { AppInfo, ApplicationObj } from '../model/typedef';

@Component
export struct textInput {
  @Link applicationItem: Array<AppInfo | ApplicationObj>; // application info array
  @Link searchResult: boolean; // search results
  @State oldApplicationItem: Array<AppInfo | ApplicationObj> = []; // Original application information array

  aboutToAppear() {
    this.oldApplicationItem = this.applicationItem;
  }

  build() {
    Column() {
      Flex({ alignContent: FlexAlign.Start }) {
        TextInput({ placeholder: $r('app.string.textInput_placeholder') })
          .backgroundColor($r('sys.color.comp_background_list_card'))
          .padding({ left: Constants.TEXTINPUT_PADDING_LEFT })
          .type(InputType.Normal)
          .border({
            width: Constants.TEXTINPUT_BORDER_WIDTH, color: $r('app.color.label_color_20'), radius: Constants.TEXTINPUT_BORDER_RADIUS
          })
          .placeholderColor(Color.Grey)
          .placeholderFont({
            size: Constants.TEXT_MIDDLE_FONT_SIZE,
            weight: FontWeight.Normal,
            family: 'sans-serif',
            style: FontStyle.Normal
          })
          .caretColor($r('sys.color.font_secondary'))
          .height(Constants.TEXTINPUT_HEIGHT)
          .onChange((value: string) => {
            if (value === '' || value === null) {
              this.applicationItem = this.oldApplicationItem;
            } else {
              this.applicationItem = this.oldApplicationItem.filter((item: AppInfo | ApplicationObj) => {
                  return String(item.label).indexOf(value) > -1;
              })
            }
            if (this.applicationItem.length) {
              this.searchResult = true;
            } else {
              this.searchResult = false;
            }
          })
        Button().defaultFocus(true).opacity(0).position({ x: '-100%' })
        Image($r('app.media.ic_public_search_filled'))
          .objectFit(ImageFit.Contain)
          .width(Constants.TEXTINPUT_IMAGE_WIDTH)
          .height(Constants.TEXTINPUT_IMAGE_HEIGHT)
          .position({ x: Constants.TEXTINPUT_IMAGE_MARGIN_LEFT, y: Constants.TEXTINPUT_IMAGE_MARGIN_TOP })
      }
    }
  }
}
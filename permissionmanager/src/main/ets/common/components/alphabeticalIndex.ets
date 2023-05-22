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

@Component
export struct alphabetIndexerComponent {
  private value: string[] = [
    '#',
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z'
  ]; // Array of alphabetically indexed names
  @Link applicationItem: Array<any>; // application info array
  @State index: number = 0; // alphabetical index
  @State oldApplicationItem: Array<any> = []; // Original application information array

  aboutToAppear() {
    this.oldApplicationItem = this.applicationItem;
  }

  build() {
    AlphabetIndexer({ arrayValue: this.value, selected: this.index })
      .color($r('sys.color.ohos_id_color_text_secondary'))
      .selectedColor($r('sys.color.ohos_id_color_text_primary_activated')) // selected color
      .popupColor($r('sys.color.ohos_id_color_text_primary_activated')) // popover color
      .selectedBackgroundColor($r('app.color.selected_Background_Color')) // Check background color
      .popupBackground($r('sys.color.ohos_id_color_card_bg')) // popover background color
      .usingPopup(true) // whether to show a popup
      .selectedFont({ size: Constants.ALPHABETINDEXER_SELECTEDFONT_SIZE, weight: FontWeight.Bolder }) // selected style
      .popupFont({ size: Constants.ALPHABETINDEXER_POPUPFONT_SIZE, weight: FontWeight.Bolder }) // Demo of the popup
      .itemSize(Constants.ALPHABETINDEXER_ITEMSIZE) // size square of each item
      .alignStyle(IndexerAlign.Left) // Align left
      .onSelect((index: number) => {
        this.index = index;
        if (this.value[index] === '#') {
          this.applicationItem = this.oldApplicationItem;
        } else {
          this.applicationItem = this.oldApplicationItem.filter((item) => {
            return item.alphabeticalIndex.toUpperCase() === this.value[index];
          })
        }
      })
      .height(Constants.ALPHABETINDEXER_HEIGHT)
      .width(Constants.ALPHABETINDEXER_WIDTH)
  }
}
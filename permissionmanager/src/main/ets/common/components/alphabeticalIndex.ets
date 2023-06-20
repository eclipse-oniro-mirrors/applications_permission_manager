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
import { indexValue, appSort } from '../utils/utils';

@Component
export struct alphabetIndexerComponent {
  @Link applicationItem: Array<any>; // application info array
  @Link index: number; // alphabetical index

  build() {
    AlphabetIndexer({ arrayValue: indexValue, selected: this.index })
      .color($r('sys.color.ohos_id_color_text_secondary'))
      .selectedColor($r('sys.color.ohos_id_color_text_primary_activated')) // selected color
      .popupColor($r('sys.color.ohos_id_color_text_primary_activated')) // popover color
      .popupBackground($r('sys.color.ohos_id_color_card_bg')) // popover background color
      .usingPopup(true) // whether to show a popup
      .font({ size: $r('sys.float.ohos_id_text_size_body3') })
      .popupFont({ size: $r('sys.float.ohos_id_text_size_headline7') }) // Demo of the popup
      .onSelect((index: number) => {
        const value = indexValue[index];
        if (value === '#') {
          let item = appSort(this.applicationItem)[0];
          indexValue.includes(item.alphabeticalIndex.toUpperCase()) ? '' : globalThis.scroller.scrollToIndex(0);
          return;
        }
        for (let i = 0; i < this.applicationItem.length; i++) {
          let item = appSort(this.applicationItem)[i];
          if (item.alphabeticalIndex.toUpperCase() === value) {
            globalThis.scroller.scrollToIndex(i);
            return;
          }
        }
      })
      .height(Constants.FULL_HEIGHT)
      .constraintSize({ maxHeight: Constants.ALPHABETINDEXER_HEIGHT })
      .width(Constants.APPLICATION_ALPHABETINDEX_WIDTH)
  }
}
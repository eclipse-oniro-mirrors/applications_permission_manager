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
import { indexValue, sortByName } from '../utils/utils';
import { GlobalContext } from '../utils/globalContext';
import { AppInfo, ApplicationObj } from '../utils/typedef';

@Component
export struct alphabetIndexerComponent {
  @Link applicationItem: Array<AppInfo | ApplicationObj>; // application info array
  @Link index: number; // alphabetical index
  @State usingPopup: boolean = false;

  aboutToAppear() {
    const this_ = this;
    setTimeout(() => {
      this_.usingPopup = true;
    }, 1000)
  }

  build() {
    AlphabetIndexer({ arrayValue: indexValue, selected: this.index })
      .color($r('sys.color.ohos_id_color_text_secondary'))
      .selectedColor($r('sys.color.ohos_id_color_text_primary_activated')) // selected color
      .popupColor($r('sys.color.ohos_id_color_text_primary_activated')) // popover color
      .popupBackground($r('sys.color.ohos_id_color_card_bg')) // popover background color
      .usingPopup(this.usingPopup) // whether to show a popup
      .font({ size: $r('sys.float.ohos_id_text_size_body3') })
      .popupFont({ size: $r('sys.float.ohos_id_text_size_headline7') }) // Demo of the popup
      .onSelect((index: number) => {
        const value = indexValue[index];
        let scroller: Scroller = GlobalContext.getContext().get('scroller') as Scroller;
        for (let i = 0; i < this.applicationItem.length; i++) {
          let item = sortByName(this.applicationItem)[i];
          if (item.indexTag === value) {
            scroller.scrollToIndex(i);
            return;
          }
        }
      })
      .height(Constants.FULL_HEIGHT)
      .constraintSize({ maxHeight: Constants.ALPHABETINDEXER_HEIGHT })
      .width(Constants.APPLICATION_ALPHABETINDEX_WIDTH)
  }
}
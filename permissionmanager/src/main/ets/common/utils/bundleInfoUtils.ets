/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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

import { CommonUtils } from './commonUtils';

export class BundleInfoUtils {
  /**
   *
   *
   */
  private static readonly zh: string = '阿八嚓哒妸发旮哈靃讥咔垃呣拏噢妑七呥仨它唾畖窊夕丫帀';
  private static readonly en: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  /**
   *
   *
   */
  static getStringZh(input: string): string {
    let result: string = '';
    let upperCaseStr = input.toLocaleUpperCase();
    let regex: RegExp = new RegExp('[A-Z]')
    for (let i = 0; i < input.length; i++) {
      if (upperCaseStr[i].match(regex)) {
        let index = upperCaseStr.charCodeAt(i) - 'A'.charCodeAt(0);
        let ch = BundleInfoUtils.zh.charAt(index);
        result += ch;
      } else {
        result += upperCaseStr[i];
      }
    }
    return result;
  }

  /**
   *
   *
   */
  static findZhIndex(zhCharacter: string): string {
    if (CommonUtils.isEmpty(zhCharacter) || zhCharacter.localeCompare(BundleInfoUtils.zh[0], 'zh') < 0) {
      return '#';
    }
    for (let left = 0; left < BundleInfoUtils.zh.length - 1; left++) {
      let next = left + 1;
      if (
        zhCharacter.localeCompare(BundleInfoUtils.zh[left], 'zh') >= 0 &&
        zhCharacter.localeCompare(BundleInfoUtils.zh[next], 'zh') < 0
      ) {
        return BundleInfoUtils.en[left];
      }
      if (next === BundleInfoUtils.zh.length - 1 && zhCharacter.localeCompare(BundleInfoUtils.zh[next], 'zh') >= 0) {
        return BundleInfoUtils.en[next];
      }
    }
    return '';
  }
  
}
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

export class CommonUtils {
  /**
   * Determines whether the object is unavailable
   * @param {str} string to be judged
   */
  static isInvalid(str: string): boolean {
    return str == null;
  }

  /**
   * String null
   * @param {str} Word string
   */
  static isEmpty(str: string): boolean {
    return CommonUtils.isInvalid(str) || str.trim().length == 0;
  }
  
}
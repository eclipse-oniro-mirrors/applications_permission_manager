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

import deviceInfo from '@ohos.deviceInfo';
import display from '@ohos.display';

export class DeviceUtil {
  constructor() {
  }

  public static isPC(): boolean {
    return deviceInfo.deviceType === '2in1';
  }

  public static isTablet(): boolean {
    return deviceInfo.deviceType === 'tablet';
  }

  // 折叠屏
  public static isFold(): boolean {
    try {
      return ((deviceInfo.deviceType === 'default' || deviceInfo.deviceType === 'phone') && display.isFoldable());
    } catch (error) {
      return false;
    }
  }

  // 直板机
  public static isCandyBar(): boolean {
    return ((deviceInfo.deviceType === 'default' || deviceInfo.deviceType === 'phone') && !DeviceUtil.isFold());
  }
}
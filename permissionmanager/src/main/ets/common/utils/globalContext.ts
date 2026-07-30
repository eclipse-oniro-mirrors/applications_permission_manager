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

import { bundleManager } from '@kit.AbilityKit';

const TAG = 'GlobalContext';

export class BundleInfoUtils {
  static async filterBundleInfos(bundleInfos: bundleManager.BundleInfo[]): Promise<bundleManager.BundleInfo[]> {
    let initialGroups: bundleManager.BundleInfo[] = [];
    for (let i = 0; i < bundleInfos.length; i++) {
      let info = bundleInfos[i];
      // Filter blank icon icon and text label resources
      try {
        await bundleManager.queryAbilityInfo({
          bundleName: info.name,
          action: 'action.system.home',
          entities: ['entity.system.home']
        }, bundleManager.AbilityFlag.GET_ABILITY_INFO_WITH_APPLICATION);
      } catch (error) {
        console.error(
          TAG + 'queryAbilityByWant catch app: ' + JSON.stringify(info.name) + 'err: ' + JSON.stringify(error)
        );
        continue;
      }
      initialGroups.push(info);
    }
    return initialGroups;
  }
}

export class GlobalContext {
  currentPermissionGroup: string;
  isVertical: boolean;
  bundleName: string;
  windowNum: number;
  dialogSet: Set<String>;

  public static getContext(): GlobalContext {
    if (!GlobalContext.instance) {
      GlobalContext.instance = new GlobalContext();
    }
    return GlobalContext.instance;
  }

  private constructor() {}
  private static instance: GlobalContext;
  private _objects = new Map<string, Object>();

  static load<T>(name: string): T {
    return globalThis[name];
  }

  static store(name: string, obj: Object): void {
    globalThis[name] = obj;
  }

  get(value: string): Object {
    return this._objects.get(value);
  }

  set(key: string, objectClass: Object): void {
    this._objects.set(key, objectClass);
  }

  public getWindowNum(): number {
    return globalThis.windowNum || 0;
  }

  public increaseAndGetWindowNum(): number {
    globalThis.windowNum ++;
    return globalThis.windowNum;
  }

  public decreaseAndGetWindowNum(): number {
    globalThis.windowNum --;
    return globalThis.windowNum;
  }

  public setAndGetWindowNum(num: number): number {
    globalThis.windowNum = num;
    return globalThis.windowNum || 0;
  }
}
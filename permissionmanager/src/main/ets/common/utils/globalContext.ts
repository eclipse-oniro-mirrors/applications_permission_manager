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

export class GlobalContext {
  currentPermissionGroup: string;
  isMuteSupported: boolean;
  isVertical: boolean;
  bundleName: string;
  globalState: string;
  windowNum: number;

  public static getContext(): GlobalContext {
    if (!GlobalContext.instance) {
      GlobalContext.instance = new GlobalContext();
    }
    return GlobalContext.instance;
  }

  private constructor() {}
  private static instance: GlobalContext;
  private _objects = new Map<string, Object>();

  static load(name: string): any {
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
}
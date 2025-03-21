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

import { BaseIntent } from '../common/base/BaseIntent';
import { ButtonStatus } from '../common/model/definition';
import { PermissionGroupConfig, CallerAppInfo } from '../common/model/typedef';
import common from '@ohos.app.ability.common';

export namespace GrantDialogIntent {

  export class InitIntent extends BaseIntent {
    public context: common.ServiceExtensionContext;

    constructor(context: common.ServiceExtensionContext) {
      super();
      this.context = context;
    }

    public getIntentTag(): string {
      return 'InitIntent';
    }
  }

  export class RefreshIntent extends BaseIntent {
    public context: common.ServiceExtensionContext;
    public callerAppInfo: CallerAppInfo;

    constructor(context: common.ServiceExtensionContext, callerAppInfo: CallerAppInfo) {
      super();
      this.context = context;
      this.callerAppInfo = callerAppInfo;
    }

    public getIntentTag(): string {
      return 'RefreshIntent';
    }
  }

  export class ClickIntent extends BaseIntent {
    public context: common.ServiceExtensionContext;
    public groupConfig: PermissionGroupConfig;
    public callerAppInfo: CallerAppInfo;
    public buttonStatus: ButtonStatus;

    constructor(
      context: common.ServiceExtensionContext,
      groupConfig: PermissionGroupConfig,
      callerAppInfo: CallerAppInfo,
      buttonStatus: ButtonStatus
    ) {
      super();
      this.context = context;
      this.groupConfig = groupConfig;
      this.callerAppInfo = callerAppInfo;
      this.buttonStatus = buttonStatus;
    }

    public getIntentTag(): string {
      return 'ClickIntent';
    }
  }
}
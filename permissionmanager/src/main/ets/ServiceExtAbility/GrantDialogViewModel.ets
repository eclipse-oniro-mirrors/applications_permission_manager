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

import { BaseViewModel, ProcessResult } from '../common/base/BaseViewModel';
import { BaseIntent } from '../common/base/BaseIntent';
import { GrantDialogModel } from './GrantDialogModel';
import { GrantDialogIntent } from './GrantDialogIntent';
import { GrantDialogViewState } from './GrantDialogViewState';
import { Permission } from '../common/model/definition';
import { CallerAppInfo } from '../common/model/typedef';
import { Log } from '../common/utils/utils';
import window from '@ohos.window';

export class GrantDialogViewModel extends BaseViewModel<GrantDialogModel, GrantDialogViewState> {
  private callerAppInfo: CallerAppInfo;
  private win: window.Window;

  constructor(callerAppInfo: CallerAppInfo, win: window.Window) {
    super();
    this.callerAppInfo = callerAppInfo;
    this.win = win;
  }

  private async processInitIntent(
    viewState: GrantDialogViewState, model: GrantDialogModel, intention: GrantDialogIntent.InitIntent
  ): Promise<ProcessResult> {
    if (this.callerAppInfo.reqPerms.includes(Permission.READ_PASTEBOARD)) {
      viewState.pasteBoardName = model.getPasteBoardInfo();
    }
    viewState.curIndex = 0;
    viewState.appName = model.getAppName(this.callerAppInfo.bundleName);
    viewState.locationFlag = model.initLocationFlag(this.callerAppInfo);
    viewState.grantGroups = model.getGrantGroups(
      this.callerAppInfo, intention.context, viewState.appName, viewState.locationFlag, viewState.pasteBoardName
    );
    if (viewState.grantGroups.length === 0) {
      Log.error(`grantGroups length is 0, terminate.`);
      model.terminateWithResult(intention.context, this.win, this.callerAppInfo);
    }
    viewState.grantGroups.forEach((groupConfig) => {
      Log.info(`group: ${groupConfig.groupName}.`);
      if (groupConfig.title === '') {
        Log.error(`get resource faild, terminate.`);
        model.terminateWithResult(intention.context, this.win, this.callerAppInfo);
      }
    })
    return ProcessResult.SUCCESS;
  }

  private async processRefreshIntent(
    viewState: GrantDialogViewState, model: GrantDialogModel, intention: GrantDialogIntent.RefreshIntent
  ): Promise<ProcessResult> {
    if (this.callerAppInfo.reqPerms.includes(Permission.READ_PASTEBOARD)) {
      viewState.pasteBoardName = model.getPasteBoardInfo();
    }
    viewState.appName = model.getAppName(intention.callerAppInfo.bundleName);
    viewState.grantGroups = model.getGrantGroups(
      intention.callerAppInfo, intention.context, viewState.appName, viewState.locationFlag, viewState.pasteBoardName
    );
    return ProcessResult.SUCCESS;
  }

  private async processClickIntent(
    viewState: GrantDialogViewState, model: GrantDialogModel, intention: GrantDialogIntent.ClickIntent
  ): Promise<ProcessResult> {
    await model.clickHandle(
      intention.groupConfig, intention.callerAppInfo, viewState.locationFlag, intention.buttonStatus
    );
    if (viewState.curIndex === viewState.grantGroups.length - 1) {
      let timer: number = setTimeout(() => {
        model.terminateWithResult(intention.context, this.win, intention.callerAppInfo);
        clearTimeout(timer);
      }, 200);
      return ProcessResult.SUCCESS;
    } else {
      let nextIndex = viewState.curIndex + 1;
      viewState.curIndex = nextIndex >= viewState.grantGroups.length ? viewState.grantGroups.length - 1 : nextIndex;
    }
    return ProcessResult.SUCCESS;
  }

  protected initModel(): GrantDialogModel {
    return new GrantDialogModel();
  }

  protected initViewState(): GrantDialogViewState {
    return new GrantDialogViewState();
  }

  protected async processIntentWithModel(
    intention: BaseIntent, model: GrantDialogModel, viewState: GrantDialogViewState
  ): Promise<ProcessResult> {
    if (intention instanceof GrantDialogIntent.InitIntent) {
      return await this.processInitIntent(viewState, model, intention);
    }
    if (intention instanceof GrantDialogIntent.RefreshIntent) {
      return await this.processRefreshIntent(viewState, model, intention);
    }
    if (intention instanceof GrantDialogIntent.ClickIntent) {
      return await this.processClickIntent(viewState, model, intention);
    }
    return ProcessResult.FAIL;
  }
}
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

import { Log } from '../utils/utils';
import { BaseIntent } from './BaseIntent';
import { BaseModel } from './BaseModel';
import { BaseState } from './BaseState';

export enum ProcessResult {
  FAIL = 0,
  SUCCESS = 1
}

export abstract class BaseViewModel<M extends BaseModel, S extends BaseState> {
  private _model?: M;
  private _viewState?: S;

  /**
   * 获取界面状态
   * return 界面状态
   */
  public getViewState(): S {
    if (this._viewState === null || this._viewState === undefined) {
      this._viewState = this.initViewState();
    }
    return this._viewState;
  }

  /**
   * 异步的方式执行intention
   * @param intention view的意图
   * return 执行结果
   */
  public async processIntent(intention: BaseIntent): Promise<ProcessResult> {
    Log.info(`start processIntent: ${intention.getIntentTag()}.`);
    if (this._model === null || this._model === undefined) {
      this._model = this.initModel();
    }
    if (this._viewState === null || this._viewState === undefined) {
      this._viewState = this.initViewState();
    }
    if (this._model !== null && this._viewState !== null) {
      try {
        return await this.processIntentWithModel(intention, this._model, this._viewState);
      } catch (err) {
        Log.error(`error when process intention: ${intention.getIntentTag()}.`);
      }
    }
    return ProcessResult.FAIL;
  }

  /**
   * 同步的方式执行intention
   * @param intention view的意图
   * return 执行结果
   */
  public processIntentSync(intention: BaseIntent): ProcessResult {
    Log.info(`start processIntent: ${intention.getIntentTag()}.`);
    if (this._model === null || this._model === undefined) {
      this._model = this.initModel();
    }
    if (this._viewState === null || this._viewState === undefined) {
      this._viewState = this.initViewState();
    }
    if (this._model !== null && this._viewState !== null) {
      try {
        return this.processIntentWithModelSync(intention, this._model, this._viewState);
      } catch (err) {
        Log.error(`error when process intention: ${intention.getIntentTag()}.`);
      }
    }
    return ProcessResult.FAIL;
  }

  /**
   * 初始化逻辑处理类，子类需要实现这个方法
   * return 逻辑处理类
   */
  protected abstract initModel(): M;

  /**
   * 初始化界面状态，子类需要实现这个方法
   * return 界面状态
   */
  protected abstract initViewState(): S;

  /**
   * 异步的方式处理intention
   * @param intention view的意图
   * @param model 逻辑处理类
   * @param viewState 界面状态
   * return 界面状态
   */
  protected abstract processIntentWithModel(intention: BaseIntent, model: M, viewState: S): Promise<ProcessResult>;

  /**
   * 同步的方式处理intention
   * @param intention view的意图
   * @param model 逻辑处理类
   * @param viewState 界面状态
   * return 界面状态
   */
  protected processIntentWithModelSync(intention: BaseIntent, model: M, viewState: S): ProcessResult {
    return ProcessResult.SUCCESS;
  }

}
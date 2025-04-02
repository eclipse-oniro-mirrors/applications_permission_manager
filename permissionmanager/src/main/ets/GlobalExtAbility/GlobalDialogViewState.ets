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

import { BaseState } from '../common/base/BaseState';

@Observed
export class GlobalDialogViewState extends BaseState {
  // 全局开关类型
  public type: string | undefined = '';

  // 全局弹窗标题
  public title: ResourceStr = '';

  // 全局弹窗文本
  public text: ResourceStr = '';

}
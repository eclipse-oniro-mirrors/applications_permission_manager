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
import { PermissionGroupConfig } from '../common/model/typedef';
import Constants from '../common/utils/constant';

@Observed
export class GrantDialogViewState extends BaseState {
  // 授权应用名
  public appName: string | undefined = '';

  // 授权权限组列表
  public grantGroups: PermissionGroupConfig[] = [];

  // 当前展示的权限组索引
  public curIndex: number = 0;

  // 剪贴板内容来源应用名
  public pasteBoardName: string = '';

  // 位置权限组状态
  public locationFlag: number = Constants.LOCATION_NONE;

}
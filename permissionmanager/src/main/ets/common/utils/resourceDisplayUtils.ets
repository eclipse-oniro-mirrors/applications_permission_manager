/*
 * Copyright (c) 2026 Huawei Device Co., Ltd.
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

import common from '@ohos.app.ability.common';
import { Permission } from '../model/definition';
import { AppInfo } from '../model/typedef';
import { getPermissionLabel, Log } from './utils';

/**
 * Safely convert a resource object to a string and return an empty string when the resource is
 * missing or cannot be read.
 */
export function getTextFromResource(context: common.UIAbilityContext, resource: ResourceStr): string {
  if (typeof resource === 'string') {
    return resource;
  }
  if (resource === undefined || resource.id === undefined || resource.id === 0) {
    return '';
  }
  try {
    return context.resourceManager.getStringSync(resource.id);
  } catch (error) {
    Log.error('GetTextFromResource error: ' + JSON.stringify(error));
    return '';
  }
}

/**
 * Resolve the application display name, preferring the resource object and then falling back to
 * the resource ID or default name.
 */
export async function resolveAppLabel(
  context: common.UIAbilityContext,
  info: AppInfo,
  fallbackLabel: string = info.label || info.bundleName || ''
): Promise<string> {
  const labelResourceId = info.labelResource?.id ?? 0;
  const labelId = info.labelId ?? 0;
  if (labelResourceId === 0 && labelId === 0) {
    return fallbackLabel;
  }
  try {
    if (labelResourceId !== 0) {
      return await context.resourceManager.getStringValue(info.labelResource);
    }
    let resourceManager = context.createBundleContext(info.bundleName).resourceManager;
    return await resourceManager.getStringValue(labelId);
  } catch (error) {
    Log.error('ResolveAppLabel error: ' + JSON.stringify(error));
    return fallbackLabel;
  }
}

/**
 * Resolve the application icon, preferring the resource object and then falling back to the
 * resource ID or default icon.
 */
export function resolveAppIcon(
  context: common.UIAbilityContext,
  info: AppInfo,
  fallbackIcon: ResourceStr | PixelMap = $r('app.media.icon')
): ResourceStr | PixelMap {
  const iconResourceId = info.iconResource?.id ?? 0;
  const iconId = info.iconId ?? 0;
  if (iconResourceId === 0 && iconId === 0) {
    return fallbackIcon;
  }
  try {
    if (iconResourceId !== 0) {
      let iconDescriptor = context.resourceManager.getDrawableDescriptor(info.iconResource);
      return iconDescriptor?.getPixelMap() ?? fallbackIcon;
    }
    let resourceManager = context.createBundleContext(info.bundleName).resourceManager;
    let iconDescriptor = resourceManager.getDrawableDescriptor(iconId);
    return iconDescriptor?.getPixelMap() ?? fallbackIcon;
  } catch (error) {
    Log.error('ResolveAppIcon error: ' + JSON.stringify(error));
    return fallbackIcon;
  }
}

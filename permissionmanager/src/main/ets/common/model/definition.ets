/*
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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

export enum Permission {
  LOCATION_IN_BACKGROUND = 'ohos.permission.LOCATION_IN_BACKGROUND',
  APPROXIMATELY_LOCATION = 'ohos.permission.APPROXIMATELY_LOCATION',
  LOCATION = 'ohos.permission.LOCATION',
  CAMERA = 'ohos.permission.CAMERA',
  MICROPHONE = 'ohos.permission.MICROPHONE',
  READ_CONTACTS = 'ohos.permission.READ_CONTACTS',
  WRITE_CONTACTS = 'ohos.permission.WRITE_CONTACTS',
  READ_CALENDAR = 'ohos.permission.READ_CALENDAR',
  WRITE_CALENDAR = 'ohos.permission.WRITE_CALENDAR',
  READ_WHOLE_CALENDAR = 'ohos.permission.READ_WHOLE_CALENDAR',
  WRITE_WHOLE_CALENDAR = 'ohos.permission.WRITE_WHOLE_CALENDAR',
  ACTIVITY_MOTION = 'ohos.permission.ACTIVITY_MOTION',
  READ_HEALTH_DATA = 'ohos.permission.READ_HEALTH_DATA',
  READ_IMAGEVIDEO = 'ohos.permission.READ_IMAGEVIDEO',
  WRITE_IMAGEVIDEO = 'ohos.permission.WRITE_IMAGEVIDEO',
  MEDIA_LOCATION = 'ohos.permission.MEDIA_LOCATION',
  READ_AUDIO = 'ohos.permission.READ_AUDIO',
  WRITE_AUDIO = 'ohos.permission.WRITE_AUDIO',
  READ_DOCUMENT = 'ohos.permission.READ_DOCUMENT',
  WRITE_DOCUMENT = 'ohos.permission.WRITE_DOCUMENT',
  READ_MEDIA = 'ohos.permission.READ_MEDIA',
  WRITE_MEDIA = 'ohos.permission.WRITE_MEDIA',
  APP_TRACKING_CONSENT = 'ohos.permission.APP_TRACKING_CONSENT',
  GET_INSTALLED_BUNDLE_LIST = 'ohos.permission.GET_INSTALLED_BUNDLE_LIST',
  DISTRIBUTED_DATASYNC = 'ohos.permission.DISTRIBUTED_DATASYNC',
  ACCESS_BLUETOOTH = 'ohos.permission.ACCESS_BLUETOOTH',
  READ_PASTEBOARD = 'ohos.permission.READ_PASTEBOARD',
  READ_WRITE_DOWNLOAD_DIRECTORY = 'ohos.permission.READ_WRITE_DOWNLOAD_DIRECTORY',
  READ_WRITE_DESKTOP_DIRECTORY = 'ohos.permission.READ_WRITE_DESKTOP_DIRECTORY',
  READ_WRITE_DOCUMENTS_DIRECTORY = 'ohos.permission.READ_WRITE_DOCUMENTS_DIRECTORY',
  ACCESS_NEARLINK = 'ohos.permission.ACCESS_NEARLINK',
  CUSTOM_SCREEN_CAPTURE = 'ohos.permission.CUSTOM_SCREEN_CAPTURE'
}

export enum PermissionGroup {
  LOCATION = 'LOCATION',
  CAMERA = 'CAMERA',
  MICROPHONE = 'MICROPHONE',
  CONTACTS = 'CONTACTS',
  CALENDAR = 'CALENDAR',
  SPORT = 'SPORT',
  HEALTH = 'HEALTH',
  IMAGE_AND_VIDEOS = 'IMAGE_AND_VIDEOS',
  AUDIOS = 'AUDIOS',
  DOCUMENTS = 'DOCUMENTS',
  ADS = 'ADS',
  GET_INSTALLED_BUNDLE_LIST = 'GET_INSTALLED_BUNDLE_LIST',
  DISTRIBUTED_DATASYNC = 'DISTRIBUTED_DATASYNC',
  BLUETOOTH = 'BLUETOOTH',
  PASTEBOARD = 'PASTEBOARD',
  FOLDER = 'FOLDER',
  DOWNLOAD_DIRECTORY = 'DOWNLOAD_DIRECTORY',
  DESKTOP_DIRECTORY = 'DESKTOP_DIRECTORY',
  DOCUMENTS_DIRECTORY = 'DOCUMENTS_DIRECTORY',
  NEARLINK = 'NEARLINK',
  CUSTOM_SCREEN_CAPTURE = 'CUSTOM_SCREEN_CAPTURE',
  OTHER = 'OTHER'
}

export enum ButtonStatus {
  ALLOW = 'ALLOW',
  DENY = 'DENY',
  CANCEL = 'CANCEL',
  THIS_TIME_ONLY = 'THIS_TIME_ONLY',
  ALLOW_THIS_TIME = 'ALLOW_THIS_TIME',
  ALLOW_ONLY_DURING_USE = 'ALLOW_ONLY_DURING_USE'
}

export enum ClickOption {
  // ALLOW/THIS_TIME_ONLY/ALLOW_THIS_TIME/ALLOW_ONLY_DURING_USE
  GRANT = 'GRANT',
  // DENY
  DENY = 'DENY',
  // CANCEL
  CANCEL = 'CANCEL'
}

export enum PermissionOption {
  // 允许
  GRANT = 'GRANT',
  // 禁止
  REVOKE = 'REVOKE',
  // 不操作
  SKIP = 'SKIP'
}

export enum PermissionType {
  // 允许
  GRANT = 0,
  // 弹窗失败
  FAILED = 1,
  // 取消
  CANCELED = 2,
}
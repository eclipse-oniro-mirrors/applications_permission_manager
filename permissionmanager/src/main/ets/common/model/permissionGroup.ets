/*
 * Copyright (c) 2022 Huawei Device Co., Ltd.
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

import { PermissionInfo, GroupInfo } from './typedef';
import { Permission, PermissionGroup, ButtonStatus } from './definition';

export const permissionInfos: Map<Permission, PermissionInfo> = new Map([
    [Permission.LOCATION_IN_BACKGROUND, new PermissionInfo(Permission.LOCATION_IN_BACKGROUND, PermissionGroup.LOCATION, $r('sys.string.ohos_lab_location_in_background'), 0)],
    [Permission.APPROXIMATELY_LOCATION, new PermissionInfo(Permission.APPROXIMATELY_LOCATION, PermissionGroup.LOCATION, $r('sys.string.ohos_lab_approximately_location'), 0)],
    [Permission.LOCATION, new PermissionInfo(Permission.LOCATION, PermissionGroup.LOCATION, $r('sys.string.ohos_lab_location'), 0)],
    [Permission.CAMERA, new PermissionInfo(Permission.CAMERA, PermissionGroup.CAMERA, $r('sys.string.ohos_lab_camera'), 1)],
    [Permission.MICROPHONE, new PermissionInfo(Permission.MICROPHONE, PermissionGroup.MICROPHONE, $r('sys.string.ohos_lab_microphone'), 2)],
    [Permission.READ_CONTACTS, new PermissionInfo(Permission.READ_CONTACTS, PermissionGroup.CONTACTS, $r('sys.string.ohos_lab_read_contacts'), 3, 'app.string.enable_description_read_contacts', $r('app.string.forbidden_description_read_contacts'))],
    [Permission.WRITE_CONTACTS, new PermissionInfo(Permission.WRITE_CONTACTS, PermissionGroup.CONTACTS, $r('sys.string.ohos_lab_write_contacts'), 3, 'app.string.enable_description_write_contacts', $r('app.string.forbidden_description_write_contacts'))],
    [Permission.READ_CALENDAR, new PermissionInfo(Permission.READ_CALENDAR, PermissionGroup.CALENDAR, $r('sys.string.ohos_lab_read_calendar'), 4, 'app.string.enable_description_read_calendar', $r('app.string.forbidden_description_read_calendar'))],
    [Permission.WRITE_CALENDAR, new PermissionInfo(Permission.WRITE_CALENDAR, PermissionGroup.CALENDAR, $r('sys.string.ohos_lab_write_calendar'), 4, 'app.string.enable_description_write_calendar', $r('app.string.forbidden_description_write_calendar'))],
    [Permission.READ_WHOLE_CALENDAR, new PermissionInfo(Permission.READ_WHOLE_CALENDAR, PermissionGroup.CALENDAR, $r('sys.string.ohos_lab_read_whole_calendar'), 4, 'app.string.enable_description_read_whole_calendar', $r('app.string.forbidden_description_read_whole_calendar'))],
    [Permission.WRITE_WHOLE_CALENDAR, new PermissionInfo(Permission.WRITE_WHOLE_CALENDAR, PermissionGroup.CALENDAR, $r('sys.string.ohos_lab_write_whole_calendar'), 4, 'app.string.enable_description_write_whole_calendar', $r('app.string.forbidden_description_write_whole_calendar'))],
    [Permission.ACTIVITY_MOTION, new PermissionInfo(Permission.ACTIVITY_MOTION, PermissionGroup.SPORT, $r('sys.string.ohos_lab_activity_motion'), 5)],
    [Permission.READ_HEALTH_DATA, new PermissionInfo(Permission.READ_HEALTH_DATA, PermissionGroup.HEALTH, $r('sys.string.ohos_lab_read_health_data'), 6)],
    [Permission.READ_IMAGEVIDEO, new PermissionInfo(Permission.READ_IMAGEVIDEO, PermissionGroup.IMAGE_AND_VIDEOS, $r('sys.string.ohos_desc_read_imagevideo'), 8)],
    [Permission.WRITE_IMAGEVIDEO, new PermissionInfo(Permission.WRITE_IMAGEVIDEO, PermissionGroup.IMAGE_AND_VIDEOS, $r('sys.string.ohos_desc_write_imagevideo'), 8)],
    [Permission.MEDIA_LOCATION, new PermissionInfo(Permission.MEDIA_LOCATION, PermissionGroup.IMAGE_AND_VIDEOS, $r('sys.string.ohos_lab_media_location'), 8)],
    [Permission.READ_AUDIO, new PermissionInfo(Permission.READ_AUDIO, PermissionGroup.AUDIOS, $r('sys.string.ohos_desc_read_audio'), 9)],
    [Permission.WRITE_AUDIO, new PermissionInfo(Permission.WRITE_AUDIO, PermissionGroup.AUDIOS, $r('sys.string.ohos_desc_write_audio'), 9)],
    [Permission.READ_DOCUMENT, new PermissionInfo(Permission.READ_DOCUMENT, PermissionGroup.DOCUMENTS, $r('sys.string.ohos_desc_read_document'), 10)],
    [Permission.WRITE_DOCUMENT, new PermissionInfo(Permission.WRITE_DOCUMENT, PermissionGroup.DOCUMENTS, $r('sys.string.ohos_desc_write_document'), 10)],
    [Permission.READ_MEDIA, new PermissionInfo(Permission.READ_MEDIA, PermissionGroup.DOCUMENTS, $r('sys.string.ohos_lab_read_media'), 10)],
    [Permission.WRITE_MEDIA, new PermissionInfo(Permission.WRITE_MEDIA, PermissionGroup.DOCUMENTS, $r('sys.string.ohos_lab_write_media'), 10)],
    [Permission.APP_TRACKING_CONSENT, new PermissionInfo(Permission.APP_TRACKING_CONSENT, PermissionGroup.ADS, $r('sys.string.ohos_lab_app_tracking_consent'), 11)],
    [Permission.GET_INSTALLED_BUNDLE_LIST, new PermissionInfo(Permission.GET_INSTALLED_BUNDLE_LIST, PermissionGroup.GET_INSTALLED_BUNDLE_LIST, $r('sys.string.ohos_lab_get_installed_bundle_list'), 12)],
    [Permission.DISTRIBUTED_DATASYNC, new PermissionInfo(Permission.DISTRIBUTED_DATASYNC, PermissionGroup.DISTRIBUTED_DATASYNC, $r('sys.string.ohos_lab_distributed_datasync'), 13)],
    [Permission.ACCESS_BLUETOOTH, new PermissionInfo(Permission.ACCESS_BLUETOOTH, PermissionGroup.BLUETOOTH, $r('sys.string.ohos_lab_access_bluetooth'), 14)],
    [Permission.READ_PASTEBOARD, new PermissionInfo(Permission.READ_PASTEBOARD, PermissionGroup.PASTEBOARD, $r('sys.string.ohos_lab_read_pasteboard'), 15)],
    [Permission.READ_WRITE_DOWNLOAD_DIRECTORY, new PermissionInfo(Permission.READ_WRITE_DOWNLOAD_DIRECTORY, PermissionGroup.FOLDER, $r('sys.string.ohos_lab_read_write_download_directory'), 16)],
    [Permission.READ_WRITE_DESKTOP_DIRECTORY, new PermissionInfo(Permission.READ_WRITE_DESKTOP_DIRECTORY, PermissionGroup.FOLDER, $r('sys.string.ohos_lab_read_write_desktop_directory'), 16)],
    [Permission.READ_WRITE_DOCUMENTS_DIRECTORY, new PermissionInfo(Permission.READ_WRITE_DOCUMENTS_DIRECTORY, PermissionGroup.FOLDER, $r('sys.string.ohos_lab_read_write_documents_directory'), 16)],
    [Permission.ACCESS_NEARLINK, new PermissionInfo(Permission.ACCESS_NEARLINK, PermissionGroup.NEARLINK, $r('sys.string.ohos_lab_access_nearlink'), 17)],
    [Permission.CUSTOM_SCREEN_CAPTURE, new PermissionInfo(Permission.CUSTOM_SCREEN_CAPTURE, PermissionGroup.CUSTOM_SCREEN_CAPTURE, $r('sys.string.ohos_lab_custom_screen_capture'), 18)]
])

export const groups: GroupInfo[] = [
    new GroupInfo(PermissionGroup.LOCATION, $r('app.string.groupName_location'), 'app.string.group_label_location', $r('app.media.ic_public_gps'), [], '', [Permission.LOCATION_IN_BACKGROUND, Permission.APPROXIMATELY_LOCATION, Permission.LOCATION], [ButtonStatus.ALLOW_ONLY_DURING_USE, ButtonStatus.ALLOW_THIS_TIME, ButtonStatus.CANCEL], true, 'app.string.enable_description_location', $r('app.string.forbidden_description_location')),
    new GroupInfo(PermissionGroup.CAMERA, $r('app.string.groupName_camera'), 'app.string.group_label_camera', $r('app.media.ic_public_camera'), [], '', [Permission.CAMERA], [ButtonStatus.DENY, ButtonStatus.ALLOW], true, 'app.string.enable_description_camera', $r('app.string.forbidden_description_camera')),
    new GroupInfo(PermissionGroup.MICROPHONE, $r('app.string.groupName_microphone'), 'app.string.group_label_microphone', $r('app.media.ic_public_voice'), [], '', [Permission.MICROPHONE], [ButtonStatus.DENY, ButtonStatus.ALLOW], true, 'app.string.enable_description_microphone', $r('app.string.forbidden_description_microphone')),
    new GroupInfo(PermissionGroup.CONTACTS, $r('app.string.groupName_contacts'), 'app.string.group_label_contacts', $r('app.media.ic_public_contacts_group'), [], '', [Permission.READ_CONTACTS, Permission.WRITE_CONTACTS], [ButtonStatus.DENY, ButtonStatus.ALLOW], false),
    new GroupInfo(PermissionGroup.CALENDAR, $r('app.string.groupName_calendar'), 'app.string.group_label_calendar', $r('app.media.ic_public_calendar'), [], '', [Permission.READ_CALENDAR, Permission.WRITE_CALENDAR, Permission.READ_WHOLE_CALENDAR, Permission.WRITE_WHOLE_CALENDAR], [ButtonStatus.DENY, ButtonStatus.ALLOW], true),
    new GroupInfo(PermissionGroup.SPORT, $r('app.string.groupName_sport'), 'app.string.group_label_sport', $r('app.media.ic_sport'), [], '', [Permission.ACTIVITY_MOTION], [ButtonStatus.DENY, ButtonStatus.ALLOW], true, 'app.string.enable_description_sport', $r('app.string.forbidden_description_sport')),
    new GroupInfo(PermissionGroup.HEALTH, $r('app.string.groupName_health'), 'app.string.group_label_health', $r('app.media.ic_ssensor'), [], '', [Permission.READ_HEALTH_DATA], [ButtonStatus.DENY, ButtonStatus.ALLOW], true, 'app.string.enable_description_health', $r('app.string.forbidden_description_health')),
    new GroupInfo(PermissionGroup.OTHER, $r('app.string.groupName_other'), '', $r('app.media.ic_more'), [], '', [], [ButtonStatus.DENY, ButtonStatus.ALLOW], true),
    new GroupInfo(PermissionGroup.IMAGE_AND_VIDEOS, $r('sys.string.ohos_lab_read_imagevideo'), 'app.string.group_label_image_and_videos', $r('app.media.ic_public_picture'), [], '', [Permission.READ_IMAGEVIDEO, Permission.WRITE_IMAGEVIDEO, Permission.MEDIA_LOCATION], [ButtonStatus.DENY, ButtonStatus.ALLOW], false, 'app.string.enable_description_image', $r('app.string.forbidden_description_image')),
    new GroupInfo(PermissionGroup.AUDIOS, $r('sys.string.ohos_lab_read_audio'), 'app.string.group_label_audios', $r('app.media.ic_public_audio'), [], '', [Permission.READ_AUDIO, Permission.WRITE_AUDIO], [ButtonStatus.DENY, ButtonStatus.ALLOW], false, 'app.string.enable_description_audios', $r('app.string.forbidden_description_audios')),
    new GroupInfo(PermissionGroup.DOCUMENTS, $r('sys.string.ohos_lab_read_document'), 'app.string.group_label_document', $r('app.media.ic_public_folder'), [], '', [Permission.READ_DOCUMENT, Permission.WRITE_DOCUMENT, Permission.READ_MEDIA, Permission.WRITE_MEDIA], [ButtonStatus.DENY, ButtonStatus.ALLOW], false, 'app.string.enable_description_documents', $r('app.string.forbidden_description_documents')),
    new GroupInfo(PermissionGroup.ADS, $r('app.string.groupName_ADS'), 'app.string.group_label_ADS', $r('app.media.track'), [], '', [Permission.APP_TRACKING_CONSENT], [ButtonStatus.DENY, ButtonStatus.ALLOW], false, 'app.string.enable_description_ADS', $r('app.string.forbidden_description_ADS')),
    new GroupInfo(PermissionGroup.GET_INSTALLED_BUNDLE_LIST, $r('app.string.groupName_appList'), 'app.string.group_label_appList', $r('app.media.ic_public_app_list'), [], '', [Permission.GET_INSTALLED_BUNDLE_LIST], [ButtonStatus.DENY, ButtonStatus.ALLOW], false, 'app.string.enable_description_appList', $r('app.string.forbidden_description_appList')),
    new GroupInfo(PermissionGroup.DISTRIBUTED_DATASYNC, $r('app.string.multi_device_collaboration'), 'app.string.group_label_distributed_datasync', $r('app.media.ic_multi_device_vector'), [], '', [Permission.DISTRIBUTED_DATASYNC], [ButtonStatus.DENY, ButtonStatus.ALLOW], false, 'app.string.enable_description_distributed_datasync', $r('app.string.forbidden_description_distributed_datasync')),
    new GroupInfo(PermissionGroup.BLUETOOTH, $r('app.string.groupName_bluetooth'), 'app.string.group_label_bluetooth', $r('app.media.ic_public_bluetooth'), [], '', [Permission.ACCESS_BLUETOOTH], [ButtonStatus.DENY, ButtonStatus.ALLOW], false, 'app.string.enable_description_bluetooth', $r('app.string.forbidden_description_bluetooth')),
    new GroupInfo(PermissionGroup.PASTEBOARD, $r('app.string.groupName_pasteboard'), 'app.string.group_label_pasteboard', $r('app.media.ic_clipboard'), [], '', [Permission.READ_PASTEBOARD], [ButtonStatus.DENY, ButtonStatus.THIS_TIME_ONLY], false, 'app.string.enable_description_pasteboard', $r('app.string.forbidden_description_pasteboard')),
    new GroupInfo(PermissionGroup.FOLDER, $r('app.string.groupName_folder'), 'app.string.group_label_folder', $r('app.media.ic_public_folder'), [], '', [Permission.READ_WRITE_DOWNLOAD_DIRECTORY, Permission.READ_WRITE_DESKTOP_DIRECTORY, Permission.READ_WRITE_DOCUMENTS_DIRECTORY], [ButtonStatus.DENY, ButtonStatus.ALLOW], false, 'app.string.enable_description_folder', $r('app.string.forbidden_description_folder')),
    new GroupInfo(PermissionGroup.NEARLINK, $r('app.string.groupName_nearLink'), 'app.string.group_label_nearLink', $r('app.media.ic_nearLink'), [], '', [Permission.ACCESS_NEARLINK], [ButtonStatus.DENY, ButtonStatus.ALLOW], false, 'app.string.enable_description_nearLink', $r('app.string.forbidden_description_nearLink')),
    new GroupInfo(PermissionGroup.CUSTOM_SCREEN_CAPTURE, $r('app.string.groupName_screenCapture'), 'app.string.group_label_screenCapture', $r('app.media.ic_public_screen_capture'), [], '', [Permission.CUSTOM_SCREEN_CAPTURE], [ButtonStatus.DENY, ButtonStatus.ALLOW], false, 'app.string.enable_description_screenCapture', $r('app.string.forbidden_description_screenCapture'))
];

export const userGrantPermissions: string[] = [
    Permission.LOCATION_IN_BACKGROUND,
    Permission.APPROXIMATELY_LOCATION,
    Permission.LOCATION,
    Permission.CAMERA,
    Permission.MICROPHONE,
    Permission.READ_CONTACTS,
    Permission.WRITE_CONTACTS,
    Permission.READ_CALENDAR,
    Permission.WRITE_CALENDAR,
    Permission.READ_WHOLE_CALENDAR,
    Permission.WRITE_WHOLE_CALENDAR,
    Permission.ACTIVITY_MOTION,
    Permission.READ_HEALTH_DATA,
    Permission.READ_IMAGEVIDEO,
    Permission.WRITE_IMAGEVIDEO,
    Permission.MEDIA_LOCATION,
    Permission.READ_AUDIO,
    Permission.WRITE_AUDIO,
    Permission.READ_DOCUMENT,
    Permission.WRITE_DOCUMENT,
    Permission.READ_MEDIA,
    Permission.WRITE_MEDIA,
    Permission.APP_TRACKING_CONSENT,
    Permission.GET_INSTALLED_BUNDLE_LIST,
    Permission.DISTRIBUTED_DATASYNC,
    Permission.ACCESS_BLUETOOTH,
    Permission.READ_PASTEBOARD,
    Permission.READ_WRITE_DOWNLOAD_DIRECTORY,
    Permission.READ_WRITE_DESKTOP_DIRECTORY,
    Permission.READ_WRITE_DOCUMENTS_DIRECTORY,
    Permission.ACCESS_NEARLINK,
    Permission.CUSTOM_SCREEN_CAPTURE
];

export const buttonResource: Map<ButtonStatus, Resource> = new Map([
    [ButtonStatus.ALLOW, $r('app.string.allow')],
    [ButtonStatus.DENY, $r('app.string.ban')],
    [ButtonStatus.CANCEL, $r('app.string.cancel')],
    [ButtonStatus.THIS_TIME_ONLY, $r('app.string.This_time_only')],
    [ButtonStatus.ALLOW_THIS_TIME, $r('app.string.allow_this_time')],
    [ButtonStatus.ALLOW_ONLY_DURING_USE, $r('app.string.allowed_only_during_use')]
])

export const showSubPermissionsGroup: string[] = [
    PermissionGroup.CALENDAR,
    PermissionGroup.CONTACTS,
];

export const polymorphismGroup: string[] = [
    PermissionGroup.LOCATION,
    PermissionGroup.FOLDER
]

export const globalGroup: string[] = [
    PermissionGroup.MICROPHONE,
    PermissionGroup.CAMERA
]
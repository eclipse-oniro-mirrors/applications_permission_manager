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
    [Permission.READ_CONTACTS, new PermissionInfo(Permission.READ_CONTACTS, PermissionGroup.CONTACTS, $r('sys.string.ohos_lab_read_contacts'), 3)],
    [Permission.WRITE_CONTACTS, new PermissionInfo(Permission.WRITE_CONTACTS, PermissionGroup.CONTACTS, $r('sys.string.ohos_lab_write_contacts'), 3)],
    [Permission.READ_CALENDAR, new PermissionInfo(Permission.READ_CALENDAR, PermissionGroup.CALENDAR, $r('sys.string.ohos_lab_read_calendar'), 5)],
    [Permission.WRITE_CALENDAR, new PermissionInfo(Permission.WRITE_CALENDAR, PermissionGroup.CALENDAR, $r('sys.string.ohos_lab_write_calendar'), 5)],
    [Permission.READ_WHOLE_CALENDAR, new PermissionInfo(Permission.READ_WHOLE_CALENDAR, PermissionGroup.CALENDAR, $r('sys.string.ohos_lab_read_whole_calendar'), 5)],
    [Permission.WRITE_WHOLE_CALENDAR, new PermissionInfo(Permission.WRITE_WHOLE_CALENDAR, PermissionGroup.CALENDAR, $r('sys.string.ohos_lab_write_whole_calendar'), 5)],
    [Permission.ACTIVITY_MOTION, new PermissionInfo(Permission.ACTIVITY_MOTION, PermissionGroup.SPORT, $r('app.string.group_name_sport'), 9)],
    [Permission.READ_HEALTH_DATA, new PermissionInfo(Permission.READ_HEALTH_DATA, PermissionGroup.HEALTH, $r('sys.string.ohos_lab_read_health_data'), 10)],
    [Permission.READ_IMAGEVIDEO, new PermissionInfo(Permission.READ_IMAGEVIDEO, PermissionGroup.IMAGE_AND_VIDEOS, $r('sys.string.ohos_desc_read_imagevideo'), 11)],
    [Permission.WRITE_IMAGEVIDEO, new PermissionInfo(Permission.WRITE_IMAGEVIDEO, PermissionGroup.IMAGE_AND_VIDEOS, $r('sys.string.ohos_desc_write_imagevideo'), 11)],
    [Permission.MEDIA_LOCATION, new PermissionInfo(Permission.MEDIA_LOCATION, PermissionGroup.IMAGE_AND_VIDEOS, $r('sys.string.ohos_lab_media_location'), 11)],
    [Permission.READ_AUDIO, new PermissionInfo(Permission.READ_AUDIO, PermissionGroup.AUDIOS, $r('sys.string.ohos_desc_read_audio'), 13)],
    [Permission.WRITE_AUDIO, new PermissionInfo(Permission.WRITE_AUDIO, PermissionGroup.AUDIOS, $r('sys.string.ohos_desc_write_audio'), 13)],
    [Permission.READ_DOCUMENT, new PermissionInfo(Permission.READ_DOCUMENT, PermissionGroup.DOCUMENTS, $r('sys.string.ohos_desc_read_document'), 15)],
    [Permission.WRITE_DOCUMENT, new PermissionInfo(Permission.WRITE_DOCUMENT, PermissionGroup.DOCUMENTS, $r('sys.string.ohos_desc_write_document'), 15)],
    [Permission.READ_MEDIA, new PermissionInfo(Permission.READ_MEDIA, PermissionGroup.DOCUMENTS, $r('sys.string.ohos_lab_read_media'), 15)],
    [Permission.WRITE_MEDIA, new PermissionInfo(Permission.WRITE_MEDIA, PermissionGroup.DOCUMENTS, $r('sys.string.ohos_lab_write_media'), 15)],
    [Permission.APP_TRACKING_CONSENT, new PermissionInfo(Permission.APP_TRACKING_CONSENT, PermissionGroup.ADS, $r('sys.string.ohos_lab_app_tracking_consent'), 16)],
    [Permission.GET_INSTALLED_BUNDLE_LIST, new PermissionInfo(Permission.GET_INSTALLED_BUNDLE_LIST, PermissionGroup.GET_INSTALLED_BUNDLE_LIST, $r('sys.string.ohos_lab_get_installed_bundle_list'), 17)],
    [Permission.DISTRIBUTED_DATASYNC, new PermissionInfo(Permission.DISTRIBUTED_DATASYNC, PermissionGroup.DISTRIBUTED_DATASYNC, $r('sys.string.ohos_lab_distributed_datasync'), 18)],
    [Permission.ACCESS_BLUETOOTH, new PermissionInfo(Permission.ACCESS_BLUETOOTH, PermissionGroup.DISTRIBUTED_DATASYNC, $r('sys.string.ohos_lab_access_bluetooth'), 18)],
    [Permission.READ_PASTEBOARD, new PermissionInfo(Permission.READ_PASTEBOARD, PermissionGroup.PASTEBOARD, $r('sys.string.ohos_lab_read_pasteboard'), 20)],
    [Permission.READ_WRITE_DOWNLOAD_DIRECTORY, new PermissionInfo(Permission.READ_WRITE_DOWNLOAD_DIRECTORY, PermissionGroup.FOLDER, $r('sys.string.ohos_lab_read_write_download_directory'), 21)],
    [Permission.READ_WRITE_DESKTOP_DIRECTORY, new PermissionInfo(Permission.READ_WRITE_DESKTOP_DIRECTORY, PermissionGroup.FOLDER, $r('sys.string.ohos_lab_read_write_desktop_directory'), 21)],
    [Permission.READ_WRITE_DOCUMENTS_DIRECTORY, new PermissionInfo(Permission.READ_WRITE_DOCUMENTS_DIRECTORY, PermissionGroup.FOLDER, $r('sys.string.ohos_lab_read_write_documents_directory'), 21)],
    [Permission.ACCESS_USER_FULL_DISK, new PermissionInfo(Permission.ACCESS_USER_FULL_DISK, PermissionGroup.FOLDER, $r('app.string.full_disk_folder'), 21)],
    [Permission.ACCESS_NEARLINK, new PermissionInfo(Permission.ACCESS_NEARLINK, PermissionGroup.DISTRIBUTED_DATASYNC, $r('sys.string.ohos_lab_access_nearlink'), 18)],
    [Permission.CUSTOM_SCREEN_CAPTURE, new PermissionInfo(Permission.CUSTOM_SCREEN_CAPTURE, PermissionGroup.CUSTOM_SCREEN_CAPTURE, $r('sys.string.ohos_lab_custom_screen_capture'), 23)],
    [Permission.FLOAT_VIEW, new PermissionInfo(Permission.FLOAT_VIEW, PermissionGroup.FLOAT_VIEW, $r('app.string.permission_label_float_view'), 25, 'app.string.enable_description_float_view', $r('app.string.forbidden_description_float_view'))],
    [Permission.CUSTOM_SCREEN_RECORDING, new PermissionInfo(Permission.CUSTOM_SCREEN_RECORDING, PermissionGroup.CUSTOM_SCREEN_RECORDING, $r('app.string.permission_label_screen_share'), 24, 'app.string.enable_description_screen_share', $r('app.string.forbidden_description_screen_share'))],
    [Permission.HOOK_KEY_EVENT, new PermissionInfo(Permission.HOOK_KEY_EVENT, PermissionGroup.HOOK_INPUT_EVENT, $r('app.string.permission_label_hook_input_event'), 26, 'app.string.enable_description_hook_input_event', $r('app.string.forbidden_description_hook_input_event'))],
    [Permission.CONTROL_DEVICE, new PermissionInfo(Permission.CONTROL_DEVICE, PermissionGroup.CONTROL_DEVICE, $r('app.string.permission_label_control_device'), 27, 'app.string.enable_description_control_device', $r('app.string.forbidden_description_control_device'))]
])

export const groups: GroupInfo[] = [
    new GroupInfo(PermissionGroup.LOCATION, $r('app.string.group_name_location'), 'app.string.group_label_location', $r('app.media.ic_public_gps'), [], '', [Permission.LOCATION_IN_BACKGROUND, Permission.APPROXIMATELY_LOCATION, Permission.LOCATION], [ButtonStatus.ALLOW_ONLY_DURING_USE, ButtonStatus.THIS_TIME_ONLY, ButtonStatus.DENY], true, 'app.string.enable_description_location', $r('app.string.forbidden_description_location')),
    new GroupInfo(PermissionGroup.CAMERA, $r('app.string.group_name_camera'), 'app.string.group_label_camera', $r('app.media.ic_public_camera'), [], '', [Permission.CAMERA], [ButtonStatus.DENY, ButtonStatus.ALLOW], true, 'app.string.enable_description_camera', $r('app.string.forbidden_description_camera')),
    new GroupInfo(PermissionGroup.MICROPHONE, $r('app.string.group_name_microphone'), 'app.string.group_label_microphone', $r('app.media.ic_public_voice'), [], '', [Permission.MICROPHONE], [ButtonStatus.DENY, ButtonStatus.ALLOW], true, 'app.string.enable_description_microphone', $r('app.string.forbidden_description_microphone')),
    new GroupInfo(PermissionGroup.CONTACTS, $r('app.string.group_name_contacts'), 'app.string.group_label_contacts', $r('app.media.ic_public_contacts_group'), [], '', [Permission.READ_CONTACTS, Permission.WRITE_CONTACTS], [ButtonStatus.DENY, ButtonStatus.ALLOW], true),
    new GroupInfo(PermissionGroup.WRITE_CONTACTS, $r('sys.string.ohos_lab_write_contacts'), 'app.string.group_label_contacts', $r('app.media.ic_public_contacts_group'), [], '', [Permission.WRITE_CONTACTS], [ButtonStatus.DENY, ButtonStatus.ALLOW], false, 'app.string.enable_description_write_contacts', $r('app.string.forbidden_description_write_contacts')),
    new GroupInfo(PermissionGroup.CALENDAR, $r('app.string.group_name_calendar'), 'app.string.group_label_calendar', $r('app.media.ic_public_calendar'), [], '', [Permission.READ_CALENDAR, Permission.WRITE_CALENDAR, Permission.READ_WHOLE_CALENDAR, Permission.WRITE_WHOLE_CALENDAR], [ButtonStatus.DENY, ButtonStatus.ALLOW], true),
    new GroupInfo(PermissionGroup.WRITE_CALENDAR, $r('sys.string.ohos_lab_write_calendar'), 'app.string.group_label_calendar', $r('app.media.ic_public_calendar'), [], '', [Permission.WRITE_CALENDAR], [ButtonStatus.DENY, ButtonStatus.ALLOW], false, 'app.string.enable_description_write_calendar', $r('app.string.forbidden_description_write_calendar')),
    new GroupInfo(PermissionGroup.READ_WHOLE_CALENDAR, $r('sys.string.ohos_lab_read_whole_calendar'), 'app.string.group_label_calendar', $r('app.media.ic_public_calendar'), [], '', [Permission.READ_WHOLE_CALENDAR], [ButtonStatus.DENY, ButtonStatus.ALLOW], false, 'app.string.enable_description_read_whole_calendar', $r('app.string.forbidden_description_read_whole_calendar')),
    new GroupInfo(PermissionGroup.WRITE_WHOLE_CALENDAR, $r('sys.string.ohos_lab_write_whole_calendar'), 'app.string.group_label_calendar', $r('app.media.ic_public_calendar'), [], '', [Permission.WRITE_WHOLE_CALENDAR], [ButtonStatus.DENY, ButtonStatus.ALLOW], false, 'app.string.enable_description_write_whole_calendar', $r('app.string.forbidden_description_write_whole_calendar')),
    new GroupInfo(PermissionGroup.SPORT, $r('app.string.group_name_sport'), 'app.string.group_label_sport', $r('app.media.ic_sport'), [], '', [Permission.ACTIVITY_MOTION], [ButtonStatus.DENY, ButtonStatus.ALLOW], true, 'app.string.enable_description_sport', $r('app.string.forbidden_description_sport')),
    new GroupInfo(PermissionGroup.HEALTH, $r('app.string.group_name_health'), 'app.string.group_label_health', $r('app.media.ic_ssensor'), [], '', [Permission.READ_HEALTH_DATA], [ButtonStatus.DENY, ButtonStatus.ALLOW], true, 'app.string.enable_description_health', $r('app.string.forbidden_description_health')),
    new GroupInfo(PermissionGroup.IMAGE_AND_VIDEOS, $r('sys.string.ohos_lab_read_imagevideo'), 'app.string.group_label_image_and_videos', $r('app.media.ic_public_picture'), [], '', [Permission.READ_IMAGEVIDEO, Permission.WRITE_IMAGEVIDEO, Permission.MEDIA_LOCATION], [ButtonStatus.DENY, ButtonStatus.ALLOW], true, 'app.string.enable_description_image', $r('app.string.forbidden_description_image')),
    new GroupInfo(PermissionGroup.WRITE_IMAGE_AND_VIDEO, $r('sys.string.ohos_desc_write_imagevideo'), 'app.string.group_label_image_and_videos', $r('app.media.ic_public_picture'), [], '', [Permission.WRITE_IMAGEVIDEO, Permission.MEDIA_LOCATION], [ButtonStatus.DENY, ButtonStatus.ALLOW], false, 'app.string.enable_description_image', $r('app.string.forbidden_description_image')),
    new GroupInfo(PermissionGroup.AUDIOS, $r('sys.string.ohos_lab_read_audio'), 'app.string.group_label_audios', $r('app.media.ic_public_audio'), [], '', [Permission.READ_AUDIO, Permission.WRITE_AUDIO], [ButtonStatus.DENY, ButtonStatus.ALLOW], true, 'app.string.enable_description_audios', $r('app.string.forbidden_description_audios')),
    new GroupInfo(PermissionGroup.WRITE_AUDIO, $r('sys.string.ohos_desc_write_audio'), 'app.string.group_label_audios', $r('app.media.ic_public_audio'), [], '', [Permission.WRITE_AUDIO], [ButtonStatus.DENY, ButtonStatus.ALLOW], false, 'app.string.enable_description_audios', $r('app.string.forbidden_description_audios')),
    new GroupInfo(PermissionGroup.DOCUMENTS, $r('sys.string.ohos_lab_read_document'), 'app.string.group_label_document', $r('app.media.ic_public_folder'), [], '', [Permission.READ_DOCUMENT, Permission.WRITE_DOCUMENT, Permission.READ_MEDIA, Permission.WRITE_MEDIA], [ButtonStatus.DENY, ButtonStatus.ALLOW], true, 'app.string.enable_description_documents', $r('app.string.forbidden_description_documents')),
    new GroupInfo(PermissionGroup.ADS, $r('app.string.group_name_ads'), 'app.string.group_label_ads', $r('app.media.ic_public_application_tracing'), [], '', [Permission.APP_TRACKING_CONSENT], [ButtonStatus.DENY, ButtonStatus.ALLOW], true, 'app.string.enable_description_ads', $r('app.string.forbidden_description_ads')),
    new GroupInfo(PermissionGroup.GET_INSTALLED_BUNDLE_LIST, $r('app.string.group_name_app_list'), 'app.string.group_label_app_list', $r('app.media.ic_public_app_list'), [], '', [Permission.GET_INSTALLED_BUNDLE_LIST], [ButtonStatus.DENY, ButtonStatus.ALLOW], true, 'app.string.enable_description_app_list', $r('app.string.forbidden_description_app_list')),
    new GroupInfo(PermissionGroup.DISTRIBUTED_DATASYNC, $r('app.string.multi_device_collaboration'), 'app.string.group_label_distributed_datasync', $r('app.media.ic_multi_device_vector'), [], '', [Permission.DISTRIBUTED_DATASYNC, Permission.ACCESS_BLUETOOTH, Permission.ACCESS_NEARLINK], [ButtonStatus.DENY, ButtonStatus.ALLOW], true, 'app.string.enable_description_distributed_datasync', $r('app.string.forbidden_description_distributed_datasync')),
    new GroupInfo(PermissionGroup.BLUETOOTH, $r('app.string.group_name_bluetooth'), 'app.string.group_label_bluetooth', $r('app.media.ic_public_bluetooth'), [], '', [Permission.ACCESS_BLUETOOTH], [ButtonStatus.DENY, ButtonStatus.ALLOW], false, 'app.string.enable_description_bluetooth', $r('app.string.forbidden_description_bluetooth')),
    new GroupInfo(PermissionGroup.PASTEBOARD, $r('app.string.group_name_pasteboard'), 'app.string.group_label_pasteboard', $r('app.media.ic_clipboard'), [], '', [Permission.READ_PASTEBOARD], [ButtonStatus.THIS_TIME_ONLY, ButtonStatus.ALWAYS_ALLOW, ButtonStatus.DENY], true, 'app.string.enable_description_pasteboard', $r('app.string.forbidden_description_pasteboard')),
    new GroupInfo(PermissionGroup.FOLDER, $r('app.string.group_name_folder'), 'app.string.group_label_folder', $r('app.media.ic_public_folder'), [], '', [Permission.READ_WRITE_DOWNLOAD_DIRECTORY, Permission.READ_WRITE_DESKTOP_DIRECTORY, Permission.READ_WRITE_DOCUMENTS_DIRECTORY, Permission.ACCESS_USER_FULL_DISK], [ButtonStatus.DENY, ButtonStatus.ALLOW], true, 'app.string.enable_description_folder', $r('app.string.forbidden_description_folder')),
    new GroupInfo(PermissionGroup.NEARLINK, $r('app.string.group_name_near_link'), 'app.string.group_label_near_link', $r('app.media.ic_nearLink'), [], '', [Permission.ACCESS_NEARLINK], [ButtonStatus.DENY, ButtonStatus.ALLOW], false, 'app.string.enable_description_near_link', $r('app.string.forbidden_description_near_link')),
    new GroupInfo(PermissionGroup.CUSTOM_SCREEN_CAPTURE, $r('app.string.group_name_screen_capture'), 'app.string.group_label_screen_capture', $r('app.media.ic_public_screen_capture'), [], '', [Permission.CUSTOM_SCREEN_CAPTURE], [ButtonStatus.DENY, ButtonStatus.ALLOW], true, 'app.string.enable_description_screen_capture', $r('app.string.forbidden_description_screen_capture')),
    new GroupInfo(PermissionGroup.CUSTOM_SCREEN_RECORDING, $r('app.string.group_name_screen_share'), 'app.string.group_label_screen_share', $r('app.media.screen_share'), [], '', [Permission.CUSTOM_SCREEN_RECORDING], [ButtonStatus.DENY, ButtonStatus.ALLOW], true, 'app.string.enable_description_screen_share', $r('app.string.forbidden_description_screen_share')),
    new GroupInfo(PermissionGroup.FLOAT_VIEW, $r('app.string.group_name_float_view'), 'app.string.group_label_float_view', $r('app.media.ic_float'), [], '', [Permission.FLOAT_VIEW], [ButtonStatus.DENY, ButtonStatus.ALLOW], true, 'app.string.enable_description_float_view', $r('app.string.forbidden_description_float_view')),
    new GroupInfo(PermissionGroup.HOOK_INPUT_EVENT, $r('app.string.group_name_hook_input_event'), 'app.string.group_label_hook_input_event', $r('app.media.ic_public_keyboard'), [], '', [Permission.HOOK_KEY_EVENT], [ButtonStatus.DENY, ButtonStatus.ALLOW], true, 'app.string.enable_description_hook_input_event', $r('app.string.forbidden_description_hook_input_event')),
    new GroupInfo(PermissionGroup.CONTROL_DEVICE, $r('app.string.group_name_control_device'), 'app.string.group_label_control_device', $r('app.media.application_projection'), [], '', [Permission.CONTROL_DEVICE], [ButtonStatus.DENY, ButtonStatus.ALLOW], true, 'app.string.enable_description_control_device', $r('app.string.forbidden_description_control_device'))
];

export const userGrantPermissions: Permission[] = [
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
    Permission.ACCESS_USER_FULL_DISK,
    Permission.ACCESS_NEARLINK,
    Permission.CUSTOM_SCREEN_CAPTURE,
    Permission.FLOAT_VIEW,
    Permission.CUSTOM_SCREEN_RECORDING,
    Permission.HOOK_KEY_EVENT,
    Permission.CONTROL_DEVICE
];

export const only2in1AndTabletSupportedPermissions: Permission[] = [
    Permission.READ_WRITE_DOWNLOAD_DIRECTORY,
    Permission.READ_WRITE_DESKTOP_DIRECTORY,
    Permission.READ_WRITE_DOCUMENTS_DIRECTORY,
]

export const buttonResource: Map<ButtonStatus, Resource> = new Map([
    [ButtonStatus.ALLOW, $r('app.string.allow')],
    [ButtonStatus.ALWAYS_ALLOW, $r('app.string.always_allow')],
    [ButtonStatus.DENY, $r('app.string.ban')],
    [ButtonStatus.CANCEL, $r('app.string.cancel')],
    [ButtonStatus.THIS_TIME_ONLY, $r('app.string.this_time_only')],
    [ButtonStatus.ALLOW_THIS_TIME, $r('app.string.allow_this_time')],
    [ButtonStatus.ALLOW_ONLY_DURING_USE, $r('app.string.allowed_only_during_use')]
])

export const showSubPermissionsGroup: PermissionGroup[] = [
];

export const polymorphismGroup: PermissionGroup[] = [
    PermissionGroup.LOCATION,
    PermissionGroup.FOLDER
]

export const globalGroup: PermissionGroup[] = [
    PermissionGroup.MICROPHONE,
    PermissionGroup.CAMERA
]

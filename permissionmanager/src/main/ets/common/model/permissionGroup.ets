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

import { PermissionInfo, GroupInfo } from '../utils/typedef';

export const permissionGroups: PermissionInfo[] = [
    new PermissionInfo('ohos.permission.LOCATION_IN_BACKGROUND', 'LOCATION', $r('sys.string.ohos_lab_location_in_background'), 0),
    new PermissionInfo('ohos.permission.APPROXIMATELY_LOCATION', 'LOCATION', $r('sys.string.ohos_lab_approximately_location'), 0),
    new PermissionInfo('ohos.permission.LOCATION', 'LOCATION', $r('sys.string.ohos_lab_location'), 0),
    new PermissionInfo('ohos.permission.CAMERA', 'CAMERA', $r('sys.string.ohos_lab_camera'), 1),
    new PermissionInfo('ohos.permission.MICROPHONE', 'MICROPHONE', $r('sys.string.ohos_lab_microphone'), 2),
    new PermissionInfo('ohos.permission.READ_CONTACTS', 'CONTACTS', $r('sys.string.ohos_lab_read_contacts'), 3, 'app.string.enable_description_read_contacts', $r('app.string.forbidden_description_read_contacts')),
    new PermissionInfo('ohos.permission.WRITE_CONTACTS', 'CONTACTS', $r('sys.string.ohos_lab_write_contacts'), 3, 'app.string.enable_description_write_contacts', $r('app.string.forbidden_description_write_contacts')),
    new PermissionInfo('ohos.permission.READ_CALENDAR', 'CALENDAR', $r('sys.string.ohos_lab_read_calendar'), 4, 'app.string.enable_description_read_calendar', $r('app.string.forbidden_description_read_calendar')),
    new PermissionInfo('ohos.permission.WRITE_CALENDAR', 'CALENDAR', $r('sys.string.ohos_lab_write_calendar'), 4, 'app.string.enable_description_write_calendar', $r('app.string.forbidden_description_write_calendar')),
    new PermissionInfo('ohos.permission.READ_WHOLE_CALENDAR', 'CALENDAR', $r('sys.string.ohos_lab_read_whole_calendar'), 4, 'app.string.enable_description_read_whole_calendar', $r('app.string.forbidden_description_read_whole_calendar')),
    new PermissionInfo('ohos.permission.WRITE_WHOLE_CALENDAR', 'CALENDAR', $r('sys.string.ohos_lab_write_whole_calendar'), 4, 'app.string.enable_description_write_whole_calendar', $r('app.string.forbidden_description_write_whole_calendar')),
    new PermissionInfo('ohos.permission.ACTIVITY_MOTION', 'SPORT', $r('sys.string.ohos_lab_activity_motion'), 5),
    new PermissionInfo('ohos.permission.READ_HEALTH_DATA', 'HEALTH', $r('sys.string.ohos_lab_read_health_data'), 6),
    new PermissionInfo('ohos.permission.READ_IMAGEVIDEO', 'IMAGE_AND_VIDEOS', $r('sys.string.ohos_desc_read_imagevideo'), 8),
    new PermissionInfo('ohos.permission.WRITE_IMAGEVIDEO', 'IMAGE_AND_VIDEOS', $r('sys.string.ohos_desc_write_imagevideo'), 8),
    new PermissionInfo('ohos.permission.MEDIA_LOCATION', 'IMAGE_AND_VIDEOS', $r('sys.string.ohos_lab_media_location'), 8),
    new PermissionInfo('ohos.permission.READ_AUDIO', 'AUDIOS', $r('sys.string.ohos_desc_read_audio'), 9),
    new PermissionInfo('ohos.permission.WRITE_AUDIO', 'AUDIOS', $r('sys.string.ohos_desc_write_audio'), 9),
    new PermissionInfo('ohos.permission.READ_DOCUMENT', 'DOCUMENTS', $r('sys.string.ohos_desc_read_document'), 10),
    new PermissionInfo('ohos.permission.WRITE_DOCUMENT', 'DOCUMENTS', $r('sys.string.ohos_desc_write_document'), 10),
    new PermissionInfo('ohos.permission.READ_MEDIA', 'DOCUMENTS', $r('sys.string.ohos_lab_read_media'), 10),
    new PermissionInfo('ohos.permission.WRITE_MEDIA', 'DOCUMENTS', $r('sys.string.ohos_lab_write_media'), 10),
    new PermissionInfo('ohos.permission.APP_TRACKING_CONSENT', 'ADS', $r('sys.string.ohos_lab_app_tracking_consent'), 11),
    new PermissionInfo('ohos.permission.GET_INSTALLED_BUNDLE_LIST', 'GET_INSTALLED_BUNDLE_LIST', $r('sys.string.ohos_lab_get_installed_bundle_list'), 12),
    new PermissionInfo('ohos.permission.DISTRIBUTED_DATASYNC', 'DISTRIBUTED_DATASYNC', $r('sys.string.ohos_lab_distributed_datasync'), 13),
    new PermissionInfo('ohos.permission.ACCESS_BLUETOOTH', 'BLUETOOTH', $r('sys.string.ohos_lab_access_bluetooth'), 14),
    new PermissionInfo('ohos.permission.READ_PASTEBOARD', 'PASTEBOARD', $r('sys.string.ohos_lab_read_pasteboard'), 15),
    new PermissionInfo('ohos.permission.READ_WRITE_DOWNLOAD_DIRECTORY', 'FOLDER', $r('sys.string.ohos_lab_read_write_download_directory'), 16),
    new PermissionInfo('ohos.permission.READ_WRITE_DESKTOP_DIRECTORY', 'FOLDER', $r('sys.string.ohos_lab_read_write_desktop_directory'), 16),
    new PermissionInfo('ohos.permission.READ_WRITE_DOCUMENTS_DIRECTORY', 'FOLDER', $r('sys.string.ohos_lab_read_write_documents_directory'), 16),
    new PermissionInfo('ohos.permission.ACCESS_NEARLINK', 'NEARLINK', $r('sys.string.ohos_lab_access_nearlink'), 17)
]

export const groups: GroupInfo[] = [
    new GroupInfo('LOCATION', $r('app.string.groupName_location'), $r('app.string.group_label_location'), $r('app.media.ic_public_gps'), [], '', ['ohos.permission.LOCATION_IN_BACKGROUND', 'ohos.permission.APPROXIMATELY_LOCATION', 'ohos.permission.LOCATION'], true, 'app.string.enable_description_location', $r('app.string.forbidden_description_location')),
    new GroupInfo('CAMERA', $r('app.string.groupName_camera'), $r('app.string.group_label_camera'), $r('app.media.ic_public_camera'), [], '', ['ohos.permission.CAMERA'], true, 'app.string.enable_description_camera', $r('app.string.forbidden_description_camera')),
    new GroupInfo('MICROPHONE', $r('app.string.groupName_microphone'), $r('app.string.group_label_microphone'), $r('app.media.ic_public_voice'), [], '', ['ohos.permission.MICROPHONE'], true, 'app.string.enable_description_microphone', $r('app.string.forbidden_description_microphone')),
    new GroupInfo('CONTACTS', $r('app.string.groupName_contacts'), $r('app.string.group_label_contacts'), $r('app.media.ic_public_contacts_group'), [], '', ['ohos.permission.READ_CONTACTS', 'ohos.permission.WRITE_CONTACTS'], false),
    new GroupInfo('CALENDAR', $r('app.string.groupName_calendar'), $r('app.string.group_label_calendar'), $r('app.media.ic_public_calendar'), [], '', ['ohos.permission.READ_CALENDAR', 'ohos.permission.WRITE_CALENDAR', 'ohos.permission.READ_WHOLE_CALENDAR', 'ohos.permission.WRITE_WHOLE_CALENDAR'], true),
    new GroupInfo('SPORT', $r('app.string.groupName_sport'), $r('app.string.group_label_sport'), $r('app.media.ic_sport'), [], '', ['ohos.permission.ACTIVITY_MOTION'], true, 'app.string.enable_description_sport', $r('app.string.forbidden_description_sport')),
    new GroupInfo('HEALTH', $r('app.string.groupName_health'), $r('app.string.group_label_health'), $r('app.media.ic_ssensor'), [], '', ['ohos.permission.READ_HEALTH_DATA'], true, 'app.string.enable_description_health', $r('app.string.forbidden_description_health')),
    new GroupInfo('OTHER', $r('app.string.groupName_other'), '', $r('app.media.ic_more'), [], '', [], true),
    new GroupInfo('IMAGE_AND_VIDEOS', $r('sys.string.ohos_lab_read_imagevideo'), $r('app.string.group_label_image_and_videos'), $r('app.media.ic_public_picture'), [], '', ['ohos.permission.READ_IMAGEVIDEO', 'ohos.permission.WRITE_IMAGEVIDEO', 'ohos.permission.MEDIA_LOCATION'], false, 'app.string.enable_description_image', $r('app.string.forbidden_description_image')),
    new GroupInfo('AUDIOS', $r('sys.string.ohos_lab_read_audio'), $r('app.string.group_label_audios'), $r('app.media.ic_public_audio'), [], '', ['ohos.permission.READ_AUDIO', 'ohos.permission.WRITE_AUDIO'], false, 'app.string.enable_description_audios', $r('app.string.forbidden_description_audios')),
    new GroupInfo('DOCUMENTS', $r('sys.string.ohos_lab_read_document'), $r('app.string.group_label_document'), $r('app.media.ic_public_folder'), [], '', ['ohos.permission.READ_DOCUMENT', 'ohos.permission.WRITE_DOCUMENT', 'ohos.permission.READ_MEDIA', 'ohos.permission.WRITE_MEDIA'], false, 'app.string.enable_description_documents', $r('app.string.forbidden_description_documents')),
    new GroupInfo('ADS', $r('app.string.groupName_ADS'), $r('app.string.group_label_ADS'), $r('app.media.track'), [], '', ['ohos.permission.APP_TRACKING_CONSENT'], false, 'app.string.enable_description_ADS', $r('app.string.forbidden_description_ADS')),
    new GroupInfo('GET_INSTALLED_BUNDLE_LIST', $r('app.string.groupName_appList'), $r('app.string.group_label_appList'), $r('app.media.ic_public_app_list'), [], '', ['ohos.permission.GET_INSTALLED_BUNDLE_LIST'], false, 'app.string.enable_description_appList', $r('app.string.forbidden_description_appList')),
    new GroupInfo('DISTRIBUTED_DATASYNC', $r('app.string.multi_device_collaboration'), $r('app.string.group_label_distributed_datasync'), $r('app.media.ic_multi_device_vector'), [], '', ['ohos.permission.DISTRIBUTED_DATASYNC'], false, 'app.string.enable_description_distributed_datasync', $r('app.string.forbidden_description_distributed_datasync')),
    new GroupInfo('BLUETOOTH', $r('app.string.groupName_bluetooth'), $r('app.string.group_label_bluetooth'), $r('app.media.ic_public_bluetooth'), [], '', ['ohos.permission.ACCESS_BLUETOOTH'], false, 'app.string.enable_description_bluetooth', $r('app.string.forbidden_description_bluetooth')),
    new GroupInfo('PASTEBOARD', $r('app.string.groupName_pasteboard'), $r('app.string.group_label_pasteboard'), $r('app.media.ic_clipboard'), [], '', ['ohos.permission.READ_PASTEBOARD'], false, 'app.string.enable_description_pasteboard', $r('app.string.forbidden_description_pasteboard')),
    new GroupInfo('FOLDER', $r('app.string.groupName_folder'), $r('app.string.group_label_folder'), $r('app.media.ic_public_folder'), [], '', ['ohos.permission.READ_WRITE_DOWNLOAD_DIRECTORY', 'ohos.permission.READ_WRITE_DESKTOP_DIRECTORY', 'ohos.permission.READ_WRITE_DOCUMENTS_DIRECTORY'], false, 'app.string.enable_description_folder', $r('app.string.forbidden_description_folder')),
    new GroupInfo('NEARLINK', $r('app.string.groupName_nearLink'), $r('app.string.group_label_nearLink'), $r('app.media.ic_nearLink'), [], '', ['ohos.permission.ACCESS_NEARLINK'], false, 'app.string.enable_description_nearLink', $r('app.string.forbidden_description_nearLink'))
];

export const userGrantPermissions: string[] = [
    'ohos.permission.LOCATION_IN_BACKGROUND',
    'ohos.permission.APPROXIMATELY_LOCATION',
    'ohos.permission.LOCATION',
    'ohos.permission.CAMERA',
    'ohos.permission.MICROPHONE',
    'ohos.permission.READ_CONTACTS',
    'ohos.permission.WRITE_CONTACTS',
    'ohos.permission.MEDIA_LOCATION',
    'ohos.permission.READ_MEDIA',
    'ohos.permission.WRITE_MEDIA',
    'ohos.permission.READ_CALENDAR',
    'ohos.permission.WRITE_CALENDAR',
    'ohos.permission.ACTIVITY_MOTION',
    'ohos.permission.READ_HEALTH_DATA',
    'ohos.permission.READ_IMAGEVIDEO',
    'ohos.permission.WRITE_IMAGEVIDEO',
    'ohos.permission.READ_AUDIO',
    'ohos.permission.WRITE_AUDIO',
    'ohos.permission.READ_DOCUMENT',
    'ohos.permission.WRITE_DOCUMENT',
    'ohos.permission.READ_WHOLE_CALENDAR',
    'ohos.permission.WRITE_WHOLE_CALENDAR',
    'ohos.permission.APP_TRACKING_CONSENT',
    'ohos.permission.GET_INSTALLED_BUNDLE_LIST',
    'ohos.permission.DISTRIBUTED_DATASYNC',
    'ohos.permission.ACCESS_BLUETOOTH',
    'ohos.permission.READ_PASTEBOARD',
    'ohos.permission.READ_WRITE_DOWNLOAD_DIRECTORY',
    'ohos.permission.READ_WRITE_DESKTOP_DIRECTORY',
    'ohos.permission.READ_WRITE_DOCUMENTS_DIRECTORY',
    'ohos.permission.ACCESS_NEARLINK'
];

export const showSubPermissionsGroup: string[] = [
    'CALENDAR',
    'CONTACTS',
];

export const polymorphismGroup: string[] = [
    'LOCATION',
    'FOLDER'
]

export const globalGroup: string[] = [
    'MICROPHONE',
    'CAMERA'
]
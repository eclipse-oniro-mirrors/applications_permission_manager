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

export const permissionGroups: any[] = [
    {
        "permissionName": "ohos.permission.LOCATION_IN_BACKGROUND",
        "groupName": "LOCATION",
        "label": $r("sys.string.ohos_lab_location_in_background"),
        "groupId": 0
    },
    {
        "permissionName": "ohos.permission.APPROXIMATELY_LOCATION",
        "groupName": "LOCATION",
        "label": $r("sys.string.ohos_lab_approximately_location"),
        "groupId": 0
    },
    {
        "permissionName": "ohos.permission.LOCATION",
        "groupName": "LOCATION",
        "label": $r("sys.string.ohos_lab_location"),
        "groupId": 0
    },
    {
        "permissionName": "ohos.permission.CAMERA",
        "groupName": "CAMERA",
        "label": $r("sys.string.ohos_lab_camera"),
        "groupId": 1
    },
    {
        "permissionName": "ohos.permission.MICROPHONE",
        "groupName": "MICROPHONE",
        "label": $r("sys.string.ohos_lab_microphone"),
        "groupId": 2
    },
    {
        "permissionName": "ohos.permission.READ_CONTACTS",
        "groupName": "CONTACTS",
        "label": $r("sys.string.ohos_lab_read_contacts"),
        "groupId": 3
    },
    {
        "permissionName": "ohos.permission.WRITE_CONTACTS",
        "groupName": "CONTACTS",
        "label": $r("sys.string.ohos_lab_write_contacts"),
        "groupId": 3
    },
    {
        "permissionName": "ohos.permission.READ_CALENDAR",
        "groupName": "CALENDAR",
        "label": $r("sys.string.ohos_lab_read_calendar"),
        "groupId": 4
    },
    {
        "permissionName": "ohos.permission.WRITE_CALENDAR",
        "groupName": "CALENDAR",
        "label": $r("sys.string.ohos_lab_write_calendar"),
        "groupId": 4
    },
    {
        "permissionName": "ohos.permission.READ_WHOLE_CALENDAR",
        "groupName": "CALENDAR",
        "label": $r('sys.string.ohos_lab_read_whole_calendar'),
        "groupId": 4
    },
    {
        "permissionName": "ohos.permission.WRITE_WHOLE_CALENDAR",
        "groupName": "CALENDAR",
        "label": $r('sys.string.ohos_lab_write_whole_calendar'),
        "groupId": 4
    },
    {
        "permissionName": "ohos.permission.ACTIVITY_MOTION",
        "groupName": "SPORT",
        "label": $r("sys.string.ohos_lab_activity_motion"),
        "groupId": 5
    },
    {
        "permissionName": "ohos.permission.READ_HEALTH_DATA",
        "groupName": "HEALTH",
        "label": $r("sys.string.ohos_lab_read_health_data"),
        "groupId": 6
    },
    {
        "permissionName": "ohos.permission.DISTRIBUTED_DATASYNC",
        "groupName": "DISTRIBUTED_DATASYNC",
        "label": $r("sys.string.ohos_lab_distributed_datasync"),
        "groupId": 13
    },
    {
        "permissionName": "ohos.permission.READ_IMAGEVIDEO",
        "groupName": "IMAGE_AND_VIDEOS",
        "label": $r('sys.string.ohos_desc_read_imagevideo'),
        "groupId": 8
    },
    {
        "permissionName": "ohos.permission.WRITE_IMAGEVIDEO",
        "groupName": "IMAGE_AND_VIDEOS",
        "label": $r('sys.string.ohos_desc_write_imagevideo'),
        "groupId": 8
    },
    {
        "permissionName": "ohos.permission.MEDIA_LOCATION",
        "groupName": "IMAGE_AND_VIDEOS",
        "label": $r("sys.string.ohos_lab_media_location"),
        "groupId": 8
    },
    {
        "permissionName": "ohos.permission.READ_AUDIO",
        "groupName": "AUDIOS",
        "label": $r('sys.string.ohos_desc_read_audio'),
        "groupId": 9
    },
    {
        "permissionName": "ohos.permission.WRITE_AUDIO",
        "groupName": "AUDIOS",
        "label": $r('sys.string.ohos_desc_write_audio'),
        "groupId": 9
    },
    {
        "permissionName": "ohos.permission.READ_DOCUMENT",
        "groupName": "DOCUMENTS",
        "label": $r('sys.string.ohos_desc_read_document'),
        "groupId": 10
    },
    {
        "permissionName": "ohos.permission.WRITE_DOCUMENT",
        "groupName": "DOCUMENTS",
        "label": $r('sys.string.ohos_desc_write_document'),
        "groupId": 10
    },
    {
        "permissionName": "ohos.permission.READ_MEDIA",
        "groupName": "DOCUMENTS",
        "label": $r("sys.string.ohos_lab_read_media"),
        "groupId": 10
    },
    {
        "permissionName": "ohos.permission.WRITE_MEDIA",
        "groupName": "DOCUMENTS",
        "label": $r("sys.string.ohos_lab_write_media"),
        "groupId": 10
    },
    {
        "permissionName": "ohos.permission.APP_TRACKING_CONSENT",
        "groupName": "ADS",
        "label": $r('sys.string.ohos_lab_app_tracking_consent'),
        "groupId": 11
    },
    {
        "permissionName": "ohos.permission.GET_INSTALLED_BUNDLE_LIST",
        "groupName": "GET_INSTALLED_BUNDLE_LIST",
        "label": $r('sys.string.ohos_lab_get_installed_bundle_list'),
        "groupId": 12
    }
]

export const groups: any[] = [
    {
        "name": "LOCATION",
        "groupName": $r("app.string.groupName_location"),
        "icon": $r('app.media.ic_public_gps'),
        "description": "",
        "label": $r("app.string.group_label_location"),
        "permissions": [
            "ohos.permission.LOCATION_IN_BACKGROUND",
            "ohos.permission.APPROXIMATELY_LOCATION",
            "ohos.permission.LOCATION"
        ],
        "isShow":true
    },
    {
        "name": "CAMERA",
        "groupName": $r("app.string.groupName_camera"),
        "icon": $r('app.media.ic_public_camera'),
        "label": $r("app.string.group_label_camera"),
        "description": "",
        "permissions": [
            "ohos.permission.CAMERA"
        ],
        "isShow":true
    },
    {
        "name": "MICROPHONE",
        "groupName": $r("app.string.groupName_microphone"),
        "icon": $r('app.media.ic_public_voice'),
        "label": $r("app.string.group_label_microphone"),
        "description": "",
        "permissions": [
            "ohos.permission.MICROPHONE"
        ],
        "isShow":true
    },
    {
        "name": "CONTACTS",
        "groupName": $r("app.string.groupName_contacts"),
        "icon": $r('app.media.ic_public_contacts_group'),
        "label": $r("app.string.group_label_contacts"),
        "description": "",
        "permissions": [
            "ohos.permission.READ_CONTACTS",
            "ohos.permission.WRITE_CONTACTS"
        ],
        "isShow":false
    },
    {
        "name": "CALENDAR",
        "groupName": $r("app.string.groupName_calendar"),
        "icon": $r('app.media.ic_public_calendar'),
        "label": $r("app.string.group_label_calendar"),
        "description": "",
        "permissions": [
            "ohos.permission.READ_CALENDAR",
            "ohos.permission.WRITE_CALENDAR",
            "ohos.permission.READ_WHOLE_CALENDAR",
            "ohos.permission.WRITE_WHOLE_CALENDAR"
        ],
        "isShow":true
    },
    {
        "name": "SPORT",
        "groupName": $r("app.string.groupName_sport"),
        "icon": $r('app.media.ic_sport'),
        "label": $r("app.string.group_label_sport"),
        "description": "",
        "permissions": [
            "ohos.permission.ACTIVITY_MOTION"
        ],
        "isShow":true
    },
    {
        "name": "HEALTH",
        "groupName": $r("app.string.groupName_health"),
        "icon": $r('app.media.ic_ssensor'),
        "label": $r("app.string.group_label_health"),
        "description": "",
        "permissions": [
            "ohos.permission.READ_HEALTH_DATA"
        ],
        "isShow":true
    },
    {
        "name": "OTHER",
        "groupName": $r("app.string.groupName_other"),
        "icon": $r('app.media.ic_more'),
        "label": '',
        "description": "",
        "permissions": [],
        "isShow":true
    },
    {
        "name": "IMAGE_AND_VIDEOS",
        "groupName": $r('sys.string.ohos_lab_read_imagevideo'),
        "icon": $r('app.media.ic_public_picture'),
        "label": $r("app.string.group_label_image_and_videos"),
        "description": "",
        "permissions": [
            "ohos.permission.READ_IMAGEVIDEO",
            "ohos.permission.WRITE_IMAGEVIDEO",
            "ohos.permission.MEDIA_LOCATION"
        ],
        "isShow":false
    },
    {
        "name": "AUDIOS",
        "groupName": $r('sys.string.ohos_lab_read_audio'),
        "icon": $r('app.media.ic_public_audio'),
        "label": $r("app.string.group_label_audios"),
        "description": "",
        "permissions": [
            "ohos.permission.READ_AUDIO",
            "ohos.permission.WRITE_AUDIO"
        ],
        "isShow":false
    },
    {
        "name": "DOCUMENTS",
        "groupName": $r('sys.string.ohos_lab_read_document'),
        "icon": $r('app.media.ic_public_folder'),
        "label": $r("app.string.group_label_document"),
        "description": "",
        "permissions": [
            "ohos.permission.READ_DOCUMENT",
            "ohos.permission.WRITE_DOCUMENT",
            "ohos.permission.READ_MEDIA",
            "ohos.permission.WRITE_MEDIA"
        ],
        "isShow":false
    },
    {
        "name": "ADS",
        "groupName": $r("app.string.groupName_ADS"),
        "icon": $r('app.media.track'),
        "label": $r("app.string.group_label_ADS"),
        "description": "",
        "permissions": [
            "ohos.permission.APP_TRACKING_CONSENT"
        ],
        "isShow":false
    },
    {
        "name": "GET_INSTALLED_BUNDLE_LIST",
        "groupName": $r('app.string.groupName_appList'),
        "icon": $r('app.media.ic_public_app_list'),
        "label": $r('app.string.group_label_appList'),
        "description": "",
        "permissions": [
            "ohos.permission.GET_INSTALLED_BUNDLE_LIST"
        ],
        "isShow":false
    },
    {
        "name": "DISTRIBUTED_DATASYNC",
        "groupName": $r('app.string.multi_device_collaboration'),
        "icon": $r('app.media.ic_multi_device_vector'),
        "label": $r('app.string.group_label_distributed_datasync'),
        "description": "",
        "permissions": [
            "ohos.permission.DISTRIBUTED_DATASYNC"
        ],
        "isShow":false
    }
];

export const permissionGroupPermissions: object = {
    "LOCATION": [
        "ohos.permission.LOCATION_IN_BACKGROUND",
        "ohos.permission.APPROXIMATELY_LOCATION",
        "ohos.permission.LOCATION"
    ],
    "CAMERA": [
        "ohos.permission.CAMERA"
    ],
    "MICROPHONE": [
        "ohos.permission.MICROPHONE"
    ],
    "CONTACTS": [
        "ohos.permission.READ_CONTACTS",
        "ohos.permission.WRITE_CONTACTS"
    ],
    "CALENDAR": [
        "ohos.permission.READ_CALENDAR",
        "ohos.permission.WRITE_CALENDAR",
        "ohos.permission.READ_WHOLE_CALENDAR",
        "ohos.permission.WRITE_WHOLE_CALENDAR"
    ],
    "SPORT": [
        "ohos.permission.ACTIVITY_MOTION"
    ],
    "HEALTH": [
        "ohos.permission.READ_HEALTH_DATA"
    ],
    "OTHER": [],
    "IMAGE_AND_VIDEOS": [
        "ohos.permission.READ_IMAGEVIDEO",
        "ohos.permission.WRITE_IMAGEVIDEO",
        "ohos.permission.MEDIA_LOCATION"
    ],
    "AUDIOS": [
        "ohos.permission.READ_AUDIO",
        "ohos.permission.WRITE_AUDIO"
    ],
    "DOCUMENTS": [
        "ohos.permission.READ_DOCUMENT",
        "ohos.permission.WRITE_DOCUMENT",
        "ohos.permission.READ_MEDIA",
        "ohos.permission.WRITE_MEDIA"
    ],
    "ADS": [
        "ohos.permission.APP_TRACKING_CONSENT"
    ],
    "GET_INSTALLED_BUNDLE_LIST": [
        "ohos.permission.GET_INSTALLED_BUNDLE_LIST"
    ],
    "DISTRIBUTED_DATASYNC": [
        "ohos.permission.DISTRIBUTED_DATASYNC"
    ]
};


export const userGrantPermissions: string[] = [
    "ohos.permission.LOCATION_IN_BACKGROUND",
    "ohos.permission.APPROXIMATELY_LOCATION",
    "ohos.permission.LOCATION",
    "ohos.permission.CAMERA",
    "ohos.permission.MICROPHONE",
    "ohos.permission.READ_CONTACTS",
    "ohos.permission.WRITE_CONTACTS",
    "ohos.permission.MEDIA_LOCATION",
    "ohos.permission.READ_MEDIA",
    "ohos.permission.WRITE_MEDIA",
    "ohos.permission.READ_CALENDAR",
    "ohos.permission.WRITE_CALENDAR",
    "ohos.permission.ACTIVITY_MOTION",
    "ohos.permission.READ_HEALTH_DATA",
    "ohos.permission.DISTRIBUTED_DATASYNC",
    "ohos.permission.READ_IMAGEVIDEO",
    "ohos.permission.WRITE_IMAGEVIDEO",
    "ohos.permission.READ_AUDIO",
    "ohos.permission.WRITE_AUDIO",
    "ohos.permission.READ_DOCUMENT",
    "ohos.permission.WRITE_DOCUMENT",
    "ohos.permission.READ_WHOLE_CALENDAR",
    "ohos.permission.WRITE_WHOLE_CALENDAR",
    "ohos.permission.APP_TRACKING_CONSENT",
    "ohos.permission.GET_INSTALLED_BUNDLE_LIST"
];

export const permissionGroupIds: object = {
    "ohos.permission.LOCATION_IN_BACKGROUND": "0",
    "ohos.permission.APPROXIMATELY_LOCATION": "0",
    "ohos.permission.LOCATION": "0",
    "ohos.permission.CAMERA": "1",
    "ohos.permission.MICROPHONE": "2",
    "ohos.permission.READ_CONTACTS": "3",
    "ohos.permission.WRITE_CONTACTS": "3",
    "ohos.permission.READ_CALENDAR": "4",
    "ohos.permission.WRITE_CALENDAR": "4",
    "ohos.permission.READ_WHOLE_CALENDAR": "4",
    "ohos.permission.WRITE_WHOLE_CALENDAR": "4",
    "ohos.permission.ACTIVITY_MOTION": "5",
    "ohos.permission.READ_HEALTH_DATA": "6",
    "ohos.permission.DISTRIBUTED_DATASYNC": "13",
    "ohos.permission.READ_IMAGEVIDEO": "8",
    "ohos.permission.WRITE_IMAGEVIDEO": "8",
    "ohos.permission.MEDIA_LOCATION": "8",
    "ohos.permission.READ_AUDIO": "9",
    "ohos.permission.WRITE_AUDIO": "9",
    "ohos.permission.READ_DOCUMENT": "10",
    "ohos.permission.WRITE_DOCUMENT": "10",
    "ohos.permission.READ_MEDIA": "10",
    "ohos.permission.WRITE_MEDIA": "10",
    "ohos.permission.APP_TRACKING_CONSENT": "11",
    "ohos.permission.GET_INSTALLED_BUNDLE_LIST": "12"
};

export const showSubpermissionsGrop: string[] = [
    "CALENDAR",
    "CONTACTS",
];

export const polymorphismGroup: string[] = [
    "LOCATION"
]

export const globalGroup: string[] = [
    "MICROPHONE",
    "CAMERA"
]
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

export default class Constants {
    // alphabetIndexer
    public static ALPHABETINDEXER_HEIGHT = 448;

    // backBar
    public static BACKBAR_HEIGHT = 56;
    public static BACKBAR_MINHEIGHT = 56;
    public static BACKBAR_IMAGE_HEIGHT = 24;
    public static BACKBAR_IMAGE_WIDTH = 24;
    public static BACKBAR_MARGIN_RIGHT = 4;

    // search textInput
    public static TEXTINPUT_PADDING_LEFT = 36;
    public static TEXTINPUT_BORDER_RADIUS = 20;
    public static TEXTINPUT_BORDER_WIDTH = 1.5;
    public static TEXTINPUT_HEIGHT = 40;
    public static TEXTINPUT_IMAGE_WIDTH = 16;
    public static TEXTINPUT_IMAGE_HEIGHT = 16;
    public static TEXTINPUT_IMAGE_MARGIN_LEFT = 12;
    public static TEXTINPUT_IMAGE_MARGIN_TOP = 12;

    // grid useSizeType
    public static GUTTER = 0;
    public static XS_COLUMNS = 2;
    public static XS_SPAN = 2;
    public static XS_OFFSET = 0;
    public static SM_COLUMNS = 4;
    public static SM_SPAN = 4;
    public static SM_OFFSET = 0;
    public static MD_COLUMNS = 8;
    public static MD_SPAN = 8;
    public static MD_OFFSET = 0;
    public static LG_COLUMNS = 12;
    public static LG_SPAN = 8;
    public static LG_OFFSET = 2;

    public static DIALOG_GUTTER = 16;
    public static DIALOG_MARGIN = 16;
    public static DIALOG_MD_SPAN = 4;
    public static DIALOG_MD_OFFSET = 2;
    public static DIALOG_LG_SPAN = 4;
    public static DIALOG_LG_OFFSET = 4;

    // 100% width,height
    public static FULL_WIDTH = '100%';
    public static FULL_HEIGHT = '100%';
    public static HALF_LENGTH = '50%';

    // public property style
    public static PERMISSION = 1;
    public static APPLICATION = 0;
    public static LAYOUT_WEIGHT = 1;
    public static FLEX_GROW = 1;
    public static HEADLINE_HEIGHT = 56;
    public static TEXT_BIG_FONT_SIZE = 20;
    public static TEXT_MIDDLE_FONT_SIZE = 16;
    public static TEXT_SMALL_FONT_SIZE = 14;
    public static TEXT_SMALLER_FONT_SIZE = 12;
    public static FONT_SIZE_12 = '12vp';
    public static FONT_SIZE_18_vp = '18vp';
    public static FONT_SIZE_24_vp = '24vp';
    public static FONT_SIZE_28 = '28vp';
    public static TEXT_LINE_HEIGHT = 22;
    public static TEXT_LINE_HEIGHT_24 = 24;
    public static TEXT_LINE_HEIGHT_27 = 27;
    public static TEXT_BIG_LINE_HEIGHT = 28;
    public static TEXT_SMALL_LINE_HEIGHT = 19;
    public static CONSTRAINTSIZE_MINHEIGHT = 48;
    public static LISTITEM_ROW_HEIGHT = 48;
    public static LISTITEM_PADDING_LEFT = 24;
    public static LIST_PADDING_LEFT = 12
    public static LISTITEM_PADDING_RIGHT = 24;
    public static LISTITEM_PADDING_RIGHT_RECORD = 50;
    public static LISTITEM_MARGIN_BOTTOM = 12;
    public static LISTITEM_HEIGHT_PERMISSION = 64;
    public static LISTITEM_HEIGHT_APPLICATION = 72;
    public static IMAGE_LENGTH_20 = 20;
    public static IMAGE_HEIGHT = 24;
    public static IMAGE_WIDTH = 12;
    public static IMAGE_HEIGHT_RECORD = 12;
    public static IMAGE_WIDTH_RECORD = 24;
    public static IMAGE_HEIGHT_RECORD_APPLICATION = 16;
    public static IMAGE_WIDTH_RECORD_APPLICATION = 16;
    public static IMAGE_POSITION_28 = 28;
    public static BORDER_WIDTH_1 = '1px';
    public static TITLE_MARGIN_BOTTOM = 16;
    public static SUBTITLE_MIN_HEIGHT = 48;
    public static SUBTITLE_LINE_HEIGHT = 24;
    public static SUBTITLE_PADDING_TOP = 16;
    public static SUBTITLE_PADDING_BOTTOM = 8;
    public static TAB_HEIGHT = 56;
    public static TAB_LINE_HEIGHT = 100;
    public static TAB_INNER_PADDING = 8;
    public static TAB_DECORATION_HEIGHT = 2;
    public static TAB_DECORATION_POSITION_Y = 6;
    public static RADIUS_5 = 5;
    public static MARGIN_4 = 4;
    public static MARGIN_8 = 8;
    public static MARGIN_12 = 12;
    public static MARGIN_16 = 16;
    public static MARGIN_24 = 24;
    public static MARGIN_26 = 26;
    public static PADDING_4 = 4;
    public static PADDING_8 = 8;
    public static PADDING_10 = 10;
    public static PADDING_14 = 14;
    public static PADDING_16 = 16;
    public static PADDING_20 = 20;
    public static PADDING_24 = 24;
    public static DEFAULT_PADDING_START = 12;
    public static DEFAULT_PADDING_END = 12;
    public static DEFAULT_PADDING_TOP = 12;
    public static DEFAULT_PADDING_BOTTOM = 12;
    public static DEFAULT_MARGIN_START = 12;
    public static DEFAULT_MARGIN_END = 12;
    public static DEFAULT_MARGIN_TOP = 12;
    public static DEFAULT_MARGIN_BOTTOM = 12;
    public static DEFAULT_SLIDER_WIDTH = 60;
    public static DEFAULT_SLIDER_HEIGHT = 40;
    public static OFFSET = 100;
    public static CLICK_SHADOW_LENGTH = 48;
    public static SCROLL_BAR_WIDTH_DEFAULT = 4;
    public static SCROLL_BAR_WIDTH_ACTIVE = 8;
    public static DIVIDER = '1px';
    public static DIALOG_DIVIDER = '2px';
    public static DIVIDER_HEIGHT = 24;
    public static DIVIDER_MARGIN_RIGHT_PERMISSION = 52;
    public static DIVIDER_MARGIN_RIGHT_APPLICATION = 68;
    public static DIALOG_TITLE_MAX_SCALE = 2;
    public static DIALOG_TEXT_MAX_SCALE = 3.2;
    public static DIALOG_BUTTON_MAX_WIDTH = 135;

    // application-secondary, authority-secondary
    public static FLEX_MARGIN_TOP = 8;
    public static FLEX_MARGIN_BOTTOM = 8;
    public static LIST_PADDING_TOP = 4;
    public static LIST_PADDING_BOTTOM = 4;
    public static LIST_MARGIN_BOTTOM = 12;
    public static ROW_MARGIN_TOP = 9;
    public static SECONDARY_TEXT_MARGIN_LEFT = 24;
    public static SECONDARY_LIST_PADDING_LEFT = 12;
    public static SECONDARY_LIST_PADDING_RIGHT = 12;

    // application-tertiary
    public static TERTIARY_IMAGE_WIDTH = 64;
    public static TERTIARY_IMAGE_HEIGHT = 64;
    public static TERTIARY_IMAGE_MARGIN_LEFT = 12;
    public static TERTIARY_IMAGE_MARGIN_RIGHT = 12;
    public static TERTIARY_LABEL_MARGIN_BOTTOM = 2;
    public static TERTIARY_MARGIN_LEFT = 12;
    public static TERTIARY_TEXT_MARGIN_LEFT = 24;
    public static TERTIARY_HALF_WIDTH = '50%';
    public static TERTIARY_ROW_MARGIN_TOP = 24;
    public static TERTIARY_RADIO_IMAGE_WIDTH = 24;
    public static TERTIARY_RADIO_IMAGE_HEIGHT = 24;
    public static TERTIARY_LISTITEM_MARGIN_TOP = 1;
    public static TERTIARY_LIST_PADDING_TOP = 4;
    public static TERTIARY_LIST_PADDING_BOTTOM = 4;
    public static LOCATION_MARGIN_TOP = 12;
    public static LOCATION_MARGIN_BOTTOM = 8;

    // authority-tertiary
    public static AUTHORITY_IMAGE_WIDTH = 40;
    public static AUTHORITY_IMAGE_HEIGHT = 40;
    public static AUTHORITY_IMAGE_MARGIN_RIGHT = 16;
    public static AUTHORITY_TOGGLE_WIDTH = 36;
    public static AUTHORITY_TOGGLE_HEIGHT = 20;
    public static AUTHORITY_ROW_HEIGHT = 72;
    public static AUTHORITY_CONSTRAINTSIZE_MINHEIGHT = 72;
    public static AUTHORITY_LISTITEM_PADDING_LEFT = 12;
    public static AUTHORITY_LISTITEM_PADDING_RIGHT = 12;
    public static AUTHORITY_TEXTINPUT_PADDING_LEFT = 12;
    public static AUTHORITY_TEXTINPUT_PADDING_RIGHT = 24;
    public static AUTHORITY_TEXT_MARGIN_TOP = 24;
    public static AUTHORITY_ROW_MARGIN_BOTTOM = 24;
    public static AUTHORITY_LIST_MARGIN_BOTTOM = 96;
    public static AUTHORITY_LIST_MARGIN_BOTTOM_GLOBAL = 176;
    public static NORECORD_IMAGE_WIDTH = 120;
    public static NORECORD_IMAGE_HEIGHT = 120;
    public static NORECORD_IMAGE_MARGIN_LEFT = 40;
    public static SEARCHNORESULT_IMAGE_WIDTH = 200;
    public static SEARCHNORESULT_IMAGE_HEIGHT = 200;
    public static AUTHORITY_ALPHABETINDEX_WIDTH = 24;
    public static AUTHORITY_ALPHABETINDEX_PADDING_TOP = 16;

    // authority-management
    public static MANAGEMENT_IMAGE_WIDTH = 24;
    public static MANAGEMENT_IMAGE_HEIGHT = 24;
    public static MANAGEMENT_IMAGE_MARGIN_RIGHT = 16;
    public static MANAGEMENT_IMAGE_MARGIN_RIGHT_RECORD = 24;
    public static MANAGEMENT_IMAGE_MARGIN_LEFT = 8;
    public static MANAGEMENT_ROW_HEIGHT = 56;
    public static MANAGEMENT_ROW_PADDING_LEFT = 12;
    public static MANAGEMENT_ROW_PADDING_RIGHT = 12;
    public static MANAGEMENT_ROW_PADDING_TOP = 8;
    public static MANAGEMENT_ROW_PADDING_BOTTOM = 50;
    public static MANAGEMENT_ROW_MARGIN_TOP = 12;
    public static APPLICATION_IMAGE_WIDTH = 40;
    public static APPLICATION_IMAGE_HEIGHT = 40;
    public static APPLICATION_IMAGE_MARGIN_RIGHT = 16;
    public static APPLICATION_TEXT_MARGIN_RIGHT = 4;
    public static APPLICATION_LIST_MARGIN_BOTTOM = 40;
    public static APPLICATION_TEXTINPUT_PADDING_LEFT = 12;
    public static APPLICATION_TEXTINPUT_PADDING_TOP = 8;
    public static APPLICATION_TEXTINPUT_PADDING_RIGHT = 24;
    public static APPLICATION_ALPHABETINDEX_MARGIN_TOP = 12;
    public static APPLICATION_ALPHABETINDEX_WIDTH = 24;
    public static LOADING_WIDTH = 100;
    public static BAR_WIDTH = 250;

    //group number
    public static FIXED_GROUP = 1;
    public static CHANGE_GROUP = 2;
    public static OTHER_GROUP = 3;
    public static EXTRA_GROUP = 4;

    //Permission state
    public static PERMISSION_ALLOW = 0;
    public static PERMISSION_BAN = 1;
    public static PERMISSION_ONLY_THIS_TIME = 2;
    public static PERMISSION_ALLOWED_ONLY_DURING_USE = 3;

    //shape
    public static SHAPE_DIA = 20;

    public static PERMISSION_INDEX = 0;
    public static PERMISSION_NUM = 0;

    // permission flag
    public static PERMISSION_DEFAULT = 0;
    public static PERMISSION_FLAG = 2;
    public static PERMISSION_SYSTEM_FIXED = 4;
    public static PERMISSION_COMPONENT_SET = 16;
    public static PERMISSION_POLICY_FIXED = 32;
    public static PERMISSION_ALLOW_THIS_TIME = 64;

    public static START_SUBSCRIPT = 0
    public static END_SUBSCRIPT = 500
    public static MAXIMUM_HEADER_LINES = 1
    public static MAXIMUM_HEADER_WIDTH = 200
    public static MAXIMUM_HEADER_HEIGHT = 500
    public static MAXIMUM_HEADER_LENGTH = 1000

    public static RECORD_PADDING_BOTTOM = '20%'

    //////////////security_dialog///////////////

    // icon
    public static SECURITY_ICON_WIDTH = 48;
    public static SECURITY_ICON_HEIGHT = 48;
    public static PADDING_TWICE = 2;

    // header
    public static SECURITY_HEADER_MAX_LINES = 2;
    public static SECURITY_HEADER_MAX_SCALE = 2;

    ////////////////////////////////////////////

    // icon of dialog
    public static DIALOG_ICON_WIDTH = 24;
    public static DIALOG_ICON_HEIGHT = 24;
    public static DIALOG_ICON_MARGIN_TOP = 23;

    // label text of dialog
    public static DIALOG_LABEL_FONT_SIZE = 10;
    public static DIALOG_LABEL_MARGIN_TOP = 2;
    public static DIALOG_LABEL_LINE_HEIGHT = 14;

    // request text of dialog
    public static DIALOG_REQ_MARGIN_TOP = 16;

    public static RESULT_SUCCESS = 1
    public static RESULT_FAILURE = 0
    public static RESULT_CODE = 0
    public static RESULT_CODE_1 = 1

    //location status
    public static LOCATION_NONE = 0
    public static LOCATION_FUZZY = 1
    public static LOCATION_UPGRADE = 2
    public static LOCATION_BOTH_PRECISE = 3
    public static LOCATION_BOTH_FUZZY = 4

    //location canvas
    public static LOCATION_CANVAS_HEIGHT = 172;
    public static LOCATION_CANVAS_MARGIN_TOP = 4;
    public static LOCATION_CANVAS_MARGIN_BOTTOM = 8;
    public static LOCATION_CANVAS_INITIAL_SCALE = 1;
    public static LOCATION_CANVAS_ZOOM_SCALE = 1.3;
    public static LOCATION_BUTTON_HEIGHT = 32;
    public static LOCATION_BUTTON_RADIUS = 16;
    public static LOCATION_BUTTON_POSITION_Y = 16;
    public static LOCATION_ICON_POSITION_X = 228;
    public static LOCATION_ICON_POSITION_Y = 86.5;
    public static LOCATION_CIRCLE_POSITION_X = 194;
    public static LOCATION_CIRCLE_POSITION_Y = 62.5;
    public static LOCATION_ICON_WIDTH = 24;
    public static LOCATION_ICON_HEIGHT = 29;
    public static LOCATION_CIRCLE_DIA = 94;
    public static LOCATION_CIRCLE_OPACITY = 0.3;
    public static LOCATION_ANIMATION_DURATION = 400;

    //
    public static SETTING_OPER = -1
    public static PASS_OPER = 0
    public static DYNAMIC_OPER = 1
    public static INVALID_OPER = 2

    //global dialog
    public static ROW_HEIGHT = 56

    public static ACCESS_TOKEN = 'ohos.security.accesstoken.tokencallback'
    public static SEC_COMP_DIALOG_CALLBACK = 'ohos.security.ISecCompDialogCallback'

    // permission dialogs
    public static GLOBAL_SWITCH_CAMERA = 0;
    public static GLOBAL_SWITCH_MICROPHONE = 1;

    public static PERMISSION_DIALOG_SUCCESS = 0;

    public static ERR_MODAL_ALREADY_EXIST = 1;
    public static ERR_PERMISSIONS_NOT_SAME_GROUP = 2;
    public static ERR_PERMISSIONS_NOT_IN_CONFIG = 3;
    public static ERR_PERMISSIONS_ALL_GRANTED = 4;
    public static ERR_PERMISSIONS_FLAG_DEFAULT = 5;
    public static ERR_PERMISSION_GRANT_EXCEPTION = 6;

    public static ERR_GLOBAL_SWITCH_NOT_SUPPORTED = 2;
    public static ERR_GLOBAL_SWITCH_IS_ON = 3;
    public static ERR_GLOBAL_SWITCH_EXCEPTION = 4;

    // permission system error codes
    public static CREATE_WINDOW_REPEATED = 1300001;

    public static CUSTOMIZE_BUTTON_WIDTH = 152;
    public static CUSTOMIZE_BUTTON_TEXT_MIN_SIZE = 12;
    public static CUSTOMIZE_BUTTON_TEXT_MAX_SIZE = 15;

    // SecurityToast
    public static TOAST_SYMBOLGLYPH_FONTSIZE = '16vp';
    public static TOAST_TEXT_MIDDLE_FONT_SIZE = '12vp';
    public static TOAST_POSITION_Y_UP = 15;
    public static TOAST_POSITION_Y_UNDER = -15;
    public static TOAST_ANIMATION_OFFSET = 80;
    public static TOAST_ANIMATION_TIMEOUT_START = 100;
    public static TOAST_ANIMATION_TIMEOUT_END = 3100;
    public static TOAST_ANIMATION_TIMEOUT_ID = 3500;
    public static TOAST_ICON_FONTSIZE_4 = 4;
    public static TOAST_ICON_FONTSIZE_2 = 2;
    public static TOAST_ICON_FONTSIZE_16 = 16;
    public static TOAST_ICON_FONTSIZE_14 = 14;
    public static TOAST_MAX_FONT_SCALE = 1;
    public static TOAST_CONSTRAINT_SIZE_MAX_WIDTH = 400;
    public static TOAST_CONSTRAINT_SIZE_MIN_HEIGHT = 36;
    public static TOAST_COLUMN_WIDTH = '100%';
    public static TOAST_COLUMN_HEIGHT = '100%';
    public static TOAST_FLEX_SHADOW_RADIUS_40 = 40;
    public static TOAST_FLEX_SHADOW_RADIUS_60 = 60;
    public static TOAST_FLEX_SHADOW_OFFSET_X = 0;
    public static TOAST_FLEX_SHADOW_OFFSET_Y = 10;
}

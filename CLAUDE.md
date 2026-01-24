# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PermissionManager is a system application for OpenHarmony that provides:
- Permission dialog boxes during app runtime including user_grant permission request dialog, global switch dialog and security component usage dialog.
- Permission management settings (accessible via Settings → Privacy → Permission Manager).

This is a OpenHarmony application written in ArkTS (TypeScript variant), using the Stage model.

## Background

- **User_grant permissions** are authorized by the user. The application with this type of permission can access user personal information. This type of permissions must be declared in the application installation package and authorized by the user in a dialog box during the running of the application. The application has the permission only after the user has granted it. 

- **Permission Group**: A permission group consists of user_grant permissions that are logically related to reduce the number of permission pop-up windows. It helps minimize the number of dialogs that are presented to the user when an application requests closely related permissions. A permission in a permission group is called a sub-permission of the group.

- **Global switch** of a permission is used for forbiddening all applications from using a permission.

- **Security components** are a set of button-like ArkUI components provided with certain permissions. After it is integrated into an application and is used for the first time, a dialog box is displayed to ask for user authorization. If the user taps Allow, the application automatically obtains the permission  within a short period of time. No more dialog box is displayed for authorization.

- **Permission management settings** provides function to manage permission and view permission records

## Project Structure

```
permission_manager/
├── entry/                    # Entry module (UI entry point)
│   └── src/main/ets/         # Source code for entry
├── permissionmanager/        # Main permission manager module
│   └── src/main/ets/
│       ├── Application/      # AbilityStage configuration
│       ├── MainAbility/      # Main UI ability entry point
│       ├── ServiceExtAbility/      # Service extension for permission grants
│       ├── GlobalExtAbility/       # Service extension for global switch
│       ├── SecurityExtAbility/     # Service extension for security component
│       ├── PermissionSheet/        # Permission management ability
│       ├── common/
│       │   ├── base/              # Base classes (ViewModel, Strategy patterns)
│       │   ├── components/        # Reusable UI components
│       │   ├── model/             # Data models and type definitions
│       │   ├── observer/          # Event observers
│       │   ├── permissionGroupManager/  # Permission strategy implementations
│       │   └── utils/             # Utility functions
│       └── pages/              # Application pages (UI screens)
├── AppScope/                 # Application-level configuration
├── signature/                # Signing certificates
└── BUILD.gn                 # GN build configuration for system integration
```

## Architecture


### Ability Model (Stage Model)

The application uses the OpenHarmony Stage model with multiple abilities:

- **MainAbility**: Main UI entry point, handles bundle monitoring and application listing.
- **ServiceExtAbility**: Starts a dialog box for requesting user authorization.
- **GlobalExtAbility**: Starts a dialog for asking for enable a permission when the global switch of a permission which is turned off. This pop-up is triggered by the system and is not an application request.
- **SecurityExtAbility**: Starts a dialog for user authorization to use the security component.
- **PermissionStateSheetAbility**: The ability provides three funtions. `Permissoins` sheet displays all user_grant permissions, allowing users to view which applications have that permission and manage their permission status. `Application` sheet presents information by application dimension, showing the permissions it has requested and manage the permission status of each permission. It also provides a record of permission usage for applications.
- **GlobalSwitchSheetAbility**: Start a dialog for turning on global switch of the permission. When the features such as recording and photographing are disabled, the application can display the dialog box, asking the user to enable the related features.


### Permission Strategy Pattern

The `permissionGroupManager/` directory contains strategy implementations for different permission groups:
- Each permission group (Camera, Location, Microphone, etc.) has its own Strategy class
- `PermissionGroupManager.ets` orchestrates these strategies
- Strategies implement `BasePermissionStrategy.ets`

### Page Structure

Pages in `pages/` directory include:
- `authority-management.ets` - Main permission management view (all apps)
- `application-secondary.ets` - Single app permission view
- `application-tertiary.ets` - App permission details
- `authority-tertiary.ets` - Permission category details
- `permission-access-record.ets` - Permission usage records
- `authority-tertiary-groups.ets` - Permission group details
- `dialogPlus.ets` - Permission request dialog
- `globalSwitch.ets` - Global switch of permission dialog
- `securityDialog.ets` - Security component usage dialog

## Build System

### Development Commands

```
./build.sh --product-name rk3568 --build-target //applications/standard/permission_manager:permission_manager
```
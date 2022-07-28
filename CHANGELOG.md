# Changelog

## Upcoming

- Added new SSL certificate of [parley.nu](https://parley.nu) for SSL pinning.
- Fixed a crash when sending or receiving a new message when there is no welcome message.
- Fixed a crash when setting the user information after calling `Parley.configure()`.
- Fixed a crash that could happen due to keyboard visiblity.
- When setting or clearing the user information, Parley will now reconfigure itself to show the contents of the corresponding chat.
- Calling `Parley.configure()` twice without resetting Parley is unsupported and will now throw an error when this happens.

## 3.5.1 - Released 21 Jul 2022

- Fixed crashes when using carousels and quick replies when using SPM.

## 3.5.0 - Released 2 May 2022

### Upgrading:

Parley now uses a unique device id per app installation as default setting.

**IMPORTANT**: When using anonymous chats, the chat now always starts empty after a new app installation by default.

_What's changed?_

- In Parley 3.4.2 and lower the iOS `identifierForVendor` was used as device id. This device id does not change per app installation, causing anonymous chats to continue with their existing chat even when the user deleted and reinstalled the app. 
- In Parley 3.5.0 and higher a random UUID is used as device id. This value is stored in the user defaults by default and is generated once per installation. Updating the app won't result in a new device id as long as the user defaults aren't cleared. This ensures that new anonymous chats always start empty.

**Note**: This only affects the behavior of starting anonymous chats, chats that use the user authorization won't be affected by this change.

**Note**: This is the default behavior of Parley. When passing the device id to the configure method, Parley will use that as device id instead and won't store it in the user defaults either.

### Changes:

- Device id is now unique per installation, instead of using the iOS `identifierForVendor`. Affects how anonymous chats are handled.
- Added optional `Parley.reset(callback)` method to reset Parley back to its initial state, clearing the user and chat data that is in memory.

## 3.4.2 - Released 2 May 2022

- Added optional `uniqueDeviceIdentifier` parameter to the configure method to override the default device identifier that Parley uses.

## 3.4.1 - Released 19 Jan 2022

- Fixed date message not showing up directly when sending the first message of the day
- Fixed date messages showing incorrect date in some cases

## 3.4.0 - Released 12 Nov 2021

- Added `ParleyViewAppearance.notificationsPosition` to configure where the notifications should be shown in the chat: `.top` (default) or `.bottom`.
  For example: to show them on the bottom of the chat, use:
  ```
  let appearance = ParleyViewAppearance(...) 
  appearance.notificationsPosition = .bottom
  parleyView.appearance = appearance
  ```

## 3.3.1 - Released 10 Nov 2021

- Fixed an issue where (sticky) messages were hidden unintentionally due to concurrency
- Fixed links within parentheses not being clickable

## 3.3.0 - Released 27 Oct 2021

### Updating:

- **NOTE (BREAKING)**: When specyfing a custom `ParleyNetwork` and using API 1.5 or lower, the default implementation may break the images functionality in the chat. To resolve this: specify the used `apiVersion` in the `ParleyNetwork`.
- **DEPRECATION**: Using `ParleyNetwork` without `apiVersion` is now deprecated. Please specify an `apiVersion` when using `ParleyNetwork`.
- **DEPRECATION**: `ParleyMessageViewAppearance.buttonHeight` is now deprecated and unused since version 3.3.0. Style the buttons by using `ParleyMessageViewAppearance.buttonInsets` instead.

### Changes:

- Added support for API 1.6
- Added `ApiVersion` parameter to `ParleyNetwork`
- By default Parley will now target API 1.6
- Parley is now using the new media implementation when using API 1.6 or higher
- Added `buttonsInsets` field to `ParleyMessageViewAppearance` to control the insets for the buttons

## 3.2.4 - Released 13 Oct 2021

- Fixed an issue with imports when using SPM

## 3.2.3 - Released 12 Oct 2021

**NOTE**: This release does not work in combination with SPM, use the next version 3.2.4 instead.

### Changes:

- Added polling when notifications are disabled
- Updated default base url to latest version: v1.5
- Fixed crash on iPad when presenting `.actionSheet`
- Fixed demo app appearance on iOS 15 when using xCode 13

## 3.2.2 - Released 27 Sep 2021

- Added support for buttons with types `webUrl`, `phoneNumber` and `reply`
- Quick replies now don't require a message to show anymore
- Carousel now doesn't require a message to show anymore
- Carousel now also shows the time inside the items
- Updated the documentation and added CHANGELOG.md

## 3.2.1 - Released 20 Aug 2021

- Links inside messages that were not formatted as Markdown are now clickable as well

## 3.2.0 - Released 20 Aug 2021

### Upgrading:

- **DEPRECATION**: `setFcmToken(_:)`  is now deprecated, use `setPushToken(_:)` instead.

### Changes:

- Added support for sending (silent) messages
- Added support for setting the referrer
- Added support for setting the push type

## 3.1.5 - Released 1 Jun 2021

- Added autocorrect to the compose textview

## 3.1.4 - Released 1 Jun 2021

- Fixed several crashes reported by the clients of Parley

## 3.1.3 - Released 1 Jun 2021

- Added support for Swift Package Manager

## 3.1.2 - Released 31 Mar 2021

- Fixed an issue in layout constraints 

## 3.1.1 - Released 29 Mar 2021

- Fixed an issue where the sticky was not being shown

## 3.1.0 - Released 25 Mar 2021

### Upgrading:

Version 3.1.0 contains a breaking change related to Public Key Pinning. Parley is not depending on TrustKit anymore.

Check out step 5 of the configuration in the [README.md](README.md) to apply the new configuration

- **REMOVED**: The `pin1` and `pin2` parameters have been removed from the `ParleyNetwork` initializer

### Changes:

- Removed TrustKit dependency for SSL pinning (SSL pinning is still fully supported)
- Initial version with support for rich messaging

## 3.0.1 - Released 23 Sep 2020

- Updated default SSL pins for Parley

## 3.0.0 - Released 3 Oct 2019

The first release of version 3.0 of the Parley library

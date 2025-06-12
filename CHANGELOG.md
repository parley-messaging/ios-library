# Changelog

## 4.2.11 - Released 12 Jun 2025

- [SSL Pinning] Updated SSL pinning public key of Parley.

## 4.2.10 - Released 2 May 2025

- [Accessibility] Added configurable background color to time and checkmark in messages and made corner radius configurable.
- [Styling] Changed `imageTimeBackgroundColor` to `imageMetaBackgroundColor` in `ParleyMessageViewAppearance`.
- [Styling] Changed `imageTimeSpacing` to `imageMetaSpacing` in `ParleyMessageViewAppearance`.
- [Styling] Changed `imageTimeHorizontalPadding` to `imageMetaHorizontalPadding` in `ParleyMessageViewAppearance`.
- [Styling] Added `imageMetaCornerRadius` to `ParleyMessageViewAppearance` to adjust the corner radius.

## 4.2.9 - Released 25 Apr 2025

- [Accessibility] Added customizable background to time labels in image messages, with configurable color, spacing, and padding.  
- [Styling] Added `imageTimeBackgroundColor` to `ParleyMessageViewAppearance` to set the background color.  
- [Styling] Added `imageTimeSpacing` to `ParleyMessageViewAppearance` to adjust spacing between icon and time.  
- [Styling] Added `imageTimeHorizontalPadding` to `ParleyMessageViewAppearance` to modify horizontal padding around the time label.

## 4.2.8 - Released 31 Mar 2025

- [Chat] Resolved an issue where new messages would not be displayed when ParleyView was added before configuring Parley.
- [Chat] Resolved an issue where messages would not update when ParleyView was added before configuring Parley.

## 4.2.7 - Released 28 Mar 2025

- [Chat] Resolved an issue where messages would not be displayed when ParleyView was added before configuring Parley.
- [Configure] Fixed a crash when not calling the configure method from the main thread.

## 4.2.6 - Released 26 Mar 2025

- [Chat] Resolved an issue where messages would not be displayed when ParleyView was added before configuring Parley.
- [Messages] Resolved a potential issue where messages would not be sorted correctly.
- [Packages] Replaced Reachability library with NWPathMonitor (PR #196, thanks mat1th).
- [ParleyNetwork] Senable conformance has been added (PR #194, thanks mat1th).

## 4.2.5 - Released 13 Mar 2025

- [Core] The core has been adjusted with how messages are setup, grouped, and shown. Thisi mproves separation in code (required for some current and upcoming changes, visually no changes).
- [Date Headers] Date headers are now headers in the chat which are persistent on top when viewing messages of a specific day.
- [Accessibility] Improved VoiceOver navigation on date headers.
- **DEPRECATION**: `DateTableViewCellAppearance`has been renamed to `DateHeaderAppearance`.

## 4.2.4 - Released 17 Jan 2025

- **IMPORTANT**: When using custom appearance, adjust the `let appearance = ParleyViewAppearance(...)` to a `var`.
- [Styling] Changed most Appearance classes to structs, allowing easier creation of the appearance classes.
- [Styling] Added `style` to DateTableViewCellAppearance to configure the dateformatter style of the date headers (fixes #109).
- [Message] Improved gradient behind agent name when adjusting text scaling (fixes #111).
- [Compose] Fixed placeholder going out of bounds in some cases (fixes #124).
- [Accessibility] Links are now underlined to improve accessibility (fixes #104).
- [Strings] Fixed some typos (fixes #171).
- [Accessibility] Added localization to use for VoiceOver for the compose placeholder (fixes #170).
- [Implementation] Fixed a case where calling `reset` or `purgeLocalMemory` could cause a crash if not called on the main thread (fixes #141).
- [Accessibility] Allow opening media and files when using VoiceOver (fixes #169).
- [Viewer] Fixed an issue when rotating the device when the image viewer is showing (fixes #129).
- [Styling] Added `sendButtonSize` to ParleyComposeViewAppearance (partially adresses #108).
- [Styling] Added `sendButtonShape` to ParleyComposeViewAppearance (partially adresses #108).
- [Chat] Fixed an issue causing consecutive date headers to be shown (fixes #128).
- [Typing] Added `dots` which is a `AgentTypingTableViewCellAppearance.DotsAppearance` to AgentTypingTableViewCellAppearance to allow styling the typing message (fixes #105).
- **DEPRECATION**: Using `AgentTypingTableViewCellAppearance.dotColor` is now deprecated, use `AgentTypingTableViewCellAppearance.dots` instead.

## 4.2.3 - Released 28 Oct 2024

- Fixed images flickering when device orientation changes from to faceUp/faceDown.

## 4.2.2 - Released 17 Oct 2024

- Fixed `fileActionFont` not updating on initial load.
- Styling: Added `ParleyMessageViewAppearance.fileIcon` to configure the icon for files.

## 4.2.1 - Released 10 Oct 2024

- Fixed `LocalizationManager` not localizing keys that had arguments.
- **IMPORTANT**: When using the `LocalizationManager`, the structure of the protocol has changed slightly to support arguments.

## 4.2.0 - Released 31 Jul 2024

- Added support for uploading PDF files.
- Added support for showing and opening PDF files inside the chat.
- Fixed an issue where reusing Parley after `reset` or `purgeLocalMemory` could cause a crash (due to the registered observers).
- Fixed removing registered observers not being removed as expected.
- Parley doesn't crash itself now when doing a call when no secret is set (fail-safe and neater, but the found case doesn't happen anymore).
- Styling: `mediaIcon` has been added ParleyComposeViewAppearance.
- Styling: `mediaTintColor` has been added ParleyComposeViewAppearance. 
- Styling: `fileIconTintColor` has been added ParleyMessageViewAppearance.
- Styling: `fileNameColor` has been added ParleyMessageViewAppearance.
- Styling: `fileActionColor` has been added ParleyMessageViewAppearance.
- Styling: `fileInsets` has been added ParleyMessageViewAppearance.
- Styling: `fileContentInsets` has been added ParleyMessageViewAppearance.
- **DEPRECATION**: ParleyView's `imagesEnabled` is now deprecated, replace it with `mediaEnabled`.
- **DEPRECATION**: `ParleyImageDataSource` is now deprecated, replace it with `ParleyMediaDataSource`.
- **DEPRECATION**: `ParleyEncryptedImageDataSource` is now deprecated, replace it with `ParleyEncryptedMediaDataSource`.
- **DEPRECATION**: `cameraIcon` is now deprecated on ParleyComposeViewAppearance, replace it with `mediaIcon`.
- **DEPRECATION**: `cameraTintColor` is now deprecated on ParleyComposeViewAppearance, replace it with `mediaTintColor`.

## 4.1.8 - Released 12 Jul 2024

**IMPORTANT**: Parley 4.1.8 contains a minor breaking change when using a custom network implementation. Migrating can be done easily by removing the return types to adhere to the `ParleyNetworkSession` implementation again.

- [Network] Running network requests on background queue.
- [Network] Removed cancelable implementation, since this was not being used anymore.
- [Chat] Fixed an issue that could cause a crash when entering foreground after resetting due to the registered observers.

## 4.1.7 - Released 18 Jun 2024

- Fixed polling service not renewing when Parley is being reconfigured.

## 4.1.6 - Released 18 Jun 2024

- Fixed an issue where multiple polling timers were added when it reached the last interval.

## 4.1.5 - Released 18 Jun 2024

- Fixed an issue where polling wasn't being enabled when it should be.

## 4.1.4 - Released 14 Jun 2024

- Fixed a crash when showing the ParleyView before configuring Parley.
- The ParleyView now reveals the chat messages after all loading is done (fixes a slight noticable scroll when the ParleyView is already visible). 

## 4.1.3 - Released 5 Jun 2024

- Fixed polling functionality resetting its timer more frequently than intended.
- Fixed always polling sometimes causing the initial information message to disappear or not show up as intended.
- Automatically scroll to the bottom when new messages are received via polling.

## 4.1.2 - Released 4 Jun 2024

- Fixed an issue where scrolling up to load more messages could get the chat not to load even more messages.
- Fixed an issue where loading more messages didn't scroll back to the earlier shown message after updating.
- Fixed loading more messages triggering the API call twice sometimes.
- Aligned image heights in the chat to be the same as Android (180, instead of 160). 

## 4.1.1 - Released 31 May 2024

- Fixed an issue where the image viewer sometimes didn't show the image correctly.
- Fixed agent name not scaling with dynamic font.
- Fixed meta issues with dynamic font.
- Added `Parley.purgeLocalMemory()` method to clear local memory of Parley. Requires calling `configure()` again.
- Increased meta shadow height for better visibility.
- Added `Parley.setLocalizationManager(manager)` for overriding localizations used by Parley.
- Improved media capture and selection by requesting permissions after selecting the desired option.
- Improved media selection for iOS 14 and above by using PHPickerViewController, resulting in needing less permission for sending media.
- Added more (screenshot) tests for Parley.

## 4.1.0 - Released 28 May 2024

**IMPORTANT**: With Parley 4.1.0 there is a minor breaking change with appearance. Migrating can be done easily by adjusting to the new `ParleyTextViewAppearance` in such cases.

- Styling: `ParleyTextViewAppearance` has been introduced to be able to style the fonts and colors for text views used by Parley.
- Styling: `MessageCollectionViewCellAppearance` now has `messageTextViewAppearance` (instead of just the `messageColor` attribute).
- Styling: `ParleyMessageViewAppearance` now has `messageTextViewAppearance` (instead of just the `messageColor` and `messageTintColor` attribute).
- Styling: `ParleyStickyViewAppearance` now has `textViewAppearance` (instead of just the `color` and `tintColor` attribute).
- Preventing duplicate creation of some classes.
- Added `Parley.setAlwaysPolling(enabled)` to be able to always enable polling. Default `false`, since the Parley refreshes the chat when needed via push notifications.
  Note: By default polling is only enabled when notification permissions are denied (unchanged compared to previous versions).
- Added `ParleyMessageViewAppearance.imageCorners` to specify the rounding corners for images.
- The `set` methods that have a callback always call their callback now (instead of only when Parley was configured).
- Better type safety in cell usage.
- Prevent initialization of some classes and observers while Parley wasn't using them yet (now they are created when used).
- Added screenshot testing.
- Fixed an issue with scaling of texts when using bigger/smaller font settings.
- Updated SSL pinning certificates.
- Fixed an issue with the image viewer not scaling images correctly.

## 4.0.2 - Released 8 Apr 2024

- Added `ParleyViewAppearance.loaderTintColor` to tint the loading indicator of the chat.

## 4.0.1 - Released 5 Apr 2024

### Upgrading:

**IMPORTANT**: With Parley 4.0.1 the `ParleyNetworkSession` has the `parameters` method changed to `data`. 

- This is only a small breaking change syntax-wise when implementing your own `ParleyNetworkSession`.
- The content of `data` should be put as the body of the request (the request content type is `application/json`, so if needed, it may be encoded as JSON in the body).
- Check out Parley's standard `AlamofireNetworkSession` to see how this is could be implemented.

### Changes:

- Updated `ParleyNetworkSession` protocol: Changed `parameters` to `data` to correctly reflect the intended usage.

## 4.0.0 - Released 15 Mar 2024

### Upgrading:

**IMPORTANT**: With Parley 4.0.0 there are a few breaking changes. Migrating can be done easily with a few changes.

_What's changed?_

- In Parley 3.9.2 and lower Parley provided a network implementation which uses the Alamofire dependency. Therefore the dependency to Alamofire was attached to the project by Parley.
- In Parley 4.0.0 and higher the network implementation is separated from the core. Resulting in the modules: `Parley` (required) and `ParleyNetwork` (optional). This enables using your own network implementation and prevents requiring the use of dependencies that the standard Parley implementation uses. When providing your own network implementation, there is no need to import `ParleyNetwork` to your project. For more information, see [Advanced - Network layer](README.md#network-layer).
- In Parley 4.0.0 some deprecated methods have been removed which used default values for their parameters for backwards compatibility. These were deprecated for a while already, and similar methods are available under the same name. Provide the required parameters now when facing this.
- In Parley 4.0.0 the Parley datasource required to enabling offline messaging has been split up to different datasources. Each datasource has its own responsibility now, rather than one datasource doing everything. All datasources are required to enable offline messaging. Parley still provides standard implementations for enabling offline messaging. See [Advanced - Offline messaging](README.md#offline-messaging) for the new implementation.
- In Parley 4.0.0 the `ParleyNetwork` to configure the network configuration (base url, path, api version and headers) has been renamed to `ParleyNetworkConfig`. The underlying structure remained the same.
- In Parley 4.0.0 the `Parley.setNetwork` method has been removed. Pass the new `ParleyNetworkConfig` to the `Parley.configure()` method.
- In Parley 4.0.0 support for the Parley Client API version 1.0 to 1.5 has been dropped. Please update to a newer version when using 1.5 or lower, for the available versions, see [Version lifetime](https://developers.parley.nu/docs/version-lifetime).

### Changes:

- Split up Parley package to `Parley` and `ParleyNetwork`. You can now use Parley with your own http network layer. To do so you can implement `ParleyNetworkSession`.
- Update Reachability to 5.2.0 (from 5.1.0)
- Move configuring network settings to the `Parley.configure` function to make the setup order more clear.
- Rename `ParleyNetwork` to `ParleyNetworkConfig` to better represent what the struct does.
- Removed support for Client API 1.0 to 1.5.
- Added appearance option to hide the offline and push disabled notification views ([#73](https://github.com/parley-messaging/ios-library/issues/73)).

## 3.9.2 - Released 16 Feb 2024

- Fixed taking pictures not sending (regression by 3.9.1).
- Fixed an issue where small image messages were not taking the full width.
- Fixed an issue causing some texts to display wrong.
- Fixed an issue causing loading more triggering too early and inconsistently.
- Fixed an issue where the chat wouldn't scroll fully to the bottom directly when opening the chat.
- Added support for client API 1.7.
- Removed an unneeded guard statement when handling push messages.

## 3.9.1 - Released 13 Feb 2024

- Parley now returns the formatted error message of the backend when an error occurs when configuring or registering the device.
- When selecting or sending an image that will fail to upload, an alert will be shown with the relevant error.
- When an image inside the chat contains an error, the error message will be shown in the chat.
- Resolved some memory leaks.
- Fixed an issue that could cause quick replies to show invisible, but taking up space.

## 3.9.0 - Released 17 Jan 2024

- Parley now uses `Codable` for mapping the models (instead of ObjectMapper). This change is backwards compatible. Existing chats remain unaffected and will continue to work.
- Updated Alamofire to 5.8.1 (from 5.4.1).
- Updated AlamofireImage to 4.3.0 (from 4.1.0).
- Removed ObjectMapper dependency.
- Fixed tests not showing up in Xcode.
- Moved library and the example project to SPM structure and removed CocoaPods structure.

## 3.8.0 - Released 1 Nov 2023

**IMPORTANT**: Parley now has a minimum deployment target of iOS 12.0.

- Added Dynamic Type support.
- Added support for VoiceOver.
  - Read through the chat.
  - Interact with the chat.
  - Announcing received messages.
  - Fully supporting rich message types.
- Added dismiss button to image viewer.
- All icons now preserve vector data for a cleaner resolve.
- Fixed an issue where the loading or typing indicator would not display in some cases.

## 3.7.0 - N/A - 19 Oct 2022

- No changes to the iOS library. This version was only released on Android. 

## 3.6.3 - Released 27 Jun 2023

- Added new SSL certificate of [parley.nu](https://parley.nu) for SSL pinning.

## 3.6.2 - Released 23 Jan 2023

- Fixed an issue causing quick replies not formatting correctly.
- Fixed an issue causing quick replies not to show up after receiving them via push.
- Fixed some layout issues when showing the notifications, sticky message, or quick replies during the chat.
- Fixed an issue with some carousel messages being cut off.

## 3.6.1 - Released 16 Aug 2022

- Fixed requests sometimes failing due to the body encoding (now forces JSONEncoding, instead of using the default setting of `Alamofire`).
- Fixed an issue causing suggestions showing on top of existing messages, instead of below them.
- Fixed an issue with suggestions drawing 50% when (re)opening the chat with quick replies.

## 3.6.0 - Released 28 Jul 2022

- Added new SSL certificate of [parley.nu](https://parley.nu) for SSL pinning.
- Fixed a crash when sending or receiving a new message when there is no welcome message.
- Fixed a crash when setting the user information after calling `Parley.configure()`.
- Fixed a crash that could happen due to keyboard visiblity.
- When setting or clearing the user information, Parley will now reconfigure itself when needed to show the contents of the corresponding chat.

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

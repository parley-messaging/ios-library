# Changelog

## 3.2.2 - Upcoming

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
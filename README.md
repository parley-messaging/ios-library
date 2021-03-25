# Parley Messaging iOS library

Easily setup a secure chat with the Parley Messaging iOS library. The Parley SDK allows you to fully customize the chat appearance and integrate it seamlessly in your own app for a great user experience.

*Pay attention: You need an `appSecret` to use this library. The `appSecret` can be obtained by contacting [Parley](https://www.parley.nu/).*

## Requirements

- iOS 11.0+
- Xcode 12+
- Swift 5+

**Firebase**

For remote notifications Parley relies on Google Firebase. Configure Firebase (using the [installation guide](https://firebase.google.com/docs/ios/setup)) if you haven't configured Firebase yet.

## Screenshots

Empty | Conversation
-- | --
![Parley](Screenshots/default-empty.png) | ![Parley](Screenshots/default.png)

## Installation

[CocoaPods](https://cocoapods.org) is a dependency manager for Cocoa projects. For usage and installation instructions, visit their website. To integrate Parley into your Xcode project, specify it in your `Podfile`:

```ruby
pod 'Parley', '~> 3.1.0'
```

### Upgrading from 3.0.x to 3.1.0

3.1.0 contains a breaking change related to Public Key Pinning. Parley is not depending on TrustKit anymore.

Check out step 5 of the configuration to apply the new configuration.

## Getting started

Follow the next steps to get a minimal setup of the library.

### Step 1: Add the `ParleyView` to a *ViewController*

The `ParleyView` can be initialized manually or directly from the Storyboard.

**Manual**

Open the *ViewController* and add the following import:

```swift
import Parley
```

Create an instance of the Parley view (for example) in the `viewDidLoad`.

```swift
override func viewDidLoad() {
  super.viewDidLoad()

  let parleyView = ParleyView()
  parleyView.frame = self.view.frame

  self.view.addSubview(parleyView)
}
```

**Storyboard**

Add a view to the View Controller, select the `Show the Identity inspector` tab and change the `Custom Class` section to:

```
Class: ParleyView
Module: Parley
```

### Step 2: Configure Parley

Configure Parley with your `appSecret` with `Parley.configure(_ secret: String)` (for example in your *ViewController* from step 1).

```swift
Parley.configure("appSecret")
```

*Replace `appSecret` by your Parley `appSecret`. The `appSecret` can be obtained by contacting [Parley](https://www.parley.nu/).*

### Step 3: Configure Firebase

Parley needs the FCM token to successfully handle remote notifications.

**FCM Token**

After retrieving an FCM token via your Firebase instance, pass it to the Parley instance in order to support remote notifications. This is can be done by using `Parley.setFcmToken(_ fcmToken: String)`.

```swift
Parley.setFcmToken("fcmToken")
```

**Handle remote notifications**

Open your `AppDelegate` and add `Parley.handle(_ userInfo: [AnyHashable: Any])` to the `didReceiveRemoteNotification` method to handle remote notifications.

```swift
extension AppDelegate : UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        _ = Parley.handle(userInfo)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if UIApplication.shared.applicationState == .active {
            completionHandler([]) // Do not show notifications when app is in foreground
        } else {
            completionHandler([.alert, .sound])
        }
    }
}
```

### Step 4: Camera usage description

Add a camera and photo library usage description to the `Info.plist` file.

```xml
<key>NSCameraUsageDescription</key>
<string>We need access to the camera to take photos.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to the photo library to select photos.</string>
```

### Step 5: Add the certificate of the chat API

By default, Parley applies Public Key Pinning on every request executed to the chat api. In order to do you need to add the certificate to your project.

You can use the certificate in this repository when using the default base url (`/Example/ParleyExample/Supported Files/*.parley.nu.cer`).

*More information about Public Key Pinning can be found on the website of [OWASP](https://www.owasp.org/index.php/Certificate_and_Public_Key_Pinning).*

## Advanced

Parley allows the usage of advanced configurations, such as specifying the network, specifying the user information or enabling offline messaging. In all use cases it is recommended to apply the advanced configurations before configuring the chat with `Parley.configure(_ secret: String)`.

### Network

The network configuration can be set by setting a `ParleyNetwork` with the `Parley.setNetwork(_ network: ParleyNetwork)` method.

```swift
let network = ParleyNetwork(
    url: "https://api.parley.nu/",
    path: "clientApi/v1.2/",
)

Parley.setNetwork(network)
```

*Don't forget to add the right certificate to the project.*

**Custom headers**

Custom headers can be set by using the optional parameter `headers` in `ParleyNetwork`. The parameter accepts a `[String: String]` Dictionary.

Note that the headers used by Parley itself cannot be overridden.

```swift
let headers: [String: String] = [
    "X-Custom-Header": "Custom header value"
]

let network = ParleyNetwork(
    url: "https://api.parley.nu/",
    path: "clientApi/v1.2/",
    headers: headers
)

Parley.setNetwork(network)
```

### User information

The chat can be identified and encrypted by applying an authorization token to the `Parley.setUserInformation(_ authorization: String)` method. The token can easily be generated on a secure location by following the _[Authorization header](https://developers.parley.nu/docs/authorization-header)_ documentation.

```swift
let authorization = "ZGFhbnw5ZTA5ZjQ2NWMyMGNjYThiYjMxNzZiYjBhOTZmZDNhNWY0YzVlZjYzMGVhNGZmMWUwMjFjZmE0NTEyYjlmMDQwYTJkMTJmNTQwYTE1YmUwYWU2YTZjNTc4NjNjN2IxMmRjODNhNmU1ODNhODhkMmQwNzY2MGYxZTEzZDVhNDk1Mnw1ZDcwZjM5ZTFlZWE5MTM2YmM3MmIwMzk4ZDcyZjEwNDJkNzUwOTBmZmJjNDM3OTg5ZWU1MzE5MzdlZDlkYmFmNTU1YTcyNTUyZWEyNjllYmI5Yzg5ZDgyZGQ3MDYwYTRjZGYxMzE3NWJkNTUwOGRhZDRmMDA1MTEzNjlkYjkxNQ"

Parley.setUserInformation(authorization)
```

**Additional information**

Additionally, you can set additional information of the user by using the `additionalInformation` parameter in `Parley.setUserInformation()` method. The parameter accepts a `[String: String]` Dictionary.

```swift
let authorization = "ZGFhbnw5ZTA5ZjQ2NWMyMGNjYThiYjMxNzZiYjBhOTZmZDNhNWY0YzVlZjYzMGVhNGZmMWUwMjFjZmE0NTEyYjlmMDQwYTJkMTJmNTQwYTE1YmUwYWU2YTZjNTc4NjNjN2IxMmRjODNhNmU1ODNhODhkMmQwNzY2MGYxZTEzZDVhNDk1Mnw1ZDcwZjM5ZTFlZWE5MTM2YmM3MmIwMzk4ZDcyZjEwNDJkNzUwOTBmZmJjNDM3OTg5ZWU1MzE5MzdlZDlkYmFmNTU1YTcyNTUyZWEyNjllYmI5Yzg5ZDgyZGQ3MDYwYTRjZGYxMzE3NWJkNTUwOGRhZDRmMDA1MTEzNjlkYjkxNQ"

let additionalInformation = [
    kParleyAdditionalValueName: "John Doe",
    kParleyAdditionalValueEmail: "j.doe@parley.nu",
    kParleyAdditionalValueAddress: "Randstad 21 30, 1314, Nederland"
]

Parley.setUserInformation(authorization, additionalInformation: additionalInformation)
```

**Clear user information**

```swift
Parley.clearUserInformation()
```

### Offline messaging

Offline messaging can be enabled with the `Parley.enableOfflineMessaging(_ dataSource: ParleyDataSource)` method. `ParleyDataSource` is a protocol that can be used to create your own (secure) data source. In addition to this, Parley provides an encrypted data source called `ParleyEncryptedDataSource` which uses AES128 encryption.

```swift
if let key = "1234567890123456".data(using: .utf8), let dataSource = try? ParleyEncryptedDataSource(key: key) {
    Parley.enableOfflineMessaging(dataSource)
}
```

**Disable offline messaging**

```swift
Parley.disableOfflineMessaging()
```

## Customize

### Callbacks

Parley provides a `ParleyViewDelegate` that can be set on the `ParleyView` for receiving callbacks.

```swift
self.parleyView.delegate = self
```

```swift
extension ChatViewController: ParleyViewDelegate {

    func didSentMessage() {
        debugPrint("ChatViewController.didSentMessage")
    }
}
```

### Appearance

**Images**

Image upload is enabled by default.

```swift
self.parleyView.imagesEnabled = false
```

**Appearance**

Parley provides a `ParleyViewAppearance` that can be set on the `ParleyView` to customize the chat appearance. `ParleyViewAppearance` can be initialized with a regular, italic and bold font which are customizable. Take a look at [ChatViewController.swift](Example/ParleyExample/Controllers/ChatViewController.swift#L32) for an example of how to use the `ParleyViewAppearance`.

```swift
let appearance = ParleyViewAppearance(fontRegularName: "Montserrat-Regular", fontItalicName: "Montserrat-Italic", fontBoldName: "Montserrat-Bold")

self.parleyView.appearance = appearance
```

#### Examples

Modern | WhatsApp
-- | --
![Parley](Screenshots/modern.png) | ![Parley](Screenshots/whatsapp.png)

## License

Parley is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

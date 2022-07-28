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

### Swift Package Manager

The Swift Package Manager is a tool for automating the distribution of Swift code and is integrated into the swift compiler.

Once you have your Swift package set up, adding Parley as a dependency is as easy as adding it to the dependencies value of your Package.swift.

```
dependencies: [
    .package(url: "git@github.com:parley-messaging/ios-library.git", .upToNextMajor(from: "3.5.x"))
]
```

### Upgrading

Checkout [CHANGELOG.md](CHANGELOG.md) for the latest changes and upgrade notes.

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

*Note: calling `Parley.configure()` twice is unsupported and will result in an error.*

### Step 3: Configure Firebase

Parley needs the FCM token to successfully handle remote notifications.

**FCM Token**

After retrieving an FCM token via your Firebase instance, pass it to the Parley instance in order to support remote notifications. This is can be done by using `Parley.setPushToken(_:)`.

```swift
Parley.setPushToken("pushToken")
```

**Other push types**

```swift
Parley.setPushToken("pushToken", pushType: .customWebhook)
Parley.setPushToken("pushToken", pushType: .customWebhookBehindOAuth)
Parley.setPushToken("pushToken", pushType: .fcm) // Default
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

You can use the certificate in this repository when using the default base url (`/Example/ParleyExample/Supported Files/*.parley.nu_21-Aug-2022.cer`).

When a certificate is going to expire you can safely transition by adding the new `.cer` to the project. It is important to leave the old `.cer` in the app until after the new one is valid. In the next release the old certificate can be removed.

*More information about Public Key Pinning can be found on the website of [OWASP](https://www.owasp.org/index.php/Certificate_and_Public_Key_Pinning).*

## Advanced

Parley allows the usage of advanced configurations, such as specifying the network, specifying the user information or enabling offline messaging. In all use cases it is recommended to apply the advanced configurations before configuring the chat with `Parley.configure(_ secret: String)`.

### Network

The network configuration can be set by setting a `ParleyNetwork` with the `Parley.setNetwork(_ network: ParleyNetwork)` method.

```swift
let network = ParleyNetwork(
    url: "https://api.parley.nu/",
    path: "clientApi/v1.6/",
    apiVersion: .v1_6 // Must correspond to the same version in the path
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
    path: "clientApi/v1.6/",
    apiVersion: .v1_6,
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

### Send a (silent) message

In some cases it may be handy to send a message for the user. You can easily do this by calling;

```swift
Parley.send("Lorem ipsum dolar sit amet")
```

**Silent**

It is also possible to send silent messages. Those messages are not visible in the chat.

```swift
Parley.send("User opened chat", silent: true)
```

### Referrer

```swift
Parley.setReferrer("https://parley.nu/")
```

### Custom Unique Device Identifier

By default Parley uses a random UUID as device identifier which will be stored in the user defaults. This can be overridden by passing a custom `uniqueDeviceIdentifier` to the configure method:

```swift
Parley.configure("appSecret", uniqueDeviceIdentifier: "uniqueDeviceIdentifier")
```

_When passing the `uniqueDeviceIdentifier` to the configure method, Parley will not store it. Client applications are responsible for storing it and providing Parley with the same ID in this case._

### Reset

Parley doesn't need to be reset usually, but in some cases this might be wanted. For example when a user logs out and then logs in with a different account. 

Resetting Parley will clear the current user information and chat data that is in memory. 
Requires calling the `configure()` method again to use Parley.

```swift
Parley.reset()
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

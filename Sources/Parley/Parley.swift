public struct Parley: Sendable {
    
    public typealias State = ParleyActor.State
    
    private(set) var localizationManager: LocalizationManager
    
    static nonisolated(unsafe) private(set) var shared = Parley()
    
    init(localizationManager: LocalizationManager) {
        self.localizationManager = localizationManager
    }
    
    init() {
        self.init(localizationManager: ParleyLocalizationManager())
    }
    
    /**
     Handle remote message.

     - Parameters:
       - userInfo: Remote message data.

     - Returns: `true` if Parley handled this payload, `false` otherwise.
     */
    public static func handle(_ userInfo: [AnyHashable: Any]) async -> Bool {
        await ParleyActor.shared.handle([:])
    }
    
    @available(
        *,
        deprecated,
        renamed: "enableOfflineMessaging(messageDataSource:keyValueDataSource:mediaDataSource:)",
        message: "Use enableOfflineMessaging(messageDataSource:keyValueDataSource:mediaDataSource:) instead"
    )
    public static func enableOfflineMessaging(
        messageDataSource: ParleyMessageDataSource,
        keyValueDataSource: ParleyKeyValueDataSource,
        imageDataSource: ParleyMediaDataSource
    ) async {
        await ParleyActor.shared.enableOfflineMessaging(
            messageDataSource: messageDataSource,
            keyValueDataSource: keyValueDataSource,
            imageDataSource: imageDataSource
        )
    }
    
    /**
     Enable offline messaging.

     - Parameters:
       - messageDataSource: ParleyMessageDataSource instance
       - keyValueDataSource: ParleyKeyValueDataSource instance
       - mediaDataSource: ParleyMediaDataSource instance
     */
    public static func enableOfflineMessaging(
        messageDataSource: ParleyMessageDataSource,
        keyValueDataSource: ParleyKeyValueDataSource,
        mediaDataSource: ParleyMediaDataSource
    ) async {
        await ParleyActor.shared.enableOfflineMessaging(
            messageDataSource: messageDataSource,
            keyValueDataSource: keyValueDataSource,
            mediaDataSource: mediaDataSource
        )
    }
    
    /**
     Disable offline messaging.

     - Note: The `clear()` method will be called on the current instance to prevent unused data on the device.
     */
    public static func disableOfflineMessaging() async {
        await ParleyActor.shared.disableOfflineMessaging()
    }
    
    /**
      Set the push token of the user.

      - Note: Method must be called before `Parley.configure(_ secret: String)`.

      - Parameters:
        - pushToken: The push token
        - pushType: The push type (default `fcm`)
        - onSuccess: Execution block when Firebase Cloud Messaging token is updated.
        - onFailure: Execution block when Firebase Cloud Messaging token can not updated. This block takes an Int which represents the HTTP Status Code and a String describing what went wrong.
     */
    public static func setPushToken(
        _ pushToken: String,
        pushType: Device.PushType = .fcm
    ) async -> ParleyActor.ConfigurationResult {
        await ParleyActor.shared.setPushToken(pushToken, pushType: pushType)
    }
    
    /**
      Set whether push is enabled by the user.

      - Parameters:
        - enabled: Indication if application's push is enabled.
        - onSuccess: Execution block when pushEnabled is updated.
        - onFailure: Execution block when pushEnabled can not updated. This block takes an Int which represents the HTTP Status Code and a String describing what went wrong.
     */
    public static func setPushEnabled(_ enabled: Bool) async -> ParleyActor.ConfigurationResult {
        await ParleyActor.shared.setPushEnabled(enabled)
    }
    
    /**
     Set user information to authorize the user.

     - Parameters:
       - authorization: Authorization of the user.
       - additionalInformation: Additional information of the user.
       - onSuccess: Execution block when user information is set.
       - onFailure: Execution block when user information is can not be set. This block takes an Int which represents the HTTP Status Code and a String describing what went wrong.
     */
    public static func setUserInformation(
        _ authorization: String,
        additionalInformation: [String: String]? = nil
    )  async -> ParleyActor.ConfigurationResult {
        await ParleyActor.shared.setUserInformation(authorization, additionalInformation: additionalInformation)
    }
    
    /**
     Clear user information.

     - Parameters:
       - onSuccess: Execution block when user information is cleared.
       - onFailure: Execution block when user information is can not be cleared. This block takes an Int which represents the HTTP Status Code and a String describing what went wrong.
     */
    public static func clearUserInformation() async -> ParleyActor.ConfigurationResult {
        await ParleyActor.shared.clearUserInformation()
    }
    
    /**
     Set a ``LocalizationManager`` to be able to provide more localizations than provided by the SDK.

     - Parameters:
       - localizationManager: Manager to return localization string from a key.
     */
    @MainActor
    public static func setLocalizationManager(_ localizationManager: LocalizationManager) {
        Self.shared.localizationManager = localizationManager
    }
    
    /**
     Configure Parley Messaging with clearing the cache

     The configure method allows setting a unique device identifier. If none is provided (default), Parley will default to
     a random UUID that will be stored in the user defaults. When providing a unique device
     ID to this configure method, it is not stored by Parley and only kept for the current instance
     of Parley. Client applications are responsible for storing it and providing Parley with the
     same ID. This gives client applications the flexibility to change the ID if required (for
     example when another user is logged-in to the app).

     - Parameters:
       - secret: Application secret of your Parley instance.
       - uniqueDeviceIdentifier: The device identifier to use for device registration.
       - networkConfig: The configuration for the network.
       - networkSession: The network session that will handle all http traffic.
       - onSuccess: Execution block when Parley is configured.
       - onFailure: Execution block when Parley failed to configure. This block takes an Int which represents the HTTP Status Code and a String describing what went wrong.
       - code: HTTP Status Code.
       - message: Description what went wrong.
     */
    public static func configure(
        _ secret: String,
        uniqueDeviceIdentifier: String? = nil,
        networkConfig: ParleyNetworkConfig,
        networkSession: ParleyNetworkSession
    ) async -> ParleyActor.ConfigurationResult {
        await ParleyActor.shared.configure(
            secret,
            uniqueDeviceIdentifier: uniqueDeviceIdentifier,
            networkConfig: networkConfig,
            networkSession: networkSession
        )
    }
    
    /**
     Resets Parley back to its initial state (clearing the user information). Useful when logging out a user for example. Ensures that no user and chat data is left in memory.

     Leaves the network, offline messaging and referrer settings as is, these can be altered via the corresponding methods.

     - Parameters:
       - onSuccess: Called when the device is correctly registered.
       - onFailure: Called when configuring of the device did result in a error.

     - Note: Requires calling the `configure()` method again to use Parley.
     */
    public static func reset() async -> ParleyActor.ConfigurationResult {
        await ParleyActor.shared.reset()
    }
    
    /**
     Resets all local user identifiers. Ensures that no user and chat data is left in memory.

     Leaves the network, offline messaging and referrer settings as is, these can be altered via the corresponding methods.

     - Parameters:
       - completion: Called when all data is cleared

     - Note: Requires calling the `configure()` method again to use Parley.
     */
    public func purgeLocalMemory() async {
        await ParleyActor.shared.purgeLocalMemory()
    }
    
    /**
     Send a message to Parley.

     - Note: Call after chat is configured.

     - Parameters:
       - message: The message to sent
       - silent: Indicates if the message needs to be sent silently. The message will not be shown to the user when `silent=true`.
     */
    public func send(_ message: String, silent: Bool = false) async {
        await ParleyActor.shared.send(message, silent: silent)
    }
    
    /**
     Set referrer.

     - Parameters:
       - referrer: Referrer
     */
    public func setReferrer(_ referrer: String) async {
        await ParleyActor.shared.setReferrer(referrer)
    }

    /**
     Always enable polling of messages even when the push permission is granted.

     - Parameters:
       - enabled: Boolean that indicates if `alwaysPolling` should be enabled.
     */
    public func setAlwaysPolling(_ enabled: Bool) async {
        await ParleyActor.shared.setAlwaysPolling(enabled)
    }
}

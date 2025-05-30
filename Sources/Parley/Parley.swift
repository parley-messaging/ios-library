import Foundation

public struct Parley: Sendable {
    
    public typealias ConfigurationError = ParleyActor.ConfigurationError
    
    public typealias State = ParleyActor.State
    
    private(set) var localizationManager: LocalizationManager
    
    static nonisolated(unsafe) private(set) var shared = Parley()
    
    init(localizationManager: LocalizationManager) {
        self.localizationManager = localizationManager
    }
    
    init() {
        self.init(localizationManager: ParleyLocalizationManager())
    }
    
    public struct RemoteMessageData: @unchecked Sendable {
        let userInfo: [AnyHashable: Any]
        
        public init(_ userInfo: [AnyHashable: Any]) {
            self.userInfo = userInfo
        }
    }
    
    // MARK: - Handle remote message
    
    /**
     Handle remote message.
     
     - Parameters:
      - userInfo: Remote message data.
      - completion: An optional closure called when processing completes. The closure receives a Boolean indicating whether the remote message was successfully accepted and processed. Executed on the main actor.
     */
    public static func handle(_ userInfo: [AnyHashable: Any], completion: (@Sendable (Bool) -> Void)? = nil) {
        let remoteMessage = RemoteMessageData(userInfo)
        Task {
            let result = await ParleyActor.shared.handle(remoteMessage)
            if let completion {
                await MainActor.run {
                    completion(result)
                }
            }
        }
    }
    
    /**
     Handle remote message.

     - Parameters:
       - remoteMessage: Remote message data.

     - Returns: `true` if Parley handled this payload, `false` otherwise.
     */
    @discardableResult
    public static func handle(_ remoteMessage: RemoteMessageData) async -> Bool {
        await ParleyActor.shared.handle(remoteMessage)
    }
    
    // MARK: - enableOfflineMessaging
    
    @available(
        *,
        deprecated,
        renamed: "enableOfflineMessaging(messageDataSource:keyValueDataSource:mediaDataSource:)",
        message: "Use enableOfflineMessaging(messageDataSource:keyValueDataSource:mediaDataSource:) instead"
    )
    public static func enableOfflineMessaging(
        messageDataSource: ParleyMessageDataSource,
        keyValueDataSource: ParleyKeyValueDataSource,
        imageDataSource: ParleyMediaDataSource,
        completion: (@Sendable () -> Void)? = nil
    ) {
        Task {
            await ParleyActor.shared.enableOfflineMessaging(
                messageDataSource: messageDataSource,
                keyValueDataSource: keyValueDataSource,
                imageDataSource: imageDataSource
            )
            if let completion {
                await MainActor.run(body: completion)
            }
        }
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
    
    // MARK: - enableOfflineMessaging
    
    /**
     Enable offline messaging.

     - Parameters:
       - messageDataSource: ParleyMessageDataSource instance
       - keyValueDataSource: ParleyKeyValueDataSource instance
       - mediaDataSource: ParleyMediaDataSource instance
       - completion: A closure called when the opperation completes, executed on the main actor.
     */
    public static func enableOfflineMessaging(
        messageDataSource: ParleyMessageDataSource,
        keyValueDataSource: ParleyKeyValueDataSource,
        mediaDataSource: ParleyMediaDataSource,
        completion: (@Sendable () -> Void)? = nil
    ) {
        Task {
            await ParleyActor.shared.enableOfflineMessaging(
                messageDataSource: messageDataSource,
                keyValueDataSource: keyValueDataSource,
                mediaDataSource: mediaDataSource
            )
            if let completion {
                await MainActor.run(body: completion)
            }
        }
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
    
    // MARK: - disableOfflineMessaging
    
    /**
     Disable offline messaging.

     - Parameters:
       - completion: A closure called when the opperation completes, executed on the main actor.
     */
    public static func disableOfflineMessaging(completion: (@Sendable () -> Void)? = nil) {
        Task {
            await ParleyActor.shared.disableOfflineMessaging()
            if let completion {
                await MainActor.run(body: completion)
            }
        }
    }
    
    /**
     Disable offline messaging.

     - Note: The `clear()` method will be called on the current instance to prevent unused data on the device.
     */
    public static func disableOfflineMessaging() async {
        await ParleyActor.shared.disableOfflineMessaging()
    }
    
    // MARK: - setPushToken
    
    /**
     Set the push token of the user.

     - Note: Method must be called before `Parley.configure(_ secret: String)`.

     - Parameters:
        - pushToken: The push token
        - pushType: The push type (default `fcm`)
        - onSuccess: Execution block when Firebase Cloud Messaging token is updated. Executed on the main actor.
        - onFailure: Execution block when Firebase Cloud Messaging token can not updated. This block takes an Int which represents the HTTP Status Code and a String describing what went wrong. Executed on the main actor.
     */
    public static func setPushToken(
        _ pushToken: String,
        pushType: Device.PushType = .fcm,
        onSuccess: (@Sendable () -> Void)? = nil,
        onFailure: (@Sendable (_ code: Int, _ message: String) -> Void)? = nil
    ) {
        Task {
            do {
                try await setPushToken(pushToken, pushType: pushType)
                if let onSuccess {
                    await MainActor.run(body: onSuccess)
                }
            } catch let error as ConfigurationError {
                guard let onFailure else { return }
                await MainActor.run {
                    onFailure(error.code, error.message)
                }
            }
        }
    }
    
    /**
      Set the push token of the user.

      - Note: Method must be called before `Parley.configure(_ secret: String)`.

      - Parameters:
        - pushToken: The push token
        - pushType: The push type (default `fcm`)
      - Throws: `ConfigurationError` containing the HTTP status code and a descriptive error message when the reset or device registration fails.
     */
    public static func setPushToken(
        _ pushToken: String,
        pushType: Device.PushType = .fcm
    ) async throws(ConfigurationError) {
        try await ParleyActor.shared.setPushToken(pushToken, pushType: pushType)
    }
    
    // MARK: - setPushEnabled

    /**
      Set whether push is enabled by the user.

      - Parameters:
        - enabled: Indication if application's push is enabled.
        - onSuccess: Execution block when pushEnabled is updated. Executed on the main actor.
        - onFailure: Execution block when pushEnabled can not updated. This block takes an Int which represents the HTTP Status Code and a String describing what went wrong. Executed on the main actor.
     */
    public static func setPushEnabled(
        _ enabled: Bool,
        onSuccess: (@Sendable () -> Void)? = nil,
        onFailure: (@Sendable (_ code: Int, _ message: String) -> Void)? = nil
    ) {
        Task {
            do {
                try await setPushEnabled(enabled)
                if let onSuccess {
                    await MainActor.run(body: onSuccess)
                }
            } catch let error as ConfigurationError {
                guard let onFailure else { return }
                await MainActor.run {
                    onFailure(error.code, error.message)
                }
            }
        }
    }
    
    /**
      Set whether push is enabled by the user.

      - Parameters:
        - enabled: Indication if application's push is enabled.
      - Throws: `ConfigurationError` containing the HTTP status code and a descriptive error message when the reset or device registration fails.
     */
    public static func setPushEnabled(_ enabled: Bool) async throws(ConfigurationError) {
        try await ParleyActor.shared.setPushEnabled(enabled)
    }
    
    // MARK: - setUserInformation
    
    
    /**
     Set user information to authorize the user.

     - Parameters:
       - authorization: Authorization of the user.
       - additionalInformation: Additional information of the user.
     - Throws: `ConfigurationError` containing the HTTP status code and a descriptive error message when the reset or device registration fails.
     */
    public static func setUserInformation(
        _ authorization: String,
        additionalInformation: [String: String]? = nil
    ) async throws(ConfigurationError) {
        try await ParleyActor.shared.setUserInformation(authorization, additionalInformation: additionalInformation)
    }
    
    /**
     Set user information to authorize the user.

     - Parameters:
       - authorization: Authorization of the user.
       - additionalInformation: Additional information of the user.
       - onSuccess: Execution block when Parley is configured. Executed on the main actor.
       - onFailure: Execution block when Parley failed to configure. This block takes an Int which represents the HTTP Status Code and a String describing what went wrong. Executed on the main actor.
     */
    public static func setUserInformation(
        _ authorization: String,
        additionalInformation: [String: String]? = nil,
        onSuccess: (@Sendable () -> Void)? = nil,
        onFailure: (@Sendable (_ code: Int, _ message: String) -> Void)? = nil
    ) {
        Task {
            do {
                try await setUserInformation(authorization, additionalInformation: additionalInformation)
            } catch let error as ConfigurationError {
                guard let onFailure else { return }
                await MainActor.run {
                    onFailure(error.code, error.message)
                }
            }
        }
    }
    
    // MARK: - clearUserInformation

    /**
     Clear user information.

     - Parameters:
       - onSuccess: Execution block when user information is cleared. Executed on the main actor.
       - onFailure: Execution block when user information is can not be cleared. This block takes an Int which represents the HTTP Status Code and a String describing what went wrong. Executed on the main actor.
     */
    public static func clearUserInformation(
        onSuccess: (@Sendable () -> Void)? = nil,
        onFailure: (@Sendable (_ code: Int, _ message: String) -> Void)? = nil
    ) {
        Task {
            do {
                try await clearUserInformation()
                if let onSuccess {
                    await MainActor.run(body: onSuccess)
                }
            } catch let error as ConfigurationError {
                guard let onFailure else { return }
                await MainActor.run {
                    onFailure(error.code, error.message)
                }
            }
        }
    }
    
    /**
     Clear user information.
     
     - Throws: `ConfigurationError` containing the HTTP status code and a descriptive error message when the reset or device registration fails.
     */
    public static func clearUserInformation() async throws(ConfigurationError) {
        try await ParleyActor.shared.clearUserInformation()
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
    
    // MARK: - Configure
      
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
         - onSuccess: Execution block when Parley is configured. Executed on the main actor.
         - onFailure: Execution block when Parley failed to configure. This block takes an Int which represents the HTTP Status Code and a String describing what went wrong. Executed on the main actor.
       */
      public static func configure(
          _ secret: String,
          uniqueDeviceIdentifier: String? = nil,
          networkConfig: ParleyNetworkConfig,
          networkSession: ParleyNetworkSession,
          onSuccess: (@Sendable () -> Void)? = nil,
          onFailure: (@Sendable (_ code: Int, _ message: String) -> Void)? = nil
      ) {
          Task {
              do {
                  try await Self.configure(
                    secret,
                    uniqueDeviceIdentifier: uniqueDeviceIdentifier,
                    networkConfig: networkConfig,
                    networkSession: networkSession
                  )
                  if let onSuccess {
                      await MainActor.run(body: onSuccess)
                  }
              } catch let error as ConfigurationError {
                  guard let onFailure else { return }
                  await MainActor.run {
                      onFailure(error.code, error.message)
                  }
              }
          }
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
     - Throws: `ConfigurationError` containing the HTTP status code and a descriptive error message when the reset or device registration fails.
     */
    public static func configure(
        _ secret: String,
        uniqueDeviceIdentifier: String? = nil,
        networkConfig: ParleyNetworkConfig,
        networkSession: ParleyNetworkSession
    ) async throws(ConfigurationError) {
        try await ParleyActor.shared.configure(
            secret,
            uniqueDeviceIdentifier: uniqueDeviceIdentifier,
            networkConfig: networkConfig,
            networkSession: networkSession
        )
    }
    
    // MARK: - Reset

    /**
     Resets Parley back to its initial state (clearing the user information). Useful when logging out a user for example. Ensures that no user and chat data is left in memory.

     Leaves the network, offline messaging and referrer settings as is, these can be altered via the corresponding methods.

     - Parameters:
       - onSuccess: Called when the device is correctly registered. Executed on the main actor.
       - onFailure: Called when configuring of the device did result in a error. Executed on the main actor.

     - Note: Requires calling the `configure()` method again to use Parley.
     */
    public static func reset(
        onSuccess: (@Sendable () -> Void)? = nil,
        onFailure: (@Sendable (_ code: Int, _ message: String) -> Void)? = nil
    ) {
        Task {
            do {
                try await reset()
                if let onSuccess {
                    await MainActor.run(body: onSuccess)
                }
            } catch let error as ConfigurationError {
                guard let onFailure else { return }
                await MainActor.run {
                    onFailure(error.code, error.message)
                }
            }
        }
    }
    
    /**
     Resets Parley back to its initial state (clearing the user information) and registers the device. Useful when logging out a user for example. Ensures that no user and chat data is left in memory.

     Leaves the network, offline messaging and referrer settings as is, these can be altered via the corresponding methods.
     
     - Throws: `ConfigurationError` containing the HTTP status code and a descriptive error message when the reset or device registration fails.

     - Note: Requires calling the `configure()` method again to use Parley.
     */
    public static func reset() async throws(ConfigurationError) {
        try await ParleyActor.shared.reset()
    }
    
    // MARK: - purgeLocalMemory
    
    /**
     Resets all local user identifiers. Ensures that no user and chat data is left in memory.

     Leaves the network, offline messaging and referrer settings as is, these can be altered via the corresponding methods.

     - Parameters:
       - completion: Called when all data is cleared. Executed on the main actor.

     - Note: Requires calling the `configure()` method again to use Parley.
     */
    public func purgeLocalMemory(completion: (@Sendable () -> Void)? = nil) {
        Task {
            await ParleyActor.shared.purgeLocalMemory()
            if let completion {
                await MainActor.run(body: completion)
            }
        }
    }
    
    /**
     Resets all local user identifiers. Ensures that no user and chat data is left in memory.

     Leaves the network, offline messaging and referrer settings as is, these can be altered via the corresponding methods.

     - Note: Requires calling the `configure()` method again to use Parley.
     */
    public func purgeLocalMemory() async {
        await ParleyActor.shared.purgeLocalMemory()
    }
    
    // MARK: - send
    
    /**
     Send a message to Parley.

     - Note: Call after chat is configured.

     - Parameters:
       - message: The message to sent
       - silent: Indicates if the message needs to be sent silently. The message will not be shown to the user when `silent=true`.
       - completion: A closure that will be called after the message is being qeued to send. Executed on the main actor.
     */
    public func send(_ message: String, silent: Bool = false, completion: (@Sendable () -> Void)? = nil) {
        Task {
            await ParleyActor.shared.send(message, silent: silent)
            completion?()
        }
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
    
    // MARK: - setReferrer
    
    /**
     Set referrer.

     - Parameters:
       - referrer: Referrer
       - completion: A closure that will be called after the referrer is updated. Executed on the main actor.
     */
    public func setReferrer(_ referrer: String, completion: (@Sendable () -> Void)? = nil) {
        Task {
            await ParleyActor.shared.setReferrer(referrer)
            if let completion {
                await MainActor.run(body: completion)
            }
        }
    }
    
    /**
     Set referrer.

     - Parameters:
       - referrer: Referrer
     */
    public func setReferrer(_ referrer: String) async {
        await ParleyActor.shared.setReferrer(referrer)
    }

    // MARK: - setAlwaysPolling

    /**
     Always enable polling of messages even when the push permission is granted.

     - Parameters:
       - enabled: Boolean that indicates if `alwaysPolling` should be enabled.
       - completion: A closure that will be called after the polling setting is updated. Executed on the main actor.
     */
    public func setAlwaysPolling(enabled: Bool, _ completion: (@Sendable () -> Void)? = nil) {
        Task {
            await ParleyActor.shared.setAlwaysPolling(enabled)
            if let completion {
                await MainActor.run(body: completion)
            }
        }
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

import Foundation
import UIKit

protocol ParleyProtocol {
    var state: Parley.State { get }
    var alwaysPolling: Bool { get }
    var pushEnabled: Bool { get }

    var messagesManager: MessagesManagerProtocol? { get }
    var messageRepository: MessageRepositoryProtocol! { get }
    var mediaLoader: MediaLoaderProtocol! { get }

    var messagesInteractor: MessagesInteractor! { get }
    var messagesPresenter: MessagesPresenterProtocol! { get }
    var messagesStore: MessagesStore! { get }

    var delegate: ParleyDelegate? { get set }

    func isCachingEnabled() -> Bool
    func send(_ message: Message, isNewMessage: Bool) async
    func send(_ text: String, silent: Bool)
    func userStartTyping()
    func sendNewMessageWithMedia(_ media: MediaModel) async
}

public final class Parley: ParleyProtocol, ReachabilityProvider, NetworkMonitorDelegate {
    
    public typealias ConfigurationResult = Result<Void, ConfigurationError>
    typealias ConfigurationContinuation = CheckedContinuation<ConfigurationResult, Never>
    
    public struct ConfigurationError: Error {
        let code: Int
        let message: String
        
        init(error: Error) {
            let nsError = error as NSError
            code = nsError.code
            message = error.getFormattedMessage()
        }
        
        init(code: Int, message: String) {
            self.code = code
            self.message = message
        }
    }

    enum State {
        case unconfigured
        case configuring
        case configured
        case failed
    }

    static let shared = Parley()

    private(set) var state: State = .unconfigured {
        didSet {
            Task { @MainActor in // When calling configure from background thread, ensure main thread.
                delegate?.didChangeState(state)
            }
        }
    }

    private var isLoading = false

    private var networkMonitor: NetworkMonitorProtocol?
    var reachable = false {
        didSet {
            if reachable {
                delegate?.reachable()

                configureWhenNeeded()
            } else {
                delegate?.unreachable()
            }
        }
    }

    private(set) var secret: String?
    private(set) var uniqueDeviceIdentifier: String?

    private(set) var remote: ParleyRemote!
    private(set) var networkConfig: ParleyNetworkConfig!
    private(set) var deviceRepository: DeviceRepository!
    private(set) var eventRemoteService: EventRemoteService!
    private(set) var messageRepository: MessageRepositoryProtocol!
    private(set) var messagesManager: MessagesManagerProtocol?
    private(set) var mediaDataSource: ParleyMediaDataSource?
    private(set) var mediaRepository: MediaRepository!
    private(set) var mediaLoader: MediaLoaderProtocol!
    private(set) var messageDataSource: ParleyMessageDataSource?
    private(set) var keyValueDataSource: ParleyKeyValueDataSource?
    private(set) var localizationManager: LocalizationManager = ParleyLocalizationManager()

    private(set) var messagesInteractor: MessagesInteractor!
    private(set) var messagesPresenter: MessagesPresenterProtocol!
    private(set) var messagesStore: MessagesStore!

    private(set) var alwaysPolling = false
    private(set) var pushToken: String? = nil
    private(set) var pushType: Device.PushType? = nil
    private(set) var pushEnabled = false

    private(set) var referrer: String? = nil

    private(set) var userAuthorization: String?
    private(set) var userAdditionalInformation: [String: String]?

    weak var delegate: ParleyDelegate? {
        didSet {
            guard let delegate else { return }

            delegate.didChangeState(state)

            if reachable {
                delegate.reachable()
            } else {
                delegate.unreachable()
            }
        }
    }

    private(set) var agentIsTyping = false
    private var agentStopTypingTimer: Timer?

    private var userStartTypingDate: Date?
    private var userStopTypingTimer: Timer?

    private func initialize(networkConfig: ParleyNetworkConfig, networkSession: ParleyNetworkSession) {
        let remote = ParleyRemote(
            networkConfig: networkConfig,
            networkSession: networkSession,
            createSecret: { [weak self] in self?.secret },
            createUniqueDeviceIdentifier: { [weak self] in self?.uniqueDeviceIdentifier },
            createUserAuthorizationToken: { [weak self] in self?.userAuthorization }
        )
        self.networkConfig = networkConfig
        self.remote = remote
        deviceRepository = DeviceRepository(remote: remote)
        eventRemoteService = EventRemoteService(remote: remote)
        messagesManager = MessagesManager(
            messageDataSource: messageDataSource,
            keyValueDataSource: keyValueDataSource
        )

        let messageRemoteService = MessageRemoteService(remote: remote)
        messageRepository = MessageRepository(messageRemoteService: messageRemoteService)

        mediaRepository = MediaRepository(messageRemoteService: messageRemoteService)
        mediaRepository.dataSource = mediaDataSource
        mediaLoader = MediaLoader(mediaRepository: mediaRepository)

        messagesStore = MessagesStore()
        messagesPresenter = MessagesPresenter(store: messagesStore, display: nil)
        messagesInteractor = MessagesInteractor(
            presenter: messagesPresenter!,
            messagesManager: messagesManager!,
            messageCollection: ParleyChronologicalMessageCollection(calendar: .autoupdatingCurrent),
            messagesRepository: messageRepository!,
            reachabilityProvider: self
        )
        addObservers()
    }

    // MARK: Reachability

    private func setupReachability() {
        guard networkMonitor == nil else {
            networkMonitor?.start()
            return
        }
        networkMonitor = NetworkMonitor(delegate: self)
        networkMonitor?.start()
    }

    // MARK: NetworkMonitorDelegate
    func didUpdateConnection(isConnected: Bool) {
        reachable = isConnected
    }

    // MARK: Observers

    private func addObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    private func removeObservers() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    @objc
    private func willEnterForeground() {
        configureWhenNeeded()
    }

    @objc
    private func didEnterBackground() {
        networkMonitor?.stop()
    }

    // MARK: Configure

    private func configure(
        _ secret: String,
        uniqueDeviceIdentifier: String?,
        clearCache: Bool = false
    ) async -> ConfigurationResult {
        debugPrint("Parley.\(#function)")

        if clearCache {
            clearCacheWhenNeeded(secret: secret)
        }

        state = .unconfigured

        self.secret = secret
        self.uniqueDeviceIdentifier = uniqueDeviceIdentifier

        return await configure()
    }

    private func configureWhenNeeded() {
        guard state == .failed || state == .configured else {
            return
        }
        Task {
            await configure()
        }
    }

    private func configure() async -> ConfigurationResult {
        guard let messagesManager else { fatalError("Missing messages manager (Parley wasn't initialized).") }

        debugPrint("Parley.\(#function)")

        guard !isLoading else { return .failure(.init(code: -1, message: "Parley is loading")) }
        isLoading = true

        setupReachability()

        if isCachingEnabled() {
            updateSecretInDataSource()
            updateUserAuthorizationInDataSource()

            if state == .unconfigured {
                messagesManager.loadCachedData()

                state = .configured
            }
        } else {
            if state == .unconfigured || state == .failed {
                messagesManager.clear()

                state = .configuring
            }
        }
        
        do {
            _ = try await deviceRepository.register(device: makeDeviceData())
            
            if let lastMessage = messagesManager.lastSentMessage, let id = lastMessage.id {
                let messageCollection = try await messageRepository.findAfter(id)
                messagesManager.handle(messageCollection, .after)
            } else {
                let messageCollection = try await messageRepository.findAll()
                messagesManager.handle(messageCollection, .all)
            }
            
            send(messagesManager.pendingMessages)

            isLoading = false
            state = .configured
            return .success(())
        } catch {
            isLoading = false

            if isOfflineError(error) && isCachingEnabled() {
                return .success(())
            } else {
                state = .failed
                return .failure(ConfigurationError(error: error))
            }
        }
    }

    private func updateSecretInDataSource() {
        if let secret {
            keyValueDataSource?.set(secret, forKey: kParleyCacheKeySecret)
        } else {
            keyValueDataSource?.removeObject(forKey: kParleyCacheKeySecret)
        }
    }

    private func updateUserAuthorizationInDataSource() {
        if let userAuthorization {
            keyValueDataSource?.set(userAuthorization, forKey: kParleyCacheKeyUserAuthorization)
        } else {
            keyValueDataSource?.removeObject(forKey: kParleyCacheKeyUserAuthorization)
        }
    }

    private func reconfigure() async -> ConfigurationResult {
        clearChat()
        return await configure()
    }

    private func clearChat() {
        clearMessagesAndDataSources()
        state = .unconfigured
    }

    private func isOfflineError(_ error: Error) -> Bool {
        if let httpError = error as? ParleyHTTPErrorResponse {
            httpError.isOfflineError
        } else {
            isOfflineErrorCode((error as NSError).code)
        }
    }

    private func isOfflineErrorCode(_ code: Int) -> Bool {
        code == 13
    }

    // MARK: Caching

    func isCachingEnabled() -> Bool {
        messageDataSource != nil
    }

    private func clearCacheWhenNeeded(secret: String) {
        if let cachedSecret = keyValueDataSource?.string(forKey: kParleyCacheKeySecret), cachedSecret == secret {
            return
        } else if let currentSecret = self.secret, currentSecret == secret {
            return
        }

        clearMessagesAndDataSources()
    }

    private func clearMessagesAndDataSources() {
        messageDataSource?.clear()
        keyValueDataSource?.clear()
        Task {
            await messagesInteractor.clear()
        }
    }

    // MARK: Devices

    private func registerDevice() async -> ConfigurationResult {
        if state == .configuring || state == .configured {
            do {
                _ = try await deviceRepository.register(device: makeDeviceData())
                return .success(())
            } catch {
                return .failure(ConfigurationError(error: error))
            }
        } else {
            return .success(())
        }
    }

    private func makeDeviceData() -> Device {
        Device(
            pushToken: pushToken,
            pushType: pushType,
            pushEnabled: pushEnabled,
            userAdditionalInformation: userAdditionalInformation,
            referrer: referrer
        )
    }

    // MARK: Messages

    func send(_ messages: [Message]) {
        Task {
            for message in messages {
                await sendPendingMessage(message: message)
            }
        }
    }

    private func sendPendingMessage(message: Message) async {
        do {
            let updatedMessage = try await ensureMediaUploadedIfAvailable(message)
            await send(updatedMessage, isNewMessage: false)
        } catch {
            await failedToSend(message: message, error: error)
        }
    }

    private func ensureMediaUploadedIfAvailable(_ message: Message) async throws -> Message {
        guard let storedImage = getStoredMedia(for: message) else { return message }
        return try await upload(storedImage: storedImage, message: message)
    }

    private func getStoredMedia(for message: Message) -> ParleyStoredMedia? {
        guard let media = message.media else { return nil }
        return mediaRepository.getStoredMedia(for: media)
    }

    private func upload(storedImage: ParleyStoredMedia, message: Message) async throws -> Message {
        let remoteId = try await mediaRepository.upload(media: storedImage)
        message.media = MediaObject(id: remoteId, mimeType: storedImage.type.rawValue)
        messagesManager?.update(message)
        return message
    }

    func sendNewMessageWithMedia(_ media: MediaModel) async {
        let (message, storedImage) = await storeNewMessage(with: media)
        do {
            let updatedMessage = try await upload(storedImage: storedImage, message: message)
            await send(updatedMessage, isNewMessage: true)
        } catch {
            await failedToSend(message: message, error: error)
        }
    }

    private func storeNewMessage(with media: MediaModel) async -> (Message, ParleyStoredMedia) {
        let localImage = mediaRepository.store(media: media)
        let message = media.createMessage(status: .pending)
        message.media = MediaObject(id: localImage.id, mimeType: localImage.type.rawValue)
        await addNewMessage(message)
        return (message, localImage)
    }

    func send(_ text: String, silent: Bool = false) {
        let message = Message()
        message.message = text
        message.type = silent ? .systemMessageUser : .user
        message.status = .pending
        message.time = Date()

        Task {
            await send(message, isNewMessage: true)
        }
    }

    func send(_ message: Message, isNewMessage: Bool) async {
        message.referrer = referrer

        if isNewMessage {
            await addNewMessage(message)
        }

        guard reachable else { return }

        do {
            let uploadedMessage = try await messageRepository.store(message)
            await handleMessageSent(uploadedMessage)
        } catch {
            await failedToSend(message: message, error: error)
        }
    }

    private func handleMessageSent(_ message: Message) async {
        await messagesInteractor.handleMessageSent(message)
    }

    private func addNewMessage(_ message: Message) async {
        guard let messagesInteractor else { fatalError("Missing messages interactor (Parley wasn't initialized).") }
        userStopTypingTimer?.fire();

        await messagesInteractor.handleNewMessage(message)
    }

    private func failedToSend(message: Message, error: Error) async {
        if let parleyError = error as? ParleyErrorResponse {
            message.responseInfoType = parleyError.notifications.first?.message
        }

        if !isCachingEnabled() || !isOfflineError(error) {
            await messagesInteractor.handleMessageFailedToSend(message)
        }
    }

    // MARK: Remote messages

    private func handleMessage(_ userInfo: [String: Any]) async {
        guard let messagesInteractor else { fatalError("Missing messages interactor (Parley wasn't initialized).") }
        guard
            let id = userInfo["id"] as? Int,
            let typeId = userInfo["typeId"] as? Int else { return }

        let body = userInfo["body"] as? String

        let message = Message()
        message.id = id
        message.message = body
        message.type = Message.MessageType(rawValue: typeId)
        message.time = Date()

        if isLoading { return } // Ignore remote messages when configuring chat.

        var bestEffortMessage: Message = message
        if let id = message.id {
            if let storedMessage = try? await messageRepository.find(id) {
                bestEffortMessage = storedMessage
            }
            
            if let announcement = Message.Accessibility.getAccessibilityAnnouncement(for: bestEffortMessage) {
                await UIAccessibility.post(notification: .announcement, argument: announcement)
            }
            
            await messagesInteractor.handleAgentStoppedTyping()
            await messagesInteractor.handleNewMessage(bestEffortMessage)
        } else {
            await messagesInteractor.handleAgentStoppedTyping()
            await messagesInteractor.handleNewMessage(bestEffortMessage)
        }
    }

    private func handleEvent(_ event: String?) {
        guard let event, let typeEvent = UserTypingEvent(rawValue: event) else {
            return
        }
        switch typeEvent {
        case .startTyping:
            agentStartTyping()
        case .stopTyping:
            agentStopTyping()
        }
    }

    // MARK: isTyping

    func userStartTyping() {
        guard reachable else { return }

        if
            userStartTypingDate == nil || Date().timeIntervalSince1970 - userStartTypingDate!
                .timeIntervalSince1970 > kParleyEventStartTypingTriggerAfter
        {
            Task {
                try? await eventRemoteService.fire(.startTyping)
            }

            userStartTypingDate = Date()
        }

        userStopTypingTimer?.invalidate()
        userStopTypingTimer = Timer.scheduledTimer(
            withTimeInterval: kParleyEventStopTypingTriggerAfter,
            repeats: false
        ) { _ in
            if !self.reachable { return }

            Task {
                try? await self.eventRemoteService.fire(.stopTyping)
            }

            self.userStartTypingDate = nil
            self.userStopTypingTimer = nil
        }
    }

    private func agentStartTyping() {
        let agentReallyStartTyping = !agentIsTyping
        agentIsTyping = true

        agentStopTypingTimer?.invalidate()
        agentStopTypingTimer = Timer.scheduledTimer(
            withTimeInterval: kParleyEventStopTypingTriggerAfter,
            repeats: false,
            block: { _ in
                self.agentStopTyping()
            }
        )

        if agentReallyStartTyping {
            UIAccessibility.post(
                notification: .announcement,
                argument: ParleyLocalizationKey.voiceOverAnnouncementAgentTyping.localized()
            )
            Task {
                await messagesInteractor.handleAgentBeganTyping()
            }
        }
    }

    private func agentStopTyping() {
        guard agentIsTyping else { return }

        agentIsTyping = false

        agentStopTypingTimer?.invalidate()
        agentStopTypingTimer = nil

        Task {
            await messagesInteractor.handleAgentStoppedTyping()
        }
    }
}

extension Parley {

    /**
     Handle remote message.

     - Parameters:
       - userInfo: Remote message data.

     - Returns: `true` if Parley handled this payload, `false` otherwise.
     */
    public static func handle(_ userInfo: [AnyHashable: Any]) -> Bool {
        if shared.secret == nil {
            return false
        }

        guard
            let data = (userInfo["parley"] as? String)?.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
            let messageType = json["type"] as? String,
            let object = json["object"] as? [String: Any] else
        {
            return false
        }

        switch messageType {
        case MessageTypeEvent.message.rawValue:
            Task {
                await shared.handleMessage(object)
            }
        case MessageTypeEvent.event.rawValue:
            shared.handleEvent(object["name"] as? String)
        default:
            break
        }

        return true
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
    ) {
        enableOfflineMessaging(
            messageDataSource: messageDataSource,
            keyValueDataSource: keyValueDataSource,
            mediaDataSource: imageDataSource
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
    ) {
        shared.messageDataSource = messageDataSource
        shared.keyValueDataSource = keyValueDataSource
        shared.mediaDataSource = mediaDataSource

        shared.reachable ? shared.delegate?.reachable() : shared.delegate?.unreachable()
    }

    /**
     Disable offline messaging.

     - Note: The `clear()` method will be called on the current instance to prevent unused data on the device.
     */
    public static func disableOfflineMessaging() {
        shared.messageDataSource?.clear()
        shared.messageDataSource = nil
        shared.keyValueDataSource = nil
        shared.mediaDataSource?.clear()
        shared.mediaDataSource = nil
        shared.mediaRepository?.dataSource = nil

        shared.reachable ? shared.delegate?.reachable() : shared.delegate?.unreachable()
    }
    
    // MARK: - setUserInformation
    
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
        pushType: Device.PushType = .fcm,
        onSuccess: (() -> Void)? = nil,
        onFailure: ((_ code: Int, _ message: String) -> Void)? = nil
    ) {
        Task {
            let result = await setPushToken(pushToken, pushType: pushType)
            await MainActor.run {
                switch result {
                case .success:
                    onSuccess?()
                case .failure(let error):
                    onFailure?(error.code, error.message)
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
      - Returns: A `ConfigurationResult` indicating the outcome:
       - On success: returns `.success`.
       - On failure: returns `.failure` with a `ConfigurationError` containing the HTTP status code and a descriptive error message.
     */
    public static func setPushToken(
        _ pushToken: String,
        pushType: Device.PushType = .fcm
    ) async -> ConfigurationResult {
        if shared.pushToken == pushToken { return .success(()) }

        shared.pushToken = pushToken
        shared.pushType = pushType

        return await shared.registerDevice()
    }
    
    // MARK: - setPushEnabled

    /**
      Set whether push is enabled by the user.

      - Parameters:
        - enabled: Indication if application's push is enabled.
        - onSuccess: Execution block when pushEnabled is updated.
        - onFailure: Execution block when pushEnabled can not updated. This block takes an Int which represents the HTTP Status Code and a String describing what went wrong.
     */
    public static func setPushEnabled(
        _ enabled: Bool,
        onSuccess: (() -> Void)? = nil,
        onFailure: ((_ code: Int, _ message: String) -> Void)? = nil
    ) {
        Task {
            let result = await setPushEnabled(enabled)
            await MainActor.run {
                switch result {
                case .success:
                    onSuccess?()
                case .failure(let error):
                    onFailure?(error.code, error.message)
                }
            }
        }
    }
    
    /**
      Set whether push is enabled by the user.

      - Parameters:
        - enabled: Indication if application's push is enabled.
      - Returns: A `ConfigurationResult` indicating the outcome:
        - On success: returns `.success`.
        - On failure: returns `.failure` with a `ConfigurationError` containing the HTTP status code and a descriptive error message.
     */
    public static func setPushEnabled(_ enabled: Bool) async -> ConfigurationResult {
        guard shared.pushEnabled != enabled else { return .success(()) }

        shared.pushEnabled = enabled

        shared.delegate?.didChangePushEnabled(enabled)

        return await shared.registerDevice()
    }
    
    // MARK: - setUserInformation

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
        additionalInformation: [String: String]? = nil,
        onSuccess: (() -> Void)? = nil,
        onFailure: ((_ code: Int, _ message: String) -> Void)? = nil
    ) {
        Task {
            let result = await setUserInformation(authorization, additionalInformation: additionalInformation)
            await MainActor.run {
                switch result {
                case .success:
                    onSuccess?()
                case .failure(let error):
                    onFailure?(error.code, error.message)
                }
            }
        }
    }
    
    /**
     Set user information to authorize the user.

     - Parameters:
       - authorization: Authorization of the user.
       - additionalInformation: Additional information of the user.
     - Returns: A `ConfigurationResult` indicating the outcome:
        - On success: returns `.success`.
        - On failure: returns `.failure` with a `ConfigurationError` containing the HTTP status code and a descriptive error message.
     */
    public static func setUserInformation(
        _ authorization: String,
        additionalInformation: [String: String]? = nil
    )  async -> ConfigurationResult {
        shared.userAuthorization = authorization
        shared.userAdditionalInformation = additionalInformation

        if shared.state == .configured {
            return await shared.reconfigure()
        } else {
            return .success(())
        }
    }

    // MARK: - clearUserInformation

    /**
     Clear user information.

     - Parameters:
       - onSuccess: Execution block when user information is cleared.
       - onFailure: Execution block when user information is can not be cleared. This block takes an Int which represents the HTTP Status Code and a String describing what went wrong.
     */
    @available(*, deprecated, message: "Use the async version instead.")
    public static func clearUserInformation(
        onSuccess: (() -> Void)? = nil,
        onFailure: ((_ code: Int, _ message: String) -> Void)? = nil
    ) {
        Task {
            let result = await clearUserInformation()
            await MainActor.run {
                switch result {
                case .success:
                    onSuccess?()
                case .failure(let error):
                    onFailure?(error.code, error.message)
                }
            }
        }
    }
        
    /**
     Clear user information.

     - Returns: A `ConfigurationResult` indicating the outcome:
        - On success: returns `.success`.
        - On failure: returns `.failure` with a `ConfigurationError` containing the HTTP status code and a descriptive error message.
     */
    public static func clearUserInformation() async -> ConfigurationResult {
        shared.userAuthorization = nil
        shared.userAdditionalInformation = nil

        if shared.state == .configured {
            return await shared.reconfigure()
        } else {
            return .success(())
        }
    }

    /**
     Set a ``LocalizationManager`` to be able to provide more localizations than provided by the SDK.

     - Parameters:
       - localizationManager: Manager to return localization string from a key.
     */
    public static func setLocalizationManager(_ localizationManager: LocalizationManager) {
        shared.localizationManager = localizationManager
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
       - onSuccess: Execution block when Parley is configured.
       - onFailure: Execution block when Parley failed to configure. This block takes an Int which represents the HTTP Status Code and a String describing what went wrong.
       - code: HTTP Status Code.
       - message: Description what went wrong.
     */
    @available(*, deprecated, message: "Use the async version instead.")
    public static func configure(
        _ secret: String,
        uniqueDeviceIdentifier: String? = nil,
        networkConfig: ParleyNetworkConfig,
        networkSession: ParleyNetworkSession,
        onSuccess: (() -> Void)? = nil,
        onFailure: ((_ code: Int, _ message: String) -> Void)? = nil
    ) {
        Task {
            let result = await Self.configure(
                secret,
                uniqueDeviceIdentifier: uniqueDeviceIdentifier,
                networkConfig: networkConfig,
                networkSession: networkSession
            )
            await MainActor.run {
                switch result {
                case .success:
                    onSuccess?()
                case .failure(let error):
                    onFailure?(error.code, error.message)
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
       - code: HTTP Status Code.
       - message: Description what went wrong.
     - Returns: A `ConfigurationResult` indicating the outcome:
        - On success: returns `.success`.
        - On failure: returns `.failure` with a `ConfigurationError` containing the HTTP status code and a descriptive error message.
     */
    public static func configure(
        _ secret: String,
        uniqueDeviceIdentifier: String? = nil,
        networkConfig: ParleyNetworkConfig,
        networkSession: ParleyNetworkSession
    ) async -> ConfigurationResult {
        shared.initialize(networkConfig: networkConfig, networkSession: networkSession)
        
        return await shared.configure(
            secret,
            uniqueDeviceIdentifier: uniqueDeviceIdentifier,
            clearCache: true
        )
    }
    
    // MARK: - Reset

    /**
     Resets Parley back to its initial state (clearing the user information). Useful when logging out a user for example. Ensures that no user and chat data is left in memory.

     Leaves the network, offline messaging and referrer settings as is, these can be altered via the corresponding methods.

     - Parameters:
       - onSuccess: Called when the device is correctly registered.
       - onFailure: Called when configuring of the device did result in a error.

     - Note: Requires calling the `configure()` method again to use Parley.
     */
    @available(*, deprecated, message: "Use the async version instead.")
    public static func reset(
        onSuccess: (() -> Void)? = nil,
        onFailure: ((_ code: Int, _ message: String) -> Void)? = nil
    ) {
        Task {
            let result = await reset()
            await MainActor.run {
                switch result {
                case .success:
                    onSuccess?()
                case .failure(let error):
                    onFailure?(error.code, error.message)
                }
            }
        }
    }
    
    /**
     Resets Parley back to its initial state (clearing the user information). Useful when logging out a user for example. Ensures that no user and chat data is left in memory.

     Leaves the network, offline messaging and referrer settings as is, these can be altered via the corresponding methods.

     - Parameters:
       - onSuccess: Called when the device is correctly registered.
       - onFailure: Called when configuring of the device did result in a error.

     - Note: Requires calling the `configure()` method again to use Parley.
     */
    public static func reset() async -> ConfigurationResult {
        await shared.mediaLoader?.reset()
        
        shared.userAuthorization = nil
        shared.userAdditionalInformation = nil
        shared.mediaRepository?.reset()
        shared.removeObservers()
        
        let result = await shared.registerDevice()
        
        switch result {
        case .success:
            shared.secret = nil
            shared.state = .unconfigured
        case .failure:
            shared.secret = nil
            shared.state = .unconfigured
        }
        
        await MainActor.run {
            Self.shared.clearChat()
        }
        
        return result
    }
    
    // MARK: - purgeLocalMemory

    /**
     Resets all local user identifiers. Ensures that no user and chat data is left in memory.

     Leaves the network, offline messaging and referrer settings as is, these can be altered via the corresponding methods.

     - Parameters:
       - completion: Called when all data is cleared

     - Note: Requires calling the `configure()` method again to use Parley.
     */
    @available(*, deprecated, message: "Use the async version instead.")
    public static func purgeLocalMemory(completion: (() -> Void)? = nil) {
        Task {
            await purgeLocalMemory()
            await MainActor.run {
                completion?()
            }
        }
    }

    /**
     Resets all local user identifiers. Ensures that no user and chat data is left in memory.

     Leaves the network, offline messaging and referrer settings as is, these can be altered via the corresponding methods.

     - Parameters:
       - completion: Called when all data is cleared

     - Note: Requires calling the `configure()` method again to use Parley.
     */
    public static func purgeLocalMemory() async {
        await shared.mediaLoader?.reset()
        shared.userAuthorization = nil
        shared.userAdditionalInformation = nil
        shared.mediaRepository?.reset()
        shared.secret = nil
        shared.removeObservers()
        await MainActor.run {
            shared.clearChat()
            shared.state = .unconfigured
        }
    }

    /**
     Send a message to Parley.

     - Note: Call after chat is configured.

     - Parameters:
       - message: The message to sent
       - silent: Indicates if the message needs to be sent silently. The message will not be shown to the user when `silent=true`.
     */
    public static func send(_ message: String, silent: Bool = false) {
        shared.send(message, silent: silent)
    }

    /**
     Set referrer.

     - Parameters:
       - referrer: Referrer
     */
    public static func setReferrer(_ referrer: String) {
        shared.referrer = referrer
    }

    /**
     Always enable polling of messages even when the push permission is granted.

     - Parameters:
       - enabled: Boolean that indicates if `alwaysPolling` should be enabled.
     */
    public static func setAlwaysPolling(_ enabled: Bool) {
        shared.alwaysPolling = enabled
    }
}

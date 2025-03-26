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

    enum State {
        case unconfigured
        case configuring
        case configured
        case failed
    }

    static let shared = Parley()

    private(set) var state: State = .unconfigured {
        didSet {
            delegate?.didChangeState(state)
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
        onSuccess: (() -> Void)? = nil,
        onFailure: ((_ code: Int, _ message: String) -> Void)? = nil,
        clearCache: Bool = false
    ) {
        debugPrint("Parley.\(#function)")

        if clearCache {
            clearCacheWhenNeeded(secret: secret)
        }

        state = .unconfigured

        self.secret = secret
        self.uniqueDeviceIdentifier = uniqueDeviceIdentifier

        configure(onSuccess: onSuccess, onFailure: onFailure)
    }

    private func configureWhenNeeded() {
        guard state == .failed || state == .configured else {
            return
        }

        configure()
    }

    private func configure(
        onSuccess: (() -> Void)? = nil,
        onFailure: ((_ code: Int, _ message: String) -> Void)? = nil
    ) {
        guard let messagesManager else { fatalError("Missing messages manager (Parley wasn't initialized).") }

        debugPrint("Parley.\(#function)")

        guard !isLoading else { return }
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

        let onFailure: (_ error: Error) -> Void = { [weak self] error in
            guard let self else { return }
            isLoading = false

            if isOfflineError(error) && isCachingEnabled() {
                onSuccess?()
            } else {
                state = .failed

                onFailure?((error as NSError).code, error.getFormattedMessage())
            }
        }

        deviceRepository.register(
            device: makeDeviceData(),
            onSuccess: { [weak self] _ in
                guard let self else { return }
                let onSecondSuccess: () -> Void = { [weak self] in
                    guard let self else { return }

                    send(messagesManager.pendingMessages)

                    isLoading = false
                    state = .configured

                    onSuccess?()
                }

                if let lastMessage = messagesManager.lastSentMessage, let id = lastMessage.id {
                    messageRepository.findAfter(id, onSuccess: { [weak self] messageCollection in
                        self?.messagesManager?.handle(messageCollection, .after)

                        onSecondSuccess()
                    }, onFailure: onFailure)
                } else {
                    messageRepository.findAll(onSuccess: { [weak self] messageCollection in
                        self?.messagesManager?.handle(messageCollection, .all)

                        onSecondSuccess()
                    }, onFailure: onFailure)
                }
            },
            onFailure: onFailure
        )
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

    private func reconfigure(
        onSuccess: (() -> Void)? = nil,
        onFailure: ((_ code: Int, _ message: String) -> Void)? = nil
    ) {
        clearChat()
        configure(onSuccess: onSuccess, onFailure: onFailure)
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

    private func registerDevice(
        onSuccess: (() -> Void)? = nil,
        onFailure: ((_ code: Int, _ message: String) -> Void)? = nil
    ) {
        if state == .configuring || state == .configured {
            deviceRepository?.register(device: makeDeviceData(), onSuccess: { _ in
                onSuccess?()
            }, onFailure: { error in
                onFailure?((error as NSError).code, error.getFormattedMessage())
            })
        } else {
            onSuccess?()
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

    private func handleMessage(_ userInfo: [String: Any]) {
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

        if let id = message.id {
            messageRepository.find(id, onSuccess: { storedMessage in
                if let announcement = Message.Accessibility.getAccessibilityAnnouncement(for: storedMessage) {
                    UIAccessibility.post(notification: .announcement, argument: announcement)
                }
                Task {
                    await messagesInteractor.handleAgentStoppedTyping()
                    await messagesInteractor.handleNewMessage(storedMessage)
                }
            }) { _ in
                if let announcement = Message.Accessibility.getAccessibilityAnnouncement(for: message) {
                    UIAccessibility.post(notification: .announcement, argument: announcement)
                }
                Task {
                    await messagesInteractor.handleAgentStoppedTyping()
                    await messagesInteractor.handleNewMessage(message)
                }
            }
        } else {
            Task {
                await messagesInteractor.handleAgentStoppedTyping()
                await messagesInteractor.handleNewMessage(message)
            }
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
            eventRemoteService.fire(UserTypingEvent.startTyping, onSuccess: { }, onFailure: { _ in })

            userStartTypingDate = Date()
        }

        userStopTypingTimer?.invalidate()
        userStopTypingTimer = Timer.scheduledTimer(
            withTimeInterval: kParleyEventStopTypingTriggerAfter,
            repeats: false
        ) { _ in
            if !self.reachable { return }

            self.eventRemoteService.fire(UserTypingEvent.stopTyping, onSuccess: { }, onFailure: { _ in })

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
            shared.handleMessage(object)
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
        if shared.pushToken == pushToken { return }

        shared.pushToken = pushToken
        shared.pushType = pushType

        shared.registerDevice(onSuccess: onSuccess, onFailure: onFailure)
    }

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
        guard shared.pushEnabled != enabled else { return }

        shared.pushEnabled = enabled

        shared.delegate?.didChangePushEnabled(enabled)

        shared.registerDevice(onSuccess: onSuccess, onFailure: onFailure)
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
        additionalInformation: [String: String]? = nil,
        onSuccess: (() -> Void)? = nil,
        onFailure: ((_ code: Int, _ message: String) -> Void)? = nil
    ) {
        shared.userAuthorization = authorization
        shared.userAdditionalInformation = additionalInformation

        if shared.state == .configured {
            shared.reconfigure(onSuccess: onSuccess, onFailure: onFailure)
        } else {
            onSuccess?()
        }
    }

    /**
     Clear user information.

     - Parameters:
       - onSuccess: Execution block when user information is cleared.
       - onFailure: Execution block when user information is can not be cleared. This block takes an Int which represents the HTTP Status Code and a String describing what went wrong.
     */
    public static func clearUserInformation(
        onSuccess: (() -> Void)? = nil,
        onFailure: ((_ code: Int, _ message: String) -> Void)? = nil
    ) {
        shared.userAuthorization = nil
        shared.userAdditionalInformation = nil

        if shared.state == .configured {
            shared.reconfigure(onSuccess: onSuccess, onFailure: onFailure)
        } else {
            onSuccess?()
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
        networkSession: ParleyNetworkSession,
        onSuccess: (() -> Void)? = nil,
        onFailure: ((_ code: Int, _ message: String) -> Void)? = nil
    ) {
        shared.initialize(networkConfig: networkConfig, networkSession: networkSession)

        shared.configure(
            secret,
            uniqueDeviceIdentifier: uniqueDeviceIdentifier,
            onSuccess: onSuccess,
            onFailure: onFailure,
            clearCache: true
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
    public static func reset(
        onSuccess: (() -> Void)? = nil,
        onFailure: ((_ code: Int, _ message: String) -> Void)? = nil
    ) {
        Task {
            await shared.mediaLoader?.reset()
        }

        shared.userAuthorization = nil
        shared.userAdditionalInformation = nil
        shared.mediaRepository?.reset()
        shared.removeObservers()

        shared.registerDevice(onSuccess: {
            shared.secret = nil
            shared.state = .unconfigured
            onSuccess?()
        }, onFailure: { code, message in
            shared.secret = nil
            shared.state = .unconfigured
            onFailure?(code, message)
        })

        DispatchQueue.main.async {
            Self.shared.clearChat()
        }
    }

    /**
     Resets all local user identifiers. Ensures that no user and chat data is left in memory.

     Leaves the network, offline messaging and referrer settings as is, these can be altered via the corresponding methods.

     - Parameters:
       - completion: Called when all data is cleared

     - Note: Requires calling the `configure()` method again to use Parley.
     */
    public static func purgeLocalMemory(completion: (() -> Void)? = nil) {
        Task {
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

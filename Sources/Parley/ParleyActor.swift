import Foundation
import UIKit
import Combine

protocol ParleyProtocol: Actor, AnyObject {
    var state: Parley.State { get }
    var alwaysPolling: Bool { get }
    var pushEnabled: Bool { get }

    var messagesManager: MessagesManagerProtocol? { get }
    var messageRepository: MessageRepository! { get }
    var mediaLoader: MediaLoaderProtocol! { get }
    
    var messagesInteractor: MessagesInteractor! { get }
    var messagesStore: MessagesStore! { get }

    @MainActor var delegate: ParleyDelegate? { get }
    @MainActor func set(delegate: ParleyDelegate?) async
    
    func setDisplayToAttach(_ display: ParleyMessagesDisplay) async

    func isCachingEnabled() -> Bool
    func send(_ message: inout Message, isNewMessage: Bool) async
    func send(_ text: String, silent: Bool) async
    func userStartTyping() async
    func sendNewMessageWithMedia(_ media: MediaModel) async
}

public actor ParleyActor: ParleyProtocol, ReachabilityProvider {
    
    public struct ConfigurationError: Error {
        public let code: Int
        public let message: String
        
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
    
    public enum State: Sendable {
        case unconfigured
        case configuring
        case configured
        case failed
    }

    static let shared = ParleyActor()

    private(set) var state: State = .unconfigured

    private var isLoading = false

    private(set) var secret: String?
    private(set) var uniqueDeviceIdentifier: String?

    private(set) var remote: ParleyRemote!
    private(set) var networkConfig: ParleyNetworkConfig!
    private(set) var deviceRepository: DeviceRepository!
    private(set) var eventRemoteService: EventRemoteService!
    private(set) var messageRepository: MessageRepository!
    private(set) var messagesManager: MessagesManagerProtocol?
    private(set) var mediaDataSource: ParleyMediaDataSource?
    private(set) var mediaRepository: MediaRepository!
    private(set) var mediaLoader: MediaLoaderProtocol!
    private(set) var messageDataSource: ParleyMessageDataSource?
    private(set) var keyValueDataSource: ParleyKeyValueDataSource?
    private(set) var localizationManager: LocalizationManager = ParleyLocalizationManager()
    
    private(set) var messagesInteractor: MessagesInteractor!
    private(set) var messagesStore: MessagesStore!
    private(set) var reachibilityService: ReachabilityService?

    private(set) var alwaysPolling = false
    private(set) var pushToken: String? = nil
    private(set) var pushType: Device.PushType? = nil
    private(set) var pushEnabled = false

    private(set) var referrer: String? = nil

    private(set) var userAuthorization: String?
    private(set) var userAdditionalInformation: [String: String]?
    private var reachibilityWatcher: AnyCancellable?
    
    private weak var displayToAttach: ParleyMessagesDisplay?
    
    func setDisplayToAttach(_ display: ParleyMessagesDisplay) async {
        displayToAttach = display
    }

    @MainActor
    private(set) weak var delegate: ParleyDelegate?
    
    @MainActor
    func set(delegate: ParleyDelegate?) async {
        self.delegate = delegate
        
        await delegate?.didChangeState(state)
        
        if let reachibilityService = await self.reachibilityService {
            if await reachibilityService.reachable {
                await delegate?.reachable(pushEnabled: pushEnabled)
            } else {
                await delegate?.unreachable(isCachingEnabled: isCachingEnabled())
            }
        }
    }

    private(set) var agentIsTyping = false
    private var agentStopTypingTimer: Timer?

    private var userStartTypingDate: Date?
    private var userStopTypingTimer: Timer?
    
    private var networkMonitor: NetworkMonitorProtocol?
    var reachable: Bool {
        get async {
            await reachibilityService?.reachable == true
        }
    }

    private func initialize(networkConfig: ParleyNetworkConfig, networkSession: ParleyNetworkSession) async {
        initializeParleyRemote(networkConfig: networkConfig, networkSession: networkSession)
        deviceRepository = DeviceRepository(remote: remote)
        eventRemoteService = EventRemoteService(remote: remote)
        messagesManager = MessagesManager(
            messageDataSource: messageDataSource,
            keyValueDataSource: keyValueDataSource
        )

        let messageRemoteService = MessageRemoteService(remote: remote)
        messageRepository = messageRemoteService

        mediaRepository = MediaRepository(messageRemoteService: messageRemoteService)
        await mediaRepository.set(dataSource: mediaDataSource)
        mediaLoader = MediaLoader(mediaRepository: mediaRepository)
        
        messagesStore = await MessagesStore()
        let messageReadWorker = await MessageReadWorker(messageRepository: messageRepository)
        
        let currentPresenter = await messagesInteractor?.presenter
        messagesInteractor = await MessagesInteractor(
            messagesManager: messagesManager!,
            messageCollection: ParleyChronologicalMessageCollection(calendar: .autoupdatingCurrent),
            messagesRepository: messageRepository!,
            reachabilityProvider: self,
            messageReadWorker: messageReadWorker
        )
        if let currentPresenter {
            await messagesInteractor.set(presenter: currentPresenter)
        }
        await messageReadWorker.set(delegate: messagesInteractor!)
        reachibilityService = try? ReachabilityService()
        addObservers()
    }
    
    private func initializeParleyRemote(networkConfig: ParleyNetworkConfig, networkSession: ParleyNetworkSession) {
        let remote = ParleyRemote(
            networkConfig: networkConfig,
            networkSession: networkSession,
            createSecret: { [weak self] in await self?.secret },
            createUniqueDeviceIdentifier: { [weak self] in await self?.uniqueDeviceIdentifier },
            createUserAuthorizationToken: { [weak self] in await self?.userAuthorization }
        )
        self.networkConfig = networkConfig
        self.remote = remote
    }

    // MARK: Reachability

    private func setupReachability() {
        reachibilityService = try? ReachabilityService()
        Task {
            await reachibilityService?.startNotifier()
        }
        reachibilityWatcher = reachibilityService?.reachabilityPublisher().sink(receiveValue: { [weak self] isReachable in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if isReachable {
                    await self.delegate?.reachable(pushEnabled: self.pushEnabled)
                    
                    await self.configureWhenNeeded()
                } else {
                    await self.delegate?.unreachable(isCachingEnabled: self.isCachingEnabled())
                }
            }
        })
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
    @MainActor
    private func willEnterForeground() {
        Task {
            await configureWhenNeeded()
        }
    }

    @objc
    @MainActor
    private func didEnterBackground() {
        Task {
            await reachibilityService?.stopNotifier()
        }
    }
    
    public func setup(
        secret: String,
        uniqueDeviceIdentifier: String?,
        networkSession: ParleyNetworkSession,
        networkConfig: ParleyNetworkConfig? = nil,
    ) async {
        self.secret = secret
        self.uniqueDeviceIdentifier = uniqueDeviceIdentifier
        initializeParleyRemote(
            networkConfig: networkConfig ?? ParleyNetworkConfig(),
            networkSession: networkSession
        )
        deviceRepository = DeviceRepository(remote: remote)
    }

    // MARK: Configure

    private func configure(
        _ secret: String,
        uniqueDeviceIdentifier: String?,
        clearCache: Bool = false
    ) async throws(ConfigurationError) {
        debugPrint("Parley.\(#function)")

        if clearCache {
            await clearCacheWhenNeeded(secret: secret)
        }

        state = .unconfigured

        self.secret = secret
        self.uniqueDeviceIdentifier = uniqueDeviceIdentifier

        try await configure()
    }

    private func configureWhenNeeded() {
        guard state == .failed || state == .configured else { return }
        Task {
            try await configure()
        }
    }

    private func configure() async throws(ConfigurationError) {
        guard let messagesManager else { fatalError("Missing messages manager (Parley wasn't initialized).") }

        debugPrint("Parley.\(#function)")

        guard !isLoading else {
            throw ConfigurationError(code: -1, message: "Parley is loading")
        }
        isLoading = true

        setupReachability()

        if isCachingEnabled() {
            await updateSecretInDataSource()
            await updateUserAuthorizationInDataSource()

            if state == .unconfigured {
                await messagesManager.loadCachedData()

                await set(state: .configured)
            }
        } else {
            if state == .unconfigured || state == .failed {
                await messagesManager.clear()

                await set(state: .configuring)
            }
        }
        
        do {
            _ = try await deviceRepository.register(device: makeDeviceData())
            
            if let lastMessage = await messagesManager.lastSentMessage, let remoteId = lastMessage.remoteId {
                let messageCollection = try await messageRepository.findAfter(remoteId)
                await messagesManager.handle(messageCollection, .after)
            } else {
                let messageCollection = try await messageRepository.findAll()
                await messagesManager.handle(messageCollection, .all)
            }
            
            await send(messagesManager.pendingMessages)

            isLoading = false
            await set(state: .configured)
        } catch {
            isLoading = false

            if !isOfflineError(error) || !isCachingEnabled() {
                await set(state: .failed)
                throw ConfigurationError(error: error)
            }
        }
    }
    
    private func set(state: State) async {
        self.state = state
        await MainActor.run {
            delegate?.didChangeState(state)
        }
    }

    private func updateSecretInDataSource() async {
        if let secret {
            await keyValueDataSource?.set(secret, forKey: kParleyCacheKeySecret)
        } else {
            await keyValueDataSource?.removeObject(forKey: kParleyCacheKeySecret)
        }
    }

    private func updateUserAuthorizationInDataSource() async {
        if let userAuthorization = self.userAuthorization {
            await keyValueDataSource?.set(userAuthorization, forKey: kParleyCacheKeyUserAuthorization)
        } else {
            await keyValueDataSource?.removeObject(forKey: kParleyCacheKeyUserAuthorization)
        }
    }

    private func reconfigure() async throws(ConfigurationError) {
        await clearChat()
        try await configure()
    }

    private func clearChat() async {
        await clearMessagesAndDataSources()
        await set(state: .unconfigured)
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

    private func clearCacheWhenNeeded(secret: String) async {
        if let cachedSecret = await keyValueDataSource?.string(forKey: kParleyCacheKeySecret), cachedSecret == secret {
            return
        } else if let currentSecret = self.secret, currentSecret == secret {
            return
        }

        await clearMessagesAndDataSources()
    }

    private func clearMessagesAndDataSources() async {
        await messageDataSource?.clear()
        await keyValueDataSource?.clear()
        Task {
            await messagesInteractor?.clear()
        }
    }

    // MARK: Devices

    func registerDevice() async throws(ConfigurationError) {
        do {
            _ = try await deviceRepository?.register(device: makeDeviceData())
        } catch {
            throw ConfigurationError(error: error)
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
            for var message in messages {
                await sendPendingMessage(message: &message)
            }
        }
    }

    private func sendPendingMessage(message: inout Message) async {
        do {
            try await ensureMediaUploadedIfAvailable(&message)
            await send(&message, isNewMessage: false)
        } catch {
            await failedToSend(message: &message, error: error)
        }
    }

    private func ensureMediaUploadedIfAvailable(_ message: inout Message) async throws {
        guard let storedImage = await getStoredMedia(for: message) else { return }
        try await upload(storedImage: storedImage, message: &message)
    }

    private func getStoredMedia(for message: Message) async -> ParleyStoredMedia? {
        guard let media = message.media else { return nil }
        return await mediaRepository.getStoredMedia(for: media)
    }

    private func upload(storedImage: ParleyStoredMedia, message: inout Message) async throws {
        let remoteId = try await mediaRepository.upload(media: storedImage)
        message.media = MediaObject(id: remoteId, mimeType: storedImage.type.rawValue)
        await messagesManager?.update(message)
    }

    func sendNewMessageWithMedia(_ media: MediaModel) async {
        var (message, storedImage) = await storeNewMessage(with: media)
        do {
            try await upload(storedImage: storedImage, message: &message)
            await send(&message, isNewMessage: true)
        } catch {
            await failedToSend(message: &message, error: error)
        }
    }

    private func storeNewMessage(with media: MediaModel) async -> (Message, ParleyStoredMedia) {
        let localImage = await mediaRepository.store(media: media)
        let message = Message.newMediaMessage(
            MediaObject(id: localImage.id, mimeType: localImage.type.rawValue),
            status: .pending
        )
        await addNewMessage(message)
        return (message, localImage)
    }

    func send(_ text: String, silent: Bool = false) async {
        var message = Message.newTextMessage(
            text,
            type: silent ? .systemMessageUser : .user,
            sendStatus: .pending
        )
        
        await send(&message, isNewMessage: true)
    }

    func send(_ message: inout Message, isNewMessage: Bool) async {
        message.referrer = referrer

        if isNewMessage {
            await addNewMessage(message)
        }

        guard await reachibilityService?.reachable == true else { return }

        do {
            try await messageRepository.store(&message)
            await handleMessageSent(&message)
        } catch {
            await failedToSend(message: &message, error: error)
        }
    }

    private func handleMessageSent(_ message: inout Message) async {
        await messagesInteractor.handleMessageSent(&message)
    }

    private func addNewMessage(_ message: Message) async {
        guard let messagesInteractor else { fatalError("Missing messages interactor (Parley wasn't initialized).") }
        userStopTypingTimer?.fire();
        
        await messagesInteractor.handleNewMessage(message)
    }

    private func failedToSend(message: inout Message, error: Error) async {
        if let parleyError = error as? ParleyErrorResponse {
            message.responseInfoType = parleyError.notifications.first?.message
        }

        if !isCachingEnabled() || !isOfflineError(error) {
            await messagesInteractor.handleMessageFailedToSend(&message)
        }
    }
    
    func getUneenCount() async throws -> Int {
        if messageRepository == nil {
            messageRepository = MessageRemoteService(remote: remote)
        }
        return try await messageRepository.getUnseen()
    }

    // MARK: Remote messages

    private func handleMessage(_ userInfo: [String: Any]) async {
        guard let messagesInteractor else {
            print("Parley: Remote message not handled because Parley wasn't initialized yet.") ; return
        }
        
        guard
            let id = userInfo["id"] as? Int,
            let typeId = userInfo["typeId"] as? Int,
            let type = MessageResponse.MessageType(rawValue: typeId)?.toDomainModel()
        else { return }
        
        let body = userInfo["body"] as? String

        let message = Message.push(remoteId: id, message: body, type: type )
        
        if isLoading { return } // Ignore remote messages when configuring chat.

        var bestEffortMessage: Message = message
        if let storedMessage = try? await messageRepository.find(id) {
            bestEffortMessage = storedMessage
        }
        
        await MainActor.run {
            if let announcement = Message.Accessibility.getAccessibilityAnnouncement(for: bestEffortMessage) {
                UIAccessibility.post(notification: .announcement, argument: announcement)
            }
        }
        
        await messagesInteractor.handleAgentStoppedTyping()
        await messagesInteractor.handleNewMessage(bestEffortMessage)
    }

    private func handleEvent(_ event: String?) async {
        guard let event, let typeEvent = UserTypingEvent(rawValue: event) else {
            return
        }
        switch typeEvent {
        case .startTyping:
            await agentStartTyping()
        case .stopTyping:
            agentStopTyping()
        }
    }

    // MARK: isTyping

    func userStartTyping() async {
        guard await reachibilityService?.reachable == true else { return }

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
        ) { [weak self] _ in
            Task {
                await self?.stopTypingTriggered()
            }
        }
    }
    
    private func stopTypingTriggered() async {
        if await reachibilityService?.reachable == false { return }

        Task {
            try? await self.eventRemoteService.fire(.stopTyping)
        }
        
        self.userStartTypingDate = nil
        self.userStopTypingTimer = nil
    }

    private func agentStartTyping() async {
        let agentReallyStartTyping = !agentIsTyping
        agentIsTyping = true

        agentStopTypingTimer?.invalidate()
        agentStopTypingTimer = Timer.scheduledTimer(
            withTimeInterval: kParleyEventStopTypingTriggerAfter,
            repeats: false,
            block: { [weak self] _ in
                Task {
                    await self?.agentStopTyping()
                }
            }
        )

        if agentReallyStartTyping {
            await MainActor.run {
                UIAccessibility.post(
                    notification: .announcement,
                    argument: ParleyLocalizationKey.voiceOverAnnouncementAgentTyping.localized()
                )
            }
            await messagesInteractor.handleAgentBeganTyping()
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

// MARK: - Methods
extension ParleyActor {
    
    public func set(localizationManager: LocalizationManager) {
        self.localizationManager = localizationManager
    }
    
    func handle(_ messageData: Parley.RemoteMessageData) async -> Bool {
        if secret == nil {
            return false
        }
        
        let userInfo = messageData.userInfo

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
            await handleMessage(object)
        case MessageTypeEvent.event.rawValue:
            await handleEvent(object["name"] as? String)
        default:
            break
        }

        return true
    }
    
    public func enableOfflineMessaging(
        messageDataSource: ParleyMessageDataSource,
        keyValueDataSource: ParleyKeyValueDataSource,
        imageDataSource: ParleyMediaDataSource
    ) async {
        await enableOfflineMessaging(
            messageDataSource: messageDataSource,
            keyValueDataSource: keyValueDataSource,
            mediaDataSource: imageDataSource
        )
    }

    public func enableOfflineMessaging(
        messageDataSource: ParleyMessageDataSource,
        keyValueDataSource: ParleyKeyValueDataSource,
        mediaDataSource: ParleyMediaDataSource
    ) async {
        
        self.messageDataSource = messageDataSource
        self.keyValueDataSource = keyValueDataSource
        self.mediaDataSource = mediaDataSource
        
        await notifiyReachable(reachable)
    }

    public func disableOfflineMessaging() async {
        await messageDataSource?.clear()
        messageDataSource = nil
        keyValueDataSource = nil
        await mediaDataSource?.clear()
        mediaDataSource = nil
        await mediaRepository?.set(dataSource: nil)
        await notifiyReachable(reachable)
    }
    
    private func notifiyReachable(_ isReachable: Bool) async {
        if isReachable {
            await MainActor.run { [pushEnabled] in
                delegate?.reachable(pushEnabled: pushEnabled)
            }
        } else {
            let isCachingEnabled = isCachingEnabled()
            await MainActor.run {
                delegate?.unreachable(isCachingEnabled: isCachingEnabled)
            }
        }
    }
    
    public func setPushToken(
        _ pushToken: String,
        pushType: Device.PushType = .fcm
    ) async throws(ConfigurationError) {
        if pushToken == self.pushToken { return }

        self.pushToken = pushToken
        self.pushType = pushType

        try await registerDevice()
    }

    public func setPushEnabled(_ enabled: Bool) async throws(ConfigurationError) {
        guard pushEnabled != enabled else { return }

        pushEnabled = enabled

        await MainActor.run {
            delegate?.didChangePushEnabled(enabled)
        }

        try await registerDevice()
    }

    public func setUserInformation(
        _ authorization: String,
        additionalInformation: [String: String]? = nil
    )  async throws(ConfigurationError) {
        userAuthorization = authorization
        userAdditionalInformation = additionalInformation

        if state == .configured {
            try await reconfigure()
        }
    }

    public func clearUserInformation() async throws(ConfigurationError) {
        userAuthorization = nil
        userAdditionalInformation = nil

        if state == .configured {
            try await reconfigure()
        }
    }

    public func setLocalizationManager(_ localizationManager: LocalizationManager) {
        self.localizationManager = localizationManager
    }

    public func configure(
        _ secret: String,
        uniqueDeviceIdentifier: String? = nil,
        networkConfig: ParleyNetworkConfig,
        networkSession: ParleyNetworkSession
    ) async throws(ConfigurationError) {
        await initialize(networkConfig: networkConfig, networkSession: networkSession)
        
        try await configure(
            secret,
            uniqueDeviceIdentifier: uniqueDeviceIdentifier,
            clearCache: true
        )
        
        if let display = displayToAttach.take() {
            let presenter = await MessagesPresenter(
                store: messagesStore,
                display: display,
                usesAdaptiveWelcomePosistioning: display.appearance.info.position == .adaptive
            )
            await messagesInteractor.set(presenter: presenter)
            await display.signalAttached()
        } else {
            // Already attached, refreshing display
            await messagesInteractor.handleViewDidLoad()
        }
    }

    public func reset() async throws(ConfigurationError) {
        await mediaLoader?.reset()

        userAuthorization = nil
        userAdditionalInformation = nil
        await mediaRepository?.reset()
        removeObservers()
        
        try await registerDevice()
        secret = nil
        await set(state: .unconfigured)

        await clearChat()
    }

    public func purgeLocalMemory() async {
        await mediaLoader?.reset()
        userAuthorization = nil
        userAdditionalInformation = nil
        await mediaRepository?.reset()
        secret = nil
        removeObservers()
        await clearChat()
        await set(state: .unconfigured)
    }

    public func setReferrer(_ referrer: String) {
        self.referrer = referrer
    }

    public func setAlwaysPolling(_ enabled: Bool) {
        self.alwaysPolling = enabled
    }
}

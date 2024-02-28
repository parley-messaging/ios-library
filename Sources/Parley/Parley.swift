import Reachability
import Foundation
import UIKit

public final class Parley {

    enum State {
        case unconfigured
        case configuring
        case configured
        case failed
    }

    static let shared = Parley()

    private(set) var state: State = .unconfigured {
        didSet {
            self.delegate?.didChangeState(self.state)
        }
    }
    private var isLoading = false

    private var reachability: Reachability?
    private var reachable = false {
        didSet {
            if self.reachable {
                self.delegate?.reachable()

                if self.state == .failed || self.state == .configured {
                    self.configure()
                }
            } else {
                self.delegate?.unreachable()
            }
        }
    }

    private(set) var secret: String?
    private(set) var uniqueDeviceIdentifier: String?

    private(set) var remote: ParleyRemote!
    private(set) var networkConfig: ParleyNetworkConfig!
    private(set) var deviceRepository: DeviceRepository!
    private(set) var eventRemoteService: EventRemoteService!
    private(set) var messageRepository: MessageRepository!
    private(set) var messagesManager: MessagesManager!
    private(set) var imageDataSource: ParleyImageDataSource?
    private(set) var imageRepository: ImageRepository!
    private(set) var messageDataSource: ParleyMessageDataSource?
    private(set) var keyValueDataSource: ParleyKeyValueDataSource?
 
    private(set) var pushToken: String? = nil
    private(set) var pushType: Device.PushType? = nil
    private(set) var pushEnabled: Bool = false
    
    private(set) var referrer: String? = nil

    private(set) var userAuthorization: String?
    private(set) var userAdditionalInformation: [String: String]?

    weak var delegate: ParleyDelegate? {
        didSet {
            if self.delegate == nil { return }

            self.delegate?.didChangeState(self.state)

            if self.reachable {
                self.delegate?.reachable()
            } else {
                self.delegate?.unreachable()
            }
        }
    }

    private(set) var agentIsTyping = false
    private var agentStopTypingTimer: Timer?

    private var userStartTypingDate: Date?
    private var userStopTypingTimer: Timer?

    private init() {
        addObservers()
        setupReachability()
    }

    deinit {
        removeObservers()
        reachability?.stopNotifier()
    }

    private func initialize(networkConfig: ParleyNetworkConfig, networkSession: ParleyNetworkSession) {
        let remote = ParleyRemote(
            networkConfig: networkConfig,
            networkSession: networkSession,
            createSecret: { [weak self] in self?.secret },
            createUniqueDeviceIdentifier: { [weak self] in self?.uniqueDeviceIdentifier },
            createUserAuthorizationToken: { [weak self] in self?.userAuthorization }
        )
        self.networkConfig = networkConfig
        self.deviceRepository = DeviceRepository(remote: remote)
        self.eventRemoteService = EventRemoteService(remote: remote)
        self.messageRepository = MessageRepository(remote: remote)
        self.messagesManager = MessagesManager(messageDataSource: messageDataSource, keyValueDataSource: keyValueDataSource)
        self.remote = remote
        self.imageRepository = ImageRepository(remote: remote)
        self.imageRepository.dataSource = imageDataSource
    }

    // MARK: Reachability

    private func setupReachability() {
        self.reachability = try? Reachability()
        self.reachability?.whenReachable = { [weak self] _ in
            self?.reachable = true
        }

        self.reachability?.whenUnreachable = { [weak self] _ in
            self?.reachable = false
        }

        try? reachability?.startNotifier()
    }

    // MARK: Observers

    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    private func removeObservers() {
        NotificationCenter.default.removeObserver(UIApplication.willEnterForegroundNotification)
        NotificationCenter.default.removeObserver(UIApplication.didEnterBackgroundNotification)
    }

    @objc private func willEnterForeground() {
        try? self.reachability?.startNotifier()

        if self.state == .failed || self.state == .configured {
            self.configure()
        }
    }

    @objc private func didEnterBackground() {
        self.reachability?.stopNotifier()
    }

    // MARK: Configure

    private func configure(
        _ secret: String,
        uniqueDeviceIdentifier: String?,
        onSuccess: (() -> ())? = nil,
        onFailure: ((_ code: Int, _ message: String) -> ())? = nil,
        clearCache: Bool = false
    ) {
        debugPrint("Parley.\(#function)")

        if clearCache {
            clearCacheWhenNeeded(secret: secret)
        }

        self.state = .unconfigured

        self.secret = secret
        self.uniqueDeviceIdentifier = uniqueDeviceIdentifier

        self.configure(onSuccess: onSuccess, onFailure: onFailure)
    }

    private func configure(onSuccess: (() -> ())? = nil, onFailure: ((_ code: Int, _ message: String) -> ())? = nil) {
        debugPrint("Parley.\(#function)")

        if self.isLoading { return }
        self.isLoading = true

        if self.isCachingEnabled() {
            self.keyValueDataSource?.set(self.secret, forKey: kParleyCacheKeySecret)
            self.keyValueDataSource?.set(self.userAuthorization, forKey: kParleyCacheKeyUserAuthorization)

            if self.state == .unconfigured {
                self.messagesManager.loadCachedData()

                self.state = .configured
            }
        } else {
            if self.state == .unconfigured || self.state == .failed {
                self.messagesManager.clear()

                self.state = .configuring
            }
        }

        let onFailure: (_ error: Error) -> () = { [weak self] error in
            guard let self else { return }
            self.isLoading = false

            if self.isOfflineError(error) && self.isCachingEnabled() {
                onSuccess?()
            } else {
                self.state = .failed

                onFailure?((error as NSError).code, error.getFormattedMessage())
            }
        }

        deviceRepository.register(
            device: makeDeviceData(),
            onSuccess: { [weak self] _ in
                guard let self else { return }
                let onSecondSuccess: () -> () = { [weak self] in
                    guard let self else { return }
                    self.delegate?.didReceiveMessages()

                    let pendingMessages = Array(self.messagesManager.pendingMessages)
                    self.send(pendingMessages)

                    self.isLoading = false

                    self.state = .configured

                    onSuccess?()
                }

                if let lastMessage = self.messagesManager.lastSentMessage, let id = lastMessage.id {
                    messageRepository.findAfter(id, onSuccess: { [weak messagesManager] messageCollection in
                        messagesManager?.handle(messageCollection, .after)

                        onSecondSuccess()
                    }, onFailure: onFailure)
                } else {
                    messageRepository.findAll(onSuccess: { [weak messagesManager] messageCollection in
                        messagesManager?.handle(messageCollection, .all)

                        onSecondSuccess()
                    }, onFailure: onFailure)
                }
            },
            onFailure: onFailure
        )
    }
    
    private func reconfigure(onSuccess: (() -> ())? = nil, onFailure: ((_ code: Int, _ message: String) -> ())? = nil) {
        clearChat()
        configure(onSuccess: onSuccess, onFailure: onFailure)
    }
    
    private func clearChat() {
        clearMessages()
        state = .unconfigured
    }

    private func isOfflineError(_ error: Error) -> Bool {
        if let httpError = error as? HTTPErrorResponse {
            return httpError.isOfflineError
        } else {
            return isOfflineErrorCode((error as NSError).code)
        }
    }

    private func isOfflineErrorCode(_ code: Int) -> Bool {
        return code == 13
    }
    
    // MARK: Caching

    func isCachingEnabled() -> Bool {
        return self.messageDataSource != nil
    }

    private func clearCacheWhenNeeded(secret: String) {
        if let cachedSecret = self.keyValueDataSource?.string(forKey: kParleyCacheKeySecret), cachedSecret == secret {
            return
        } else if let currentSecret = self.secret, currentSecret == secret {
            return
        }
        
        self.clearMessages()
    }
    

    private func clearMessages() {
        messagesManager.clear()
        messageDataSource?.clear()
        keyValueDataSource?.clear() // MARK: ??
        delegate?.didReceiveMessages()
    }

    // MARK: Devices
    private func registerDevice(onSuccess: (() -> ())? = nil, onFailure: ((_ code: Int, _ message: String) -> ())? = nil) {
        if self.state == .configuring || self.state == .configured {
            deviceRepository.register(device: makeDeviceData(), onSuccess: { _ in
                onSuccess?()
            }, onFailure: { error in
                onFailure?((error as NSError).code, error.getFormattedMessage())
            })
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

    func loadMoreMessages(_ lastMessageId: Int) {
        guard self.reachable || !self.isLoading || self.messagesManager.canLoadMore() else {
            return
        }

        self.isLoading = true
        messageRepository.findBefore(lastMessageId, onSuccess: { [weak self] messageCollection in
            self?.isLoading = false

            self?.messagesManager.handle(messageCollection, .before)

            self?.delegate?.didReceiveMessages()
        }, onFailure: { [weak self] (error) in
            self?.isLoading = false
        })
    }

    private func send(_ messages: [Message]) {
        guard let message = messages.first else { return }
        send(message, isNewMessage: false, onNext: { [weak self] in
            self?.send(Array(messages.dropFirst()))
        })
    }
    
    internal func upload(media: MediaModel, displayedImage: UIImage?) {
        let localImage = ParleyStoredImage.from(media: media)
        let message = media.createMessage(status: .pending)
        message.media = MediaObject(id: localImage.id)
        
        imageRepository.store(image: localImage)
        addNewMessage(message)
        
        imageRepository.upload(image: localImage) { [weak self] result in
            switch result {
            case .success(let remoteImage):
                message.media = MediaObject(id: remoteImage.id)
                self?.messagesManager.update(message)
                self?.send(message, isNewMessage: false, onNext: nil)
            case .failure(let failure):
                self?.failedToSend(message: message, error: failure)
            }
        }
    }

    /**
     Send a message to Parley.

     - Note: Call after chat is configured.

     - Parameters:
       - text: The message to sent
       - silent: Indicates if the message needs to be sent silently. The message will not be shown when `silent=true`.
     */
    func send(_ text: String, silent: Bool = false) {
        let message = Message()
        message.message = text
        message.type = silent ? .systemMessageUser : .user
        message.status = .pending
        message.time = Date()

        self.send(message, isNewMessage: true)
    }

    func send(_ message: Message, isNewMessage: Bool, onNext: (() -> ())? = nil) {
        message.referrer = self.referrer

        if isNewMessage {
            addNewMessage(message)
        }

        guard self.reachable else { return }

        func onSuccess(message: Message) {
            message.status = .success
            messagesManager.update(message)
            delegate?.didUpdate(message)

            delegate?.didSent(message)

            onNext?()
        }

        func onError(error: Error) {
            failedToSend(message: message, error: error)
            onNext?()
        }
        
        messageRepository.store(message, onSuccess: onSuccess(message:), onFailure: onError(error:))
    }
    
    private func addNewMessage(_ message: Message) {
        let indexPaths = messagesManager.add(message)
        delegate?.willSend(indexPaths)
        userStopTypingTimer?.fire()
    }
    
    private func failedToSend(message: Message, error: Error) {
        if let parleyError = error as? ParleyErrorResponse {
            message.responseInfoType = parleyError.notifications.first?.message
        }
        
        if !isCachingEnabled() || !isOfflineError(error) {
            message.status = .failed
            messagesManager.update(message)
            delegate?.didUpdate(message)
        }
    }

    // MARK: Remote messages

    private func handleMessage(_ userInfo: [String: Any]) {
        guard let id = userInfo["id"] as? Int else { return }
        guard let typeId = userInfo["typeId"] as? Int else { return }
        let body = userInfo["body"] as? String

        let message = Message()
        message.id = id
        message.message = body
        message.type = Message.MessageType(rawValue: typeId)
        message.time = Date()

        if self.isLoading { return } // Ignore remote messages when configuring chat.

        if let id = message.id {
            messageRepository.find(id, onSuccess: { [weak self] message in
                guard let self else { return }
                if let announcement = Message.Accessibility.getAccessibilityAnnouncement(for: message) {
                    UIAccessibility.post(notification: .announcement, argument: announcement)
                }
                delegate?.didStopTyping()

                let indexPaths = self.messagesManager.add(message)
                delegate?.didReceiveMessage(indexPaths)
            }) { [weak self] error in
                guard let self else { return }

                if let announcement = Message.Accessibility.getAccessibilityAnnouncement(for: message) {
                    UIAccessibility.post(notification: .announcement, argument: announcement)
                }
                delegate?.didStopTyping()

                let indexPaths = self.messagesManager.add(message)
                delegate?.didReceiveMessage(indexPaths)
            }
        } else {
            delegate?.didStopTyping()

            let indexPaths = messagesManager.add(message)
            delegate?.didReceiveMessage(indexPaths)
        }
    }

    private func handleEvent(_ event: String?) {
        switch event {
        case kParleyEventStartTyping?:
            agentStartTyping()
        case kParleyEventStopTyping?:
            agentStopTyping()
        default:
            break
        }
    }

    // MARK: isTyping

    func userStartTyping() {
        guard self.reachable else { return }

        if self.userStartTypingDate == nil || Date().timeIntervalSince1970 - self.userStartTypingDate!.timeIntervalSince1970 > kParleyEventStartTypingTriggerAfter {
            eventRemoteService.fire(kParleyEventStartTyping, onSuccess: {}, onFailure: { _ in })

            self.userStartTypingDate = Date()
        }

        self.userStopTypingTimer?.invalidate()
        self.userStopTypingTimer = Timer.scheduledTimer(withTimeInterval: kParleyEventStopTypingTriggerAfter, repeats: false) { (timer) in
            if !self.reachable { return }

            self.eventRemoteService.fire(kParleyEventStopTyping, onSuccess: {}, onFailure: { _ in })

            self.userStartTypingDate = nil
            self.userStopTypingTimer = nil
        }
    }

    private func agentStartTyping() {
        let agentReallyStartTyping = !self.agentIsTyping
        self.agentIsTyping = true

        self.agentStopTypingTimer?.invalidate()
        self.agentStopTypingTimer = Timer.scheduledTimer(withTimeInterval: kParleyEventStopTypingTriggerAfter, repeats: false, block: { _ in
            self.agentStopTyping()
        })

        if agentReallyStartTyping {
            UIAccessibility.post(notification: .announcement, argument: "parley_voice_over_announcement_agent_typing".localized)
            self.delegate?.didStartTyping()
        }
    }

    private func agentStopTyping() {
        guard self.agentIsTyping else { return }

        self.agentIsTyping = false

        self.agentStopTypingTimer?.invalidate()
        self.agentStopTypingTimer = nil

        self.delegate?.didStopTyping()
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

        guard let data = (userInfo["parley"] as? String)?.data(using: .utf8) else { return false }

        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else { return false }
        guard let messageType = json["type"] as? String else { return false }
        guard let object = json["object"] as? [String: Any] else { return false }

        switch messageType {
        case kParleyTypeMessage:
            shared.handleMessage(object)
        case kParleyTypeEvent:
            shared.handleEvent(object["name"] as? String)
        default:
            break
        }

        return true
    }

    /**
     Enable offline messaging.

     - Parameters:
       - dataSource: ParleyDataSource instance
     */
    public static func enableOfflineMessaging(
        messageDataSource: ParleyMessageDataSource,
        keyValueDataSource: ParleyKeyValueDataSource
    ) {
        shared.messageDataSource = messageDataSource
        shared.keyValueDataSource = keyValueDataSource
        
        shared.reachable ? shared.delegate?.reachable() : shared.delegate?.unreachable()
    }

    /**
     Disable offline messaging.

     - Note: The `clear()` method will be called on the current instance to prevent unused data on the device.
     */
    public static func disableOfflineMessaging() {
        shared.messageDataSource?.clear()
        shared.messageDataSource = nil
        shared.imageDataSource?.clear()
        shared.imageDataSource = nil
        shared.imageRepository.dataSource = nil
        
        shared.reachable ? shared.delegate?.reachable() : shared.delegate?.unreachable()
    }

    /**
      Set the users Firebase Cloud Messaging token.

      - Note: Method must be called before `Parley.configure(_ secret: String)`.

      - Parameters:
        - fcmToken: The Firebase Cloud Messaging token
        - pushType: The push type (default `fcm`)
        - onSuccess: Execution block when Firebase Cloud Messaging token is updated (only called when Parley is configuring/configured).
        - onFailure: Execution block when Firebase Cloud Messaging token can not updated (only called when Parley is configuring/configured). This block takes an Int which represents the HTTP Status Code and a String describing what went wrong.
     */
    @available(*, deprecated, renamed: "setPushToken(_:pushType:onSuccess:onFailure:)")
    public static func setFcmToken(
        _ fcmToken: String,
        pushType: Device.PushType = .fcm,
        onSuccess: (() -> ())? = nil,
        onFailure: ((_ code: Int, _ message: String) -> ())? = nil
    ) {
        setPushToken(fcmToken, pushType: pushType, onSuccess: onSuccess,onFailure: onFailure)
    }

    /**
      Set the push token of the user.

      - Note: Method must be called before `Parley.configure(_ secret: String)`.

      - Parameters:
        - pushToken: The push token
        - pushType: The push type (default `fcm`)
        - onSuccess: Execution block when Firebase Cloud Messaging token is updated (only called when Parley is configuring/configured).
        - onFailure: Execution block when Firebase Cloud Messaging token can not updated (only called when Parley is configuring/configured). This block takes an Int which represents the HTTP Status Code and a String describing what went wrong.
     */
    public static func setPushToken(
        _ pushToken: String,
        pushType: Device.PushType = .fcm,
        onSuccess: (() -> ())? = nil,
        onFailure: ((_ code: Int, _ message: String) -> ())? = nil
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
        - onSuccess: Execution block when pushEnabled is updated (only called when Parley is configuring/configured).
        - onFailure: Execution block when pushEnabled can not updated (only called when Parley is configuring/configured). This block takes an Int which represents the HTTP Status Code and a String describing what went wrong.
     */
    public static func setPushEnabled(
        _ enabled: Bool,
        onSuccess: (() -> ())? = nil,
        onFailure: ((_ code: Int, _ message: String) -> ())? = nil
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
       - onSuccess: Execution block when user information is set (only called when Parley is configuring/configured).
       - onFailure: Execution block when user information is can not be set (only called when Parley is configuring/configured). This block takes an Int which represents the HTTP Status Code and a String describing what went wrong.
     */
    public static func setUserInformation(
        _ authorization: String,
        additionalInformation: [String : String]? = nil,
        onSuccess: (() -> ())? = nil,
        onFailure: ((_ code: Int, _ message: String) -> ())? = nil
    ) {
        shared.userAuthorization = authorization
        shared.userAdditionalInformation = additionalInformation

        if shared.state == .configured {
            shared.reconfigure(onSuccess: onSuccess, onFailure: onFailure)
        }
    }

    /**
     Clear user information.

     - Parameters:
       - onSuccess: Execution block when user information is cleared (only called when Parley is configuring/configured).
       - onFailure: Execution block when user information is can not be cleared (only called when Parley is configuring/configured). This block takes an Int which represents the HTTP Status Code and a String describing what went wrong.
     */
    public static func clearUserInformation(
        onSuccess: (() -> ())? = nil,
        onFailure: ((_ code: Int, _ message: String) -> ())? = nil
    ) {
        shared.userAuthorization = nil
        shared.userAdditionalInformation = nil

        if shared.state == .configured {
            shared.reconfigure(onSuccess: onSuccess, onFailure: onFailure)
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

     - Note: calling `Parley.configure()` twice is unsupported, make sure to call `Parley.configure()` only once for the lifecycle of Parley.shared._

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
        onSuccess: (() -> ())? = nil,
        onFailure: ((_ code: Int, _ message: String) -> ())? = nil
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
    public static func reset(onSuccess: (() -> ())? = nil, onFailure: ((_ code: Int, _ message: String) -> ())? = nil) {
        shared.userAuthorization = nil
        shared.userAdditionalInformation = nil
        shared.imageRepository.reset()
        
        Parley.shared.registerDevice(onSuccess: {
            shared.secret = nil
            onSuccess?()
        }, onFailure: { code, message in
            shared.secret = nil
            onFailure?(code, message)
        })

        shared.clearChat()
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
    
    public static func setImageDataSource(_ dataSource: ParleyImageDataSource) {
        shared.imageDataSource = dataSource
    }
}

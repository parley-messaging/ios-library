import Reachability
import Foundation
import UIKit

public class Parley {

    enum State {
        case unconfigured
        case configuring
        case configured
        case failed
    }

    internal static let shared = Parley()

    internal var state: State = .unconfigured {
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

    internal var secret: String?
    internal var uniqueDeviceIdentifier: String?

    internal var network: ParleyNetwork = ParleyNetwork()
    internal var dataSource: ParleyDataSource? {
        didSet {
            reachable ? delegate?.reachable() : delegate?.unreachable()
        }
    }

    internal var pushToken: String? = nil
    internal var pushType: Device.PushType? = nil
    internal var pushEnabled: Bool = false
    
    internal var referrer: String? = nil

    internal var userAuthorization: String?
    internal var userAdditionalInformation: [String: String]?
    private let notificationService = NotificationService()

    internal weak var delegate: ParleyDelegate? {
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

    internal let messagesManager = MessagesManager()

    internal var agentIsTyping = false
    private var agentStopTypingTimer: Timer?

    private var userStartTypingDate: Date?
    private var userStopTypingTimer: Timer?

    init() {
        ParleyRemote.refresh(self.network)
        addObservers()
        setupReachability()
    }

    deinit {
        removeObservers()
        reachability?.stopNotifier()
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
    private func configure(_ secret: String, uniqueDeviceIdentifier: String?, onSuccess: (()->())? = nil, onFailure: ((_ code: Int, _ message: String)->())? = nil) {
        debugPrint("Parley.\(#function)")

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
            self.dataSource?.set(self.secret, forKey: kParleyCacheKeySecret)
            self.dataSource?.set(self.userAuthorization, forKey: kParleyCacheKeyUserAuthorization)
            
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

        let onFailure: (_ error: Error) -> () = { error in
            self.isLoading = false

            if self.isOfflineError(error) && self.isCachingEnabled() {
                onSuccess?()
            } else {
                self.state = .failed

                onFailure?((error as NSError).code, (error as NSError).localizedDescription)
            }
        }

        DeviceRepository().register({ [weak self, messagesManager, weak delegate] _ in
            guard let self = self else { return }
            let onSecondSuccess: () -> () = {
                delegate?.didReceiveMessages()

                let pendingMessages = Array(messagesManager.pendingMessages.reversed())
                self.send(pendingMessages)

                self.isLoading = false

                self.state = .configured

                onSuccess?()
            }

            if let lastMessage = self.messagesManager.lastSentMessage, let id = lastMessage.id {
                MessageRepository().findAfter(id, onSuccess: { [weak messagesManager] messageCollection in
                    messagesManager?.handle(messageCollection, .after)

                    onSecondSuccess()
                }, onFailure: onFailure)
            } else {
                MessageRepository().findAll(onSuccess: { [weak messagesManager] messageCollection in
                    messagesManager?.handle(messageCollection, .all)

                    onSecondSuccess()
                }, onFailure: onFailure)
            }
        }, onFailure)
    }
    
    private func reconfigure(onSuccess: (()->())? = nil, onFailure: ((_ code: Int, _ message: String)->())? = nil) {
        Parley.shared.clearChat()
        Parley.shared.configure(onSuccess: onSuccess, onFailure: onFailure)
    }
    
    private func clearChat() {
        clearMessages()
        state = .unconfigured
    }

    private func isOfflineError(_ error: Error) -> Bool {
        return isOfflineErrorCode((error as NSError).code)
    }

    private func isOfflineErrorCode(_ code: Int) -> Bool {
        return code == 13
    }
    
    private func clearCacheWhenNeeded(secret: String) {
        if let cachedSecret = self.dataSource?.string(forKey: kParleyCacheKeySecret), cachedSecret == secret {
            return
        } else if let currentSecret = self.secret, currentSecret == secret {
            return
        }
        
        self.clearMessages()
    }
    
    private func clearMessages() {
        self.messagesManager.clear()
        self.dataSource?.clear()
        delegate?.didReceiveMessages()
    }
    
    // MARK: Devices
    private func registerDevice(onSuccess: (()->())? = nil, onFailure: ((_ code: Int, _ message: String)->())? = nil) {
        if self.state == .configuring || self.state == .configured {
            DeviceRepository().register({ _ in
                onSuccess?()
            }) { error in
                onFailure?((error as NSError).code, (error as NSError).localizedDescription)
            }
        }
    }

    // MARK: Messages
    internal func loadMoreMessages(_ lastMessageId: Int) {
        if !self.reachable || self.isLoading || !self.messagesManager.canLoadMore()  {
            return
        }

        self.isLoading = true
        MessageRepository().findBefore(lastMessageId, onSuccess: { messageCollection in
            self.isLoading = false

            self.messagesManager.handle(messageCollection, .before)

            self.delegate?.didReceiveMessages()
        }, onFailure: { (error) in
            self.isLoading = false
        })
    }

    private func send(_ messages: [Message]) {
        if let message = messages.first {
            send(message, isNewMessage: false, onNext: { [weak self] in
                self?.send(Array(messages.dropFirst()))
            })
        }
    }

    internal func send(_ text: String, silent: Bool = false) {
        let message = Message()
        message.message = text
        message.type = silent ? .systemMessageUser : .user
        message.status = .pending
        message.time = Date()

        self.send(message, isNewMessage: true)
    }
    
    @available(*, deprecated)
    internal func send(_ imageUrl: URL, _ image: UIImage, _ imageData: Data? = nil) {
        let message = Message()
        message.type = .user
        message.imageURL = imageUrl
        message.image = image
        message.imageData = imageData
        message.status = .pending
        message.time = Date()

        self.send(message, isNewMessage: true)
    }
    
    internal func upload(media: MediaModel, displayedImage: UIImage?) {
        let message = media.createMessage(status: .pending)
        message.image = displayedImage
        send(message, isNewMessage: true, onNext: nil)
    }

    internal func send(_ message: Message, isNewMessage: Bool, onNext: (() -> ())? = nil) {
        message.referrer = self.referrer
        
        if isNewMessage {
            let indexPaths = messagesManager.add(message)
            delegate?.willSend(indexPaths)

            userStopTypingTimer?.fire()
        }

        guard self.reachable else { return }
        
        func onSuccess(message: Message) {
            message.status = .success
            message.mediaSendRequest = nil
            messagesManager.update(message)
            delegate?.didUpdate(message)

            delegate?.didSent(message)

            onNext?()
        }
        
        func onError(error: Error) {
            if !isCachingEnabled() || !isOfflineError(error) {
                message.status = .failed
                messagesManager.update(message)
                delegate?.didUpdate(message)
            }

            onNext?()
        }
        
        if let mediaSendRequest = message.mediaSendRequest, mediaSendRequest.hasUploaded == false {
            MessageRepository()
                .upload(
                    imageData: mediaSendRequest.image,
                    imageType: mediaSendRequest.type,
                    fileName: mediaSendRequest.filename) { [weak self] result in
                        switch result {
                        case .success(let response):
                            message.media = MediaObject(id: response.media, description: nil)
                            message.status = .pending
                            message.mediaSendRequest?.hasUploaded = true
                            self?.send(message, isNewMessage: false, onNext: nil)
                        case .failure(let error):
                            onError(error: error)
                        }
                    }
        } else {
            MessageRepository().store(message, onSuccess: onSuccess(message:), onFailure: onError(error:))
        }
    }

    // MARK: Remote messages
    internal func handleMessage(_ userInfo: [String: Any]) {
        guard let id = userInfo["id"] as? Int else { return }
        guard let typeId = userInfo["typeId"] as? Int else { return }
        guard let body = userInfo["body"] as? String else { return }

        let message = Message()
        message.id = id
        message.message = body
        message.type = Message.MessageType(rawValue: typeId)
        message.time = Date()

        if self.isLoading { return } // Ignore remote messages when configuring chat.

        if let id = message.id {
            MessageRepository().find(id, onSuccess: { [weak delegate, messagesManager] message in
                if let announcement = Message.Accessibility.getAccessibilityAnnouncement(for: message) {
                    UIAccessibility.post(notification: .announcement, argument: announcement)
                }
                delegate?.didStopTyping()

                let indexPaths = messagesManager.add(message)
                delegate?.didReceiveMessage(indexPaths)
            }) { [weak delegate, messagesManager] error in
                if let announcement = Message.Accessibility.getAccessibilityAnnouncement(for: message) {
                    UIAccessibility.post(notification: .announcement, argument: announcement)
                }
                delegate?.didStopTyping()

                let indexPaths = messagesManager.add(message)
                delegate?.didReceiveMessage(indexPaths)
            }
        } else {
            delegate?.didStopTyping()

            let indexPaths = messagesManager.add(message)
            delegate?.didReceiveMessage(indexPaths)
        }
    }

    internal func handleEvent(_ event: String?) {
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
    internal func userStartTyping() {
        if !self.reachable { return }

        if self.userStartTypingDate == nil || Date().timeIntervalSince1970 - self.userStartTypingDate!.timeIntervalSince1970 > kParleyEventStartTypingTriggerAfter {
            EventRemoteService().fire(kParleyEventStartTyping, onSuccess: {}, onFailure: { _ in })

            self.userStartTypingDate = Date()
        }

        self.userStopTypingTimer?.invalidate()
        self.userStopTypingTimer = Timer.scheduledTimer(withTimeInterval: kParleyEventStopTypingTriggerAfter, repeats: false) { (timer) in
            if !self.reachable { return }

            EventRemoteService().fire(kParleyEventStopTyping, onSuccess: {}, onFailure: { _ in })

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
        if !self.agentIsTyping { return }

        self.agentIsTyping = false

        self.agentStopTypingTimer?.invalidate()
        self.agentStopTypingTimer = nil

        self.delegate?.didStopTyping()
    }

    // MARK: Caching
    internal func isCachingEnabled() -> Bool {
        return self.dataSource != nil
    }
}

extension Parley {

    /**
     Handle remote message.

     - Parameter userInfo: Remote message data.

     - Returns: `true` if Parley handled this payload, `false` otherwise
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
     Set custom network settings.

     - Note: Method must be called before `Parley.configure(_ secret: String)`.

     - Parameter network: ParleyNetwork instance
    */
    public static func setNetwork(_ network: ParleyNetwork) {
        shared.network = network

        ParleyRemote.refresh(network)
    }

    /**
     Enable offline messaging.

     - Parameter dataSource: ParleyDataSource instance
     */
    public static func enableOfflineMessaging(_ dataSource: ParleyDataSource) {
        shared.dataSource = dataSource
    }

    /**
     Disable offline messaging.

     - Note: The `clear()` method will be called on the current instance to prevent unused data on the device.
     */
    public static func disableOfflineMessaging() {
        if let dataSource = shared.dataSource {
            dataSource.clear()
        }

        shared.dataSource = nil
    }

    /**
     Set the users Firebase Cloud Messaging token.

     - Note: Method must be called before `Parley.configure(_ secret: String)`.

     - Parameter fcmToken: The Firebase Cloud Messaging token
     - Parameter pushType: The push type (default `fcm`)
     - Parameter onSuccess: Execution block when Firebase Cloud Messaging token is updated (only called when Parley is configuring/configured).
     - Parameter onFailure: Execution block when Firebase Cloud Messaging token can not updated (only called when Parley is configuring/configured). This block takes an Int which represents the HTTP Status Code and a String describing what went wrong.
    */
    @available(*, deprecated, renamed: "setPushToken(_:pushType:onSuccess:onFailure:)")
    public static func setFcmToken(_ fcmToken: String, pushType: Device.PushType = .fcm, onSuccess: (()->())? = nil, onFailure: ((_ code: Int, _ message: String)->())? = nil) {
        setPushToken(fcmToken, pushType: pushType, onSuccess: onSuccess,onFailure: onFailure)
    }
    
    /**
     Set the push token of the user.

     - Note: Method must be called before `Parley.configure(_ secret: String)`.

     - Parameter pushToken: The push token
     - Parameter pushType: The push type (default `fcm`)
     - Parameter onSuccess: Execution block when Firebase Cloud Messaging token is updated (only called when Parley is configuring/configured).
     - Parameter onFailure: Execution block when Firebase Cloud Messaging token can not updated (only called when Parley is configuring/configured). This block takes an Int which represents the HTTP Status Code and a String describing what went wrong.
    */
    public static func setPushToken(_ pushToken: String, pushType: Device.PushType = .fcm, onSuccess: (()->())? = nil, onFailure: ((_ code: Int, _ message: String)->())? = nil) {
        if shared.pushToken == pushToken { return }

        shared.pushToken = pushToken
        shared.pushType = pushType

        Parley.shared.registerDevice(onSuccess: onSuccess, onFailure: onFailure)
    }

    /**
     Set whether push is enabled by the user.

     - Parameter enabled: Indication if application's push is enabled.
     - Parameter onSuccess: Execution block when pushEnabled is updated (only called when Parley is configuring/configured).
     - Parameter onFailure: Execution block when pushEnabled can not updated (only called when Parley is configuring/configured). This block takes an Int which represents the HTTP Status Code and a String describing what went wrong.
    */
    public static func setPushEnabled(_ enabled: Bool, onSuccess: (()->())? = nil, onFailure: ((_ code: Int, _ message: String)->())? = nil) {
        if shared.pushEnabled == enabled { return }

        shared.pushEnabled = enabled

        shared.delegate?.didChangePushEnabled(enabled)

        Parley.shared.registerDevice(onSuccess: onSuccess, onFailure: onFailure)
    }

    /**
     Set user information.

     - Parameter authorization: Authorization of the user.
     - Parameter additionalInformation: Additional information of the user.
     - Parameter onSuccess: Execution block when user information is set (only called when Parley is configuring/configured).
     - Parameter onFailure: Execution block when user information is can not be set (only called when Parley is configuring/configured). This block takes an Int which represents the HTTP Status Code and a String describing what went wrong.
     */
    public static func setUserInformation(_ authorization: String, additionalInformation: [String:String]?=nil, onSuccess: (()->())? = nil, onFailure: ((_ code: Int, _ message: String)->())? = nil) {
        shared.userAuthorization = authorization
        shared.userAdditionalInformation = additionalInformation
        
        if shared.state == .configured {
            shared.reconfigure(onSuccess: onSuccess, onFailure: onFailure)
        }
    }

    /**
     Clear user information.

     - Parameter onSuccess: Execution block when user information is cleared (only called when Parley is configuring/configured).
     - Parameter onFailure: Execution block when user information is can not be cleared (only called when Parley is configuring/configured). This block takes an Int which represents the HTTP Status Code and a String describing what went wrong.
     */
    public static func clearUserInformation(onSuccess: (()->())? = nil, onFailure: ((_ code: Int, _ message: String)->())? = nil) {
        shared.userAuthorization = nil
        shared.userAdditionalInformation = nil
        
        if shared.state == .configured {
            shared.reconfigure(onSuccess: onSuccess, onFailure: onFailure)
        }
    }

    /**
     Configure Parley Messaging.
     
     The configure method allows setting a unique device identifier. If none is provided (default), Parley will default to
     a random UUID that will be stored in the user defaults. When providing a unique device
     ID to this configure method, it is not stored by Parley and only kept for the current instance
     of Parley. Client applications are responsible for storing it and providing Parley with the
     same ID. This gives client applications the flexibility to change the ID if required (for
     example when another user is logged-in to the app).
     
     _Note: calling `Parley.configure()` twice is unsupported, make sure to call `Parley.configure()` only once for the lifecycle of Parley._

     - Parameter secret: Application secret of your Parley instance.
     - Parameter uniqueDeviceIdentifier: The device identifier to use for device registration.
     - Parameter onSuccess: Execution block when Parley is configured.
     - Parameter onFailure: Execution block when Parley failed to configure. This block takes an Int which represents the HTTP Status Code and a String describing what went wrong.
     - Parameter code: HTTP Status Code.
     - Parameter message: Description what went wrong.
     */
    public static func configure(_ secret: String, uniqueDeviceIdentifier: String? = nil, onSuccess: (()->())? = nil, onFailure: ((_ code: Int, _ message: String)->())? = nil) {
        shared.clearCacheWhenNeeded(secret: secret)
        
        shared.configure(secret, uniqueDeviceIdentifier: uniqueDeviceIdentifier, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    /**
     Resets Parley back to its initial state (clearing the user information). Useful when logging out a user for example. Ensures that no user and chat data is left in memory.
     
     Leaves the network, offline messaging and referrer settings as is, these can be altered via the corresponding methods.
     
     __Note__: Requires calling the `configure()` method again to use Parley.
     */
    public static func reset(onSuccess: (()->())? = nil, onFailure: ((_ code: Int, _ message: String)->())? = nil) {
        shared.userAuthorization = nil
        shared.userAdditionalInformation = nil
        
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
     
     - Parameter message: The message to sent
     - Parameter silent: Indicates if the message needs to be sent silently. The message will not be shown when `silent=true`.
     */
    public static func send(_ message: String, silent: Bool = false) {
        shared.send(message, silent: silent)
    }
    
    /*
     Set referrer.
     
     - Parameter referrer: The referrer
     */
    public static func setReferrer(_ referrer: String) {
        shared.referrer = referrer
    }
}

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
            debugPrint("Parley.reachable: \(self.reachable)")

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

    internal var network: ParleyNetwork = ParleyNetwork()
    internal var dataSource: ParleyDataSource? {
        didSet {
            if self.reachable {
                self.delegate?.reachable()
            } else {
                self.delegate?.unreachable()
            }
        }
    }

    internal var pushToken: String? = nil
    internal var pushType: Device.PushType? = nil
    internal var pushEnabled: Bool = false
    
    internal var referrer: String? = nil

    internal var userAuthorization: String?
    internal var userAdditionalInformation: [String:String]?

    internal var delegate: ParleyDelegate? {
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

    internal var messagesManager = MessagesManager()

    internal var agentIsTyping = false
    private var agentStopTypingTimer: Timer?

    private var userStartTypingDate: Date?
    private var userStopTypingTimer: Timer?

    init() {
        ParleyRemote.refresh(self.network)

        self.addObservers()

        self.setupReachability()
    }

    deinit {
        self.removeObservers()

        self.reachability?.stopNotifier()
    }

    // MARK: Reachability
    private func setupReachability() {
        self.reachability = try? Reachability()
        self.reachability?.whenReachable = { _ in
            self.reachable = true
        }

        self.reachability?.whenUnreachable = { _ in
            self.reachable = false
        }

        try? self.reachability?.startNotifier()
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
    private func configure(_ secret: String, onSuccess: (()->())? = nil, onFailure: ((_ code: Int, _ message: String)->())? = nil) {
        debugPrint("Parley.configure(_, _, _)")

        self.state = .unconfigured

        self.secret = secret

        self.configure(onSuccess: onSuccess, onFailure: onFailure)
    }

    private func configure(onSuccess: (()->())? = nil, onFailure: ((_ code: Int, _ message: String)->())? = nil) {
        debugPrint("Parley.configure(_, _)")

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

        let onFailure: (_ error: Error)->() = { error in
            self.isLoading = false

            if self.isOfflineError(error) && self.isCachingEnabled() {
                onSuccess?()
            } else {
                self.state = .failed

                onFailure?((error as NSError).code, (error as NSError).localizedDescription)
            }
        }

        DeviceRepository().register ({ _ in
            let onSecondSuccess: () -> () = {
                self.delegate?.didReceiveMessages()

                let pendingMessages = Array(self.messagesManager.pendingMessages.reversed())
                self.send(pendingMessages)

                self.isLoading = false

                self.state = .configured

                onSuccess?()
            }

            if let lastMessage = self.messagesManager.lastMessage, let id = lastMessage.id {
                MessageRepository().findAfter(id, onSuccess: { messageCollection in
                    self.messagesManager.handle(messageCollection, .after)

                    onSecondSuccess()
                }, onFailure: onFailure)
            } else {
                MessageRepository().findAll(onSuccess: { messageCollection in
                    self.messagesManager.handle(messageCollection, .all)

                    onSecondSuccess()
                }, onFailure: onFailure)
            }
        }, onFailure)
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
        
        self.clear()
    }
    
    private func clearCacheWhenNeeded(userAuthorization: String?) {
        if let cachedUserAuthorization = self.dataSource?.string(forKey: kParleyCacheKeyUserAuthorization), cachedUserAuthorization == userAuthorization {
            return
        } else if let currentUserAuthorization = self.userAuthorization, currentUserAuthorization == userAuthorization {
            return
        }
        
        self.clear()
    }
    
    private func clear() {
        self.messagesManager.clear()
        self.dataSource?.clear()
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
            self.send(message, isNewMessage: false, onNext: {
                self.send(Array(messages.dropFirst()))
            })
        }
    }

    internal func send(_ text: String, silent: Bool = false) {
        let message = Message()
        message.message = text
        message.type = silent ? .systemMessageUser : .user
        message.status = .pending

        self.send(message, isNewMessage: true)
    }

    internal func send(_ imageUrl: URL, _ image: UIImage, _ imageData: Data?=nil) {
        let message = Message()
        message.type = .user
        message.imageURL = imageUrl
        message.image = image
        message.imageData = imageData
        message.status = .pending

        self.send(message, isNewMessage: true)
    }

    internal func send(_ message: Message, isNewMessage: Bool, onNext: (()->())? = nil) {
        message.referrer = self.referrer
        
        if isNewMessage {
            let indexPaths = self.messagesManager.add(message)
            self.delegate?.willSend(indexPaths)

            self.userStopTypingTimer?.fire()
        }

        if !self.reachable { return }

        MessageRepository().store(message, onSuccess: { message in
            message.status = .success

            self.messagesManager.update(message)
            self.delegate?.didUpdate(message)

            self.delegate?.didSent(message)

            onNext?()
        }) { (error) in
            if !self.isCachingEnabled() || !self.isOfflineError(error) {
                message.status = .failed

                self.messagesManager.update(message)
                self.delegate?.didUpdate(message)
            }

            onNext?()
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
            MessageRepository().find(id, onSuccess: { (message) in
                self.delegate?.didStopTyping()

                let indexPaths = self.messagesManager.add(message)
                self.delegate?.didReceiveMessage(indexPaths)
            }) { (error) in
                self.delegate?.didStopTyping()

                let indexPaths = self.messagesManager.add(message)
                self.delegate?.didReceiveMessage(indexPaths)
            }
        } else {
            self.delegate?.didStopTyping()

            let indexPaths = self.messagesManager.add(message)
            self.delegate?.didReceiveMessage(indexPaths)
        }
    }

    internal func handleEvent(_ event: String?) {
        switch event {
        case kParleyEventStartTyping?:
            self.agentStartTyping()

            break
        case kParleyEventStopTyping?:
            self.agentStopTyping()

            break
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

            break
        case kParleyTypeEvent:
            shared.handleEvent(object["name"] as? String)

            break
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
        shared.clearCacheWhenNeeded(userAuthorization: authorization)
        
        shared.userAuthorization = authorization
        shared.userAdditionalInformation = additionalInformation

        Parley.shared.registerDevice(onSuccess: onSuccess, onFailure: onFailure)
    }

    /**
     Clear user information.

     - Parameter onSuccess: Execution block when user information is cleared (only called when Parley is configuring/configured).
     - Parameter onFailure: Execution block when user information is can not be cleared (only called when Parley is configuring/configured). This block takes an Int which represents the HTTP Status Code and a String describing what went wrong.
     */
    public static func clearUserInformation(onSuccess: (()->())? = nil, onFailure: ((_ code: Int, _ message: String)->())? = nil) {
        shared.clearCacheWhenNeeded(userAuthorization: nil)
        
        shared.userAuthorization = nil
        shared.userAdditionalInformation = nil

        Parley.shared.registerDevice(onSuccess: onSuccess, onFailure: onFailure)
    }

    /**
     Configure Parley Messaging.

     - Parameter secret: Application secret of your Parley instance.
     - Parameter onSuccess: Execution block when Parley is configured.
     - Parameter onFailure: Execution block when Parley failed to configure. This block takes an Int which represents the HTTP Status Code and a String describing what went wrong.
     - Parameter code: HTTP Status Code.
     - Parameter message: Description what went wrong.
     */
    public static func configure(_ secret: String, onSuccess: (()->())? = nil, onFailure: ((_ code: Int, _ message: String)->())? = nil) {
        shared.clearCacheWhenNeeded(secret: secret)
        
        shared.configure(secret, onSuccess: onSuccess, onFailure: onFailure)
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

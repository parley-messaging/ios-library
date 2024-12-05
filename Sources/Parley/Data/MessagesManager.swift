import Foundation
import UIKit

protocol MessagesManagerProtocol: AnyObject {
    var messages: [Message] { get }
    var pendingMessages: [Message] { get }
    var lastSentMessage: Message? { get }
    var latestMessage: Message? { get }
    
    var welcomeMessage: String? { get }
    var stickyMessage: String? { get }

    func loadCachedData()
    func clear()
    func canLoadMore() -> Bool
    func handle(_ messageCollection: MessageCollection, _ handleType: MessagesManager.HandleType)
    func update(_ message: Message)
    func add(_ message: Message)
    func getOldestMessage() -> Message?
}

final class MessagesManager: MessagesManagerProtocol {

    enum HandleType {
        case all
        case before
        case after
    }

    private var originalMessages: [Message] = []
    var messages: [Message] { originalMessages }

    private(set) var welcomeMessage: String?
    private(set) var stickyMessage: String?
    private(set) var paging: MessageCollection.Paging?
    private weak var messageDataSource: ParleyMessageDataSource?
    private weak var keyValueDataSource: ParleyKeyValueDataSource?

    /// The last messages that has been successfully sent.
    var lastSentMessage: Message? {
        originalMessages.last { message in
            message.id != nil && message.status == .success
        }
    }
    
    /// Latest non-ignored message
    var latestMessage: Message? {
        for message in originalMessages {
            if !message.ignore() {
                return message
            }
        }
        return nil
    }

    /// The messages that are currently pending in a sorted way.
    var pendingMessages: [Message] {
        originalMessages.reduce([Message]()) { partialResult, message in
            switch message.status {
            case .failed, .pending:
                partialResult + [message]
            default:
                partialResult
            }
        }
    }

    func getOldestMessage() -> Message? {
        for message in originalMessages {
            switch message.type {
            case .agent, .systemMessageAgent, .user, .systemMessageUser:
                return message
            default:
                continue
            }
        }
        return nil
    }

    init(
        messageDataSource: ParleyMessageDataSource?,
        keyValueDataSource: ParleyKeyValueDataSource?
    ) {
        self.messageDataSource = messageDataSource
        self.keyValueDataSource = keyValueDataSource
    }

    func loadCachedData() {
        originalMessages.removeAll(keepingCapacity: true)

        if let cachedMessages = messageDataSource?.all() {
            originalMessages
                .append(
                    contentsOf: cachedMessages
                        .sorted(by: <)
                ) // When receiving them from cached, they could be sorted differently
        }

        stickyMessage = nil
        welcomeMessage = keyValueDataSource?.string(forKey: kParleyCacheKeyMessageInfo)

        if let cachedPagingData = keyValueDataSource?.data(forKey: kParleyCacheKeyPaging) {
            paging = try? CodableHelper.shared.decode(MessageCollection.Paging.self, from: cachedPagingData)
        } else {
            paging = nil
        }
    }

    func handle(_ messageCollection: MessageCollection, _ handleType: HandleType) {
        let newMessages = messageCollection.messages.filter { message in
            if originalMessages.contains(where: { $0.id == message.id }) {
                return false
            }
            return true
        }.sorted(by: <) // By default backend sorts them the other way around (initial retrieval and findAfter)

        switch handleType {
        case .before:
            originalMessages.insert(contentsOf: newMessages, at: .zero)
        case .all, .after:
            let pendingMessages = pendingMessages
            originalMessages.removeAll { message -> Bool in
                message.status == .pending || message.status == .failed
            }

            originalMessages.append(contentsOf: newMessages)
            originalMessages.append(contentsOf: pendingMessages)
        }

        messageDataSource?.save(originalMessages)
        stickyMessage = messageCollection.stickyMessage
        updateWelcomeMessage(messageCollection.welcomeMessage)

        if handleType != .after {
            paging = messageCollection.paging
            if let messages = try? CodableHelper.shared.toJSONString(paging) {
                keyValueDataSource?.set(messages, forKey: kParleyCacheKeyPaging)
            } else {
                keyValueDataSource?.removeObject(forKey: kParleyCacheKeyPaging)
            }
        }
    }

    private func updateWelcomeMessage(_ message: String?) {
        welcomeMessage = message
        if let welcomeMessage = message {
            keyValueDataSource?.set(welcomeMessage, forKey: kParleyCacheKeyMessageInfo)
        } else {
            keyValueDataSource?.removeObject(forKey: kParleyCacheKeyMessageInfo)
        }
    }
    
    struct ParleyAddMessageResult {
        let sectionIndex: Int
        let rowIndex: Int
        let section: ParleyMessageSection
        let didAddSection: Bool
    }

    func add(_ message: Message) {
        guard !originalMessages.contains(message) else { return }
        
        originalMessages.append(message)
        messageDataSource?.insert(message, at: 0)
    }

    func update(_ message: Message) {
        guard
            let originalMessagesIndex = originalMessages
                .firstIndex(where: { originalMessage in originalMessage.uuid == message.uuid })
        else { return }

        originalMessages[originalMessagesIndex] = message
        messageDataSource?.update(message)
    }

    private func createInfoMessages(_ message: String) -> Message {
        let infoMessage = Message()
        infoMessage.type = .info
        infoMessage.message = message
        return infoMessage
    }

    func canLoadMore() -> Bool {
        if let paging = paging, !paging.before.isEmpty {
            return true
        }

        return false
    }

    func clear() {
        originalMessages.removeAll()
        welcomeMessage = nil
        stickyMessage = nil
        paging = nil
        loadCachedData()
    }
}

#if DEBUG
// MARK: - Only used for testing
extension MessagesManager {

    fileprivate func testMessages() {
        let userMessage_shortPending = Message()
        userMessage_shortPending.type = .user
        userMessage_shortPending.message = "Hello 👋"
        userMessage_shortPending.status = .pending

        let agentMessage_fullMessageWithActions = Message()
        agentMessage_fullMessageWithActions.id = 0
        agentMessage_fullMessageWithActions.type = .agent
        agentMessage_fullMessageWithActions.title = "Welcome"
        agentMessage_fullMessageWithActions.message = "Here are some quick actions for more information about *Parley*"
        agentMessage_fullMessageWithActions.buttons = [
            createButton("Open app", "open-app://parley.nu"),
            createButton("Call us", "call://+31362022080"),
            createButton("Webuildapps", "https://webuildapps.com"),
        ]

        let agentMessage_messageWithCarouselSmall = Message()
        agentMessage_messageWithCarouselSmall.id = 1
        agentMessage_messageWithCarouselSmall.type = .agent
        agentMessage_messageWithCarouselSmall.agent = Agent(id: 10, name: "Webuildapps", avatar: "avatar.png")
        agentMessage_messageWithCarouselSmall
            .message = "Here are some quick actions for more information about *Parley*"
        agentMessage_messageWithCarouselSmall.buttons = [
            createButton("Home page", "https://www.parley.nu/"),
        ]

        agentMessage_messageWithCarouselSmall.carousel = [
            createMessage(
                "Parley libraries",
                "Parley provides open source SDK's for the Web, Android and iOS to easily integrate it with any platform.\n\nThe chat is fully customisable.",
                nil,
                [
                    createButton("Android SDK", "https://github.com/parley-messaging/android-library"),
                    createButton("iOS SDK", "https://github.com/parley-messaging/ios-library"),
                ]
            ),
            createMessage(nil, nil, "https://www.parley.nu/images/tab1_mobile.png", [
                createButton("Web documentation", "https://developers.parley.nu/docs/introduction"),
                createButton("Android documentation", "https://developers.parley.nu/docs/introduction-1"),
                createButton("iOS documentation", "https://developers.parley.nu/docs/introduction-2"),
            ]),
        ]

        let agentMessage_messageWithCarouselImages = Message()
        agentMessage_messageWithCarouselImages.id = 2
        agentMessage_messageWithCarouselImages.type = .agent
        agentMessage_messageWithCarouselImages.agent = Agent(id: 10, name: "Webuildapps", avatar: "avatar.png")
        agentMessage_messageWithCarouselImages.buttons = [
            createButton("Home page", "https://www.parley.nu/"),
        ]

        agentMessage_messageWithCarouselImages.carousel = [
            createMessage(nil, nil, "https://www.parley.nu/images/tab2.png", nil),
            createMessage(nil, nil, "https://www.parley.nu/images/tab1_mobile.png", nil),
            createMessage(nil, nil, "https://parley.nu/images/tab6.png", nil),
            createMessage(
                nil,
                nil,
                "http://www.socialmediatoolvergelijken.nl/tools/tracebuzz/img/tracebuzz_1.png",
                nil
            ),
        ]

        originalMessages.removeAll()
//        originalMessages.append(userMessage_shortPending) // Will be send
//        originalMessages.append(agentMessage_fullMessageWithActions)
        originalMessages.append(agentMessage_messageWithCarouselSmall)
//        originalMessages.append(agentMessage_messageWithCarouselImages)
    }

    fileprivate func createMessage(
        _ title: String?,
        _ message: String?,
        _ image: String?,
        _ buttons: [MessageButton]?
    ) -> Message {
        let m = Message()
        m.type = .agent
        m.title = title
        m.message = message
        m.buttons = buttons
        return m
    }

    fileprivate func createButton(_ title: String, _ payload: String) -> MessageButton {
        MessageButton(title: title, payload: payload)
    }
}
#endif

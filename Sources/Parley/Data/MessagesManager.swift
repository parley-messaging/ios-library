import Foundation
import UIKit

protocol MessagesManagerProtocol: AnyObject {
    var messages: [Message] { get }
    var pendingMessages: [Message] { get }
    var lastSentMessage: Message? { get }
    var stickyMessage: String? { get }

    func loadCachedData()
    func clear()
    func canLoadMore() -> Bool
    func handle(_ messageCollection: MessageCollection, _ handleType: MessagesManager.HandleType)
    func update(_ message: Message)
    func add(_ message: Message) -> [IndexPath]
    func addTypingMessage() -> [IndexPath]
    func getOldestMessage() -> Message?
    func removeTypingMessage() -> [IndexPath]?
}

final class MessagesManager: MessagesManagerProtocol {

    enum HandleType {
        case all
        case before
        case after
    }

    private var originalMessages: [Message] = []
    private(set) var messages: [Message] = []

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
        messages.first(where: {
            switch $0.type {
            case .agent, .systemMessageAgent, .user, .systemMessageUser:
                true
            default:
                false
            }
        })
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

        formatMessages()
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

        formatMessages()
    }

    private func updateWelcomeMessage(_ message: String?) {
        welcomeMessage = message
        if let welcomeMessage = message {
            keyValueDataSource?.set(welcomeMessage, forKey: kParleyCacheKeyMessageInfo)
        } else {
            keyValueDataSource?.removeObject(forKey: kParleyCacheKeyMessageInfo)
        }
    }

    func add(_ message: Message) -> [IndexPath] {
        guard !originalMessages.contains(message) else { return [] }

        let lastIndex = lastMessage()?.index
        var addIndex = lastIndex ?? 0
        var indexPaths: [IndexPath] = []

        if isFirstMessageOfToday(message) {
            let dateIndex = lastIndex == nil ? 0 : addIndex + 1
            indexPaths.append(IndexPath(row: dateIndex, section: 0))
            let dateMessage = createDateMessage(message.time ?? Date())
            messages.insert(dateMessage, at: dateIndex)
            addIndex = dateIndex + 1
        } else {
            addIndex += 1
        }

        indexPaths.append(IndexPath(row: addIndex, section: 0))
        messages.insert(message, at: addIndex)

        originalMessages.append(message)
        messageDataSource?.insert(message, at: 0)

        return indexPaths
    }

    private func lastMessage() -> (index: Int, message: Message)? {
        guard let lastMessage = messages.last else { return nil }
        var lastMessageIndex = messages.count - 1
        if lastMessage.type == .agentTyping {
            lastMessageIndex -= 1
        }
        return (lastMessageIndex, lastMessage)
    }

    private func isFirstMessageOfToday(_ message: Message) -> Bool {
        guard
            !messages.isEmpty,
            let (lastMessageIndex, lastMessage) = lastMessage() else { return true }

        guard let messageTime = message.time else { return false }

        let calendar = Calendar.current
        let lastDate = (messages.count > lastMessageIndex ? lastMessage.time : nil) ?? Date()
        let messageDatesMatch = calendar.isDate(lastDate, inSameDayAs: messageTime)
        let isFirstMessageAfterInfoMessage = messages.count > lastMessageIndex && lastMessage.type == .info

        return isFirstMessageAfterInfoMessage || !messageDatesMatch
    }

    func update(_ message: Message) {
        guard
            let originalMessagesIndex = originalMessages
                .firstIndex(where: { originalMessage in originalMessage.uuid == message.uuid }),
            let messagesIndex = messages.firstIndex(where: { currentMessage in currentMessage.uuid == message.uuid }) else { return }

        originalMessages[originalMessagesIndex] = message
        messages[messagesIndex] = message

        messageDataSource?.update(message)
    }

    /// Adds a typing indicator message
    /// - Returns: The `IndexPath`'s to add.
    func addTypingMessage() -> [IndexPath] {
        guard messages.last?.type != .agentTyping else { return [] }
        messages.append(createTypingMessage())
        return [IndexPath(row: messages.count - 1, section: 0)]
    }

    /// Removes the typing indicator message
    /// - Returns: the `IndexPath`'s to remove.
    func removeTypingMessage() -> [IndexPath]? {
        guard messages.last?.type == .agentTyping else { return nil }
        let tyingIndicatorIndex = messages.count - 1
        messages.removeLast()
        return [IndexPath(row: tyingIndicatorIndex, section: 0)]
    }

    func formatMessages() {
        var formattedMessages: [Message] = []

        if canLoadMore() {
            formattedMessages.append(createLoadingMessage())
        } else if let welcomeMessage = welcomeMessage {
            formattedMessages.append(createInfoMessages(welcomeMessage))
        }

        let messagesByDate = getMessagesByDate()

        for date in messagesByDate.keys.sorted(by: <) {
            for message in messagesByDate[date]!.sorted(by: <) {
                formattedMessages.append(message)
            }
        }

        if messages.last?.type == .agentTyping {
            formattedMessages.append(createTypingMessage())
        }

        messages = formattedMessages
    }

    private func getMessagesByDate() -> [Date: [Message]] {
        let calendar = Calendar.current

        var messagesByDate = [Date: [Message]]()
        for message in originalMessages {
            guard let time = message.time else { continue }
            let date: Date = calendar.startOfDay(for: time)
            if messagesByDate[date] == nil {
                messagesByDate[date] = [createDateMessage(date)]
            }
            messagesByDate[date]?.append(message)
        }

        return messagesByDate
    }

    private func createTypingMessage() -> Message {
        let typingMessage = Message()
        typingMessage.type = .agentTyping
        return typingMessage
    }

    private func createDateMessage(_ date: Date) -> Message {
        let dateMessage = Message()
        dateMessage.time = date
        dateMessage.message = date.asDate()
        dateMessage.type = .date
        return dateMessage
    }

    private func createInfoMessages(_ message: String) -> Message {
        let infoMessage = Message()
        infoMessage.type = .info
        infoMessage.message = message
        return infoMessage
    }

    private func createLoadingMessage() -> Message {
        let loadingMessage = Message()
        loadingMessage.type = .loading
        return loadingMessage
    }

    func canLoadMore() -> Bool {
        if let paging = paging, !paging.before.isEmpty {
            return true
        }

        return false
    }

    func clear() {
        originalMessages.removeAll()
        messages.removeAll()
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

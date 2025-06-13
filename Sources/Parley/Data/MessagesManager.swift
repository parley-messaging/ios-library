import Foundation
import UIKit

protocol MessagesManagerProtocol: AnyObject, Actor {
    var messages: [Message] { get }
    var pendingMessages: [Message] { get }
    var lastSentMessage: Message? { get }
    
    var welcomeMessage: String? { get }
    var stickyMessage: String? { get }

    func loadCachedData() async
    func clear() async
    func canLoadMore() -> Bool
    func handle(_ messageCollection: MessageCollection, _ handleType: MessagesManager.HandleType) async
    func update(_ message: Message) async
    func add(_ message: Message) async -> Bool
    func getOldestMessage() -> Message?
}

final actor MessagesManager: MessagesManagerProtocol {

    enum HandleType: CaseIterable {
        case all
        case before
        case after
    }

    private(set) var messages: [Message] = []
    private(set) var welcomeMessage: String?
    private(set) var stickyMessage: String?
    private(set) var paging: MessageCollection.Paging?
    private weak var messageDataSource: ParleyMessageDataSource?
    private weak var keyValueDataSource: ParleyKeyValueDataSource?

    /// The last messages that has been successfully sent.
    var lastSentMessage: Message? {
        messages
            .sorted(by: <)
            .last { message in
                message.remoteId != nil && message.sendStatus == .success
            }
    }

    /// The messages that are currently pending in a sorted way.
    var pendingMessages: [Message] {
        messages.sorted(by: <).reduce([Message]()) { partialResult, message in
            switch message.sendStatus {
            case .failed, .pending:
                partialResult + [message]
            default:
                partialResult
            }
        }
    }

    func getOldestMessage() -> Message? {
        messages.sorted(by: <).first(where: {
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

    func loadCachedData() async {
        messages.removeAll(keepingCapacity: true)

        if let cachedMessages = await messageDataSource?.all() {
            messages
                .append(
                    contentsOf: cachedMessages
                        .sorted(by: <)
                ) // When receiving them from cached, they could be sorted differently
        }

        stickyMessage = nil
        welcomeMessage = await keyValueDataSource?.string(forKey: kParleyCacheKeyMessageInfo)

        if let cachedPagingData = await keyValueDataSource?.data(forKey: kParleyCacheKeyPaging) {
            let storedCollection = try? CodableHelper.shared.decode(StoredMessageCollection.Paging.self, from: cachedPagingData)
            paging = storedCollection?.toDomainModel()
        } else {
            paging = nil
        }
    }

    func handle(_ messageCollection: MessageCollection, _ handleType: HandleType) async {
        let newMessages = messageCollection.messages.filter { message in
            if messages.contains(where: { $0.id == message.id }) {
                return false
            }
            return true
        }.sorted(by: <) // By default backend sorts them the other way around (initial retrieval and findAfter)

        switch handleType {
        case .before:
            messages.insert(contentsOf: newMessages, at: .zero)
        case .all, .after:
            let pendingMessages = pendingMessages
            messages.removeAll { message -> Bool in
                message.sendStatus == .pending || message.sendStatus == .failed
            }

            messages.append(contentsOf: newMessages)
            messages.append(contentsOf: pendingMessages)
        }

        await messageDataSource?.save(messages)
        stickyMessage = messageCollection.stickyMessage
        await updateWelcomeMessage(messageCollection.welcomeMessage)

        if handleType != .after {
            paging = messageCollection.paging
            let storedPaging = StoredMessageCollection.from(messageCollection)
            if let messages = try? CodableHelper.shared.toJSONString(storedPaging) {
                await keyValueDataSource?.set(messages, forKey: kParleyCacheKeyPaging)
            } else {
                await keyValueDataSource?.removeObject(forKey: kParleyCacheKeyPaging)
            }
        }
    }

    private func updateWelcomeMessage(_ message: String?) async {
        welcomeMessage = message
        if let welcomeMessage = message {
            await keyValueDataSource?.set(welcomeMessage, forKey: kParleyCacheKeyMessageInfo)
        } else {
            await keyValueDataSource?.removeObject(forKey: kParleyCacheKeyMessageInfo)
        }
    }

    func add(_ message: Message) async -> Bool {
        guard !messages.contains(message) else { return false }
        
        messages.append(message)
        await messageDataSource?.insert(message, at: 0)
        return true
    }

    func update(_ message: Message) async {
        guard let originalMessagesIndex = messages .firstIndex(where: { $0.id == message.id }) else { return }

        messages[originalMessagesIndex] = message
        await messageDataSource?.update(message)
    }

    func canLoadMore() -> Bool {
        if let paging = paging, !paging.before.isEmpty {
            return true
        }

        return false
    }

    func clear() async {
        messages.removeAll()
        welcomeMessage = nil
        stickyMessage = nil
        paging = nil
        await loadCachedData()
    }
}

#if DEBUG
// MARK: - Only used for testing
extension MessagesManager {

    fileprivate func testMessages() {
        let userMessage_shortPending = Message.newTextMessage("Hello 👋🏻", type: .user, sendStatus: .pending)

        let agentMessage_fullMessageWithActions = Message.exsisting(
            remoteId: 0,
            localId: UUID(),
            time: Date(),
            title: "Welcome",
            message: "Here are some quick actions for more information about *Parley*",
            responseInfoType: nil,
            media: nil,
            buttons: [
                createButton("Open app", "open-app://parley.nu"),
                createButton("Call us", "call://+31362022080"),
                createButton("Webuildapps", "https://webuildapps.com")
            ],
            carousel: [],
            quickReplies: [],
            type: .agent,
            status: nil,
            sendStatus: .success,
            agent: nil,
            referrer: nil
        )

        let agentMessage_messageWithCarouselSmall = Message.exsisting(
            remoteId: 1,
            localId: UUID(),
            time: Date(),
            title: nil,
            message: "Here are some quick actions for more information about *Parley*",
            responseInfoType: nil,
            media: nil,
            buttons: [
                createButton("Home page", "https://www.parley.nu/")
            ],
            carousel: [
                createCarouselMessage(
                    "Parley libraries",
                    "Parley provides open source SDK's for the Web, Android and iOS to easily integrate it with any platform.\n\nThe chat is fully customisable.",
                    nil,
                    [
                        createButton("Android SDK", "https://github.com/parley-messaging/android-library"),
                        createButton("iOS SDK", "https://github.com/parley-messaging/ios-library"),
                    ]
                ),
                createCarouselMessage(nil, nil, "https://www.parley.nu/images/tab1_mobile.png", [
                    createButton("Web documentation", "https://developers.parley.nu/docs/introduction"),
                    createButton("Android documentation", "https://developers.parley.nu/docs/introduction-1"),
                    createButton("iOS documentation", "https://developers.parley.nu/docs/introduction-2"),
                ])
            ],
            quickReplies: [],
            type: .agent,
            status: nil,
            sendStatus: .success,
            agent: Agent(id: 10, name: "Webuildapps", avatar: "avatar.png"),
            referrer: nil
        )

        let agentMessage_messageWithCarouselImages = Message.exsisting(
            remoteId: 2,
            localId: UUID(),
            time: Date(),
            title: nil,
            message: nil,
            responseInfoType: nil,
            media: nil,
            buttons: [
                createButton("Home page", "https://www.parley.nu/"),
            ],
            carousel: [
                createCarouselMessage(nil, nil, "https://www.parley.nu/images/tab2.png", nil),
                createCarouselMessage(nil, nil, "https://www.parley.nu/images/tab1_mobile.png", nil),
                createCarouselMessage(nil, nil, "https://parley.nu/images/tab6.png", nil),
                createCarouselMessage(
                    nil,
                    nil,
                    "http://www.socialmediatoolvergelijken.nl/tools/tracebuzz/img/tracebuzz_1.png",
                    nil
                )
            ], quickReplies: [],
            type: .agent,
            status: nil,
            sendStatus: .success,
            agent: Agent(id: 10, name: "Webuildapps", avatar: "avatar.png"),
            referrer: nil
        )
        
        messages.removeAll()
//      messages.append(userMessage_shortPending) // Will be sent
//        messages.append(agentMessage_fullMessageWithActions)
        messages.append(agentMessage_messageWithCarouselSmall)
//        messages.append(agentMessage_messageWithCarouselImages)
    }

    fileprivate func createCarouselMessage(
        _ title: String?,
        _ message: String?,
        _ image: String?,
        _ buttons: [MessageButton]?
    ) -> Message {
        Message.exsisting(
            remoteId: Int.random(in: 1_000...10_000),
            localId: UUID(),
            time: Date(),
            title: title,
            message: message,
            responseInfoType: nil,
            media: nil,
            buttons: buttons ?? [],
            carousel: [],
            quickReplies: [],
            type: .agent,
            status: nil,
            sendStatus: .success,
            agent: nil,
            referrer: nil
        )
    }

    fileprivate func createButton(_ title: String, _ payload: String) -> MessageButton {
        MessageButton(title: title, payload: payload)
    }
}
#endif

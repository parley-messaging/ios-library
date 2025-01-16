import Foundation

@testable import Parley

final class MessagesManagerStub: MessagesManagerProtocol {
    
    // MARK: Stub Configuration
    private var canLoadMoreMessages: Bool = false
    
    // MARK: MessagesManagerProtocol Properties
    var latestMessage: Message? { nil }
    var welcomeMessage: String?
    
    var messages: [Message] = [Message.makeTestData(), Message.makeTestData()]

    var pendingMessages: [Message] = []

    var lastSentMessage: Message?

    var stickyMessage: String?
}

// MARK: Methods
extension MessagesManagerStub {

    func loadCachedData() {}

    func clear() {}

    func canLoadMore() -> Bool {
        canLoadMoreMessages
    }

    func handle(_ messageCollection: MessageCollection, _ handleType: MessagesManager.HandleType) {}

    func update(_ message: Message) {}

    func add(_ message: Message) -> Bool {
        return false
    }

    func getOldestMessage() -> Message? {
        messages.first
    }

    func removeTypingMessage() -> [IndexPath]? {
        nil
    }
}


// MARK: Configuration
extension MessagesManagerStub {
    
    func whenCanLoadMore(_ result: Bool) {
        canLoadMoreMessages = result
    }
}

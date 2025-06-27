import Foundation
@testable import Parley

final actor MessagesManagerStub: MessagesManagerProtocol {
    
    // MARK: Stub Configuration
    private var canLoadMoreMessages: Bool = false
    
    // MARK: MessagesManagerProtocol Properties
    var latestMessage: Message? { nil }
    private(set) var welcomeMessage: String?
    
    private(set) var messages: [Message] = [Message.makeTestData(), Message.makeTestData()]

    private(set) var pendingMessages: [Message] = []

    private(set) var lastSentMessage: Message?

    private(set) var stickyMessage: String?
}

// MARK: Setters
extension MessagesManagerStub {
    
    func setWelcomeMessage(_ message: String?) {
        self.welcomeMessage = message
    }
    
    func setMessages(_ messages: [Message]) {
        self.messages = messages
    }
    
    func setPendingMessages(_ messages: [Message]) {
        self.pendingMessages = messages
    }
    
    func setLastSentMessage(_ messages: Message?) {
        self.lastSentMessage = messages
    }
    
    func setStickyMessage(_ message: String?) {
        self.stickyMessage = message
    }
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
        return true
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

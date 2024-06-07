import Foundation

@testable import Parley

final class MessagesManagerStub: MessagesManagerProtocol {
    var messages: [Message] = [Message.makeTestData(), Message.makeTestData()]

    var pendingMessages: [Message] = []

    var lastSentMessage: Message?

    var stickyMessage: String?

    func loadCachedData() {}

    func clear() {}

    func canLoadMore() -> Bool {
        false
    }

    func handle(_ messageCollection: MessageCollection, _ handleType: MessagesManager.HandleType) {}

    func update(_ message: Message) {}

    func add(_ message: Message) -> [IndexPath] {
        []
    }

    func addTypingMessage() -> [IndexPath] {
        []
    }

    func getOldestMessage() -> Message? {
        nil
    }

    func removeTypingMessage() -> [IndexPath]? {
        nil
    }
}

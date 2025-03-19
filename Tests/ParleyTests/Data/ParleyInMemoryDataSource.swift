import Foundation
@testable import Parley

final actor ParleyMessageDataSourceMock: ParleyMessageDataSource {

    private var messages = [Message]()

    func clear() -> Bool {
        messages.removeAll()
        return true
    }

    func all() -> [Message]? {
        messages
    }

    func save(_ messages: [Message]) {
        self.messages.append(contentsOf: messages)
    }

    func insert(_ message: Message, at index: Int) {
        messages.insert(message, at: index)
    }

    func update(_ message: Message) {
        guard
            let index = messages.firstIndex(where: {
                $0.remoteId == message.remoteId || $0.id == message.id
            }) else { return }
        messages[index] = message
    }
}

import Foundation

public class ParleyEncryptedMessageDataSource {

    private let store: ParleyEncryptedStore

    public enum Directory {
        case `default`
        case custom(String)

        var path: String {
            switch self {
            case .default:
                kParleyCacheMessagesDirectory
            case .custom(let string):
                string
            }
        }
    }

    public init(
        crypter: ParleyCrypter,
        directory: Directory = .default,
        fileManager: FileManager = .default
    ) throws {
        store = try ParleyEncryptedStore(
            crypter: crypter,
            directory: directory.path,
            fileManager: fileManager
        )
    }
}

extension ParleyEncryptedMessageDataSource: ParleyMessageDataSource {

    public func clear() -> Bool {
        store.clear()
    }

    public func all() -> [Message]? {
        guard let jsonData = store.data(forKey: kParleyCacheKeyMessages) else { return nil }
        return try? CodableHelper.shared.decode([Message].self, from: jsonData)
    }

    public func save(_ messages: [Message]) {
        if let messages = try? CodableHelper.shared.toJSONString(messages) {
            store.set(messages, forKey: kParleyCacheKeyMessages)
        } else {
            store.removeObject(forKey: kParleyCacheKeyMessages)
        }
    }

    public func insert(_ message: Message, at index: Int) {
        var messages: [Message] = all() ?? []
        messages.insert(message, at: index)

        save(messages)
    }

    public func update(_ message: Message) {
        var messages: [Message] = all() ?? []

        guard
            let index = messages.firstIndex(where: { cachedMessage in
                cachedMessage.id == message.id || cachedMessage.uuid == message.uuid
            }) else { return }

        messages[index] = message

        save(messages)
    }
}

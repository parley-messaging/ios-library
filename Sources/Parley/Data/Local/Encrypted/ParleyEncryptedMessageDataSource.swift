import Foundation

public final class ParleyEncryptedMessageDataSource: Sendable {

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
        directory: Directory = .default
    ) throws {
        store = try ParleyEncryptedStore(
            crypter: crypter,
            directory: directory.path,
            fileManager: .default
        )
    }
}

extension ParleyEncryptedMessageDataSource: ParleyMessageDataSource {

    public func clear() async -> Bool {
        await store.clear()
    }

    public func all() async -> [Message]? {
        guard
            let jsonData = await store.data(forKey: kParleyCacheKeyMessages),
            let remoteMessage = try? CodableHelper.shared.decode([StoredMessage].self, from: jsonData)
        else { return nil }
        return remoteMessage.map { $0.toDomainModel() }
    }

    public func save(_ messages: [Message]) async {
        let messagesToStore = messages.map(StoredMessage.init(message:))
        if let messages = try? CodableHelper.shared.toJSONString(messagesToStore) {
            await store.set(messages, forKey: kParleyCacheKeyMessages)
        } else {
            await store.removeObject(forKey: kParleyCacheKeyMessages)
        }
    }

    public func insert(_ message: Message, at index: Int) async {
        var messages: [Message] = await all() ?? []
        messages.insert(message, at: index)

        await save(messages)
    }

    public func update(_ message: Message) async {
        var messages: [Message] = await all() ?? []

        guard
            let index = messages.firstIndex(where: { cachedMessage in
                cachedMessage.remoteId == message.remoteId || cachedMessage.localId == message.localId
            }) else { return }

        messages[index] = message

        await save(messages)
    }
}

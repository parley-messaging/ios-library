@preconcurrency import Foundation

public final class ParleyEncryptedKeyValueDataSource: Sendable {

    private let store: ParleyEncryptedStore

    public enum Directory {
        case `default`
        case custom(String)

        var path: String {
            switch self {
            case .default:
                kParleyCacheDirectory
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

extension ParleyEncryptedKeyValueDataSource: ParleyKeyValueDataSource {

    @discardableResult
    public func clear() async -> Bool {
        await store.clear()
    }

    public func string(forKey key: String) async -> String? {
        await store.string(forKey: key)
    }

    public func data(forKey key: String) async -> Data? {
        await store.data(forKey: key)
    }

    @discardableResult
    public func set(_ string: String, forKey key: String) async -> Bool {
        await store.set(string, forKey: key)
    }

    @discardableResult
    public func set(_ data: Data, forKey key: String) async -> Bool {
        await store.set(data, forKey: key)
    }

    @discardableResult
    public func removeObject(forKey key: String) async -> Bool {
        await store.removeObject(forKey: key)
    }
}

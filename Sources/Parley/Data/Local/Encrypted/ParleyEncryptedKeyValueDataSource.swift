import Foundation

public class ParleyEncryptedKeyValueDataSource {
    
    private let store: ParleyEncryptedStore
    
    public enum Directory {
        case `default`
        case custom(String)
        
        var path: String {
            switch self {
            case .default:
                return kParleyCacheDirectory
            case .custom(let string):
                return string
            }
        }
    }
    
    public init(
        crypter: ParleyCrypter,
        directory: Directory = .default,
        fileManager: FileManager = .default
    ) throws {
        self.store = try ParleyEncryptedStore(
            crypter: crypter,
            directory: directory.path,
            fileManager: fileManager
        )
    }
}

extension ParleyEncryptedKeyValueDataSource: ParleyKeyValueDataSource {
    
    @discardableResult
    public func clear() -> Bool {
        store.clear()
    }
    
    public func string(forKey key: String) -> String? {
        store.string(forKey: key)
    }
    
    public func data(forKey key: String) -> Data? {
        store.data(forKey: key)
    }
    
    @discardableResult
    public func set(_ string: String, forKey key: String) -> Bool {
        store.set(string, forKey: key)
    }
    
    @discardableResult
    public func set(_ data: Data, forKey key: String) -> Bool {
        store.set(data, forKey: key)
    }
    
    @discardableResult
    public func removeObject(forKey key: String) -> Bool {
        store.removeObject(forKey: key)
    }
}

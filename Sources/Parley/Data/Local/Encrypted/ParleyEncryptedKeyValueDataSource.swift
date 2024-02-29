import Foundation

public class ParleyEncryptedKeyValueDataSource {
    
    internal let crypter: ParleyCrypter
    internal let destination: URL
    internal let fileManager: FileManager
    
    public init(key: String) throws {
        self.crypter = try ParleyCrypter(key: key)
        self.fileManager = FileManager.default
        self.destination = fileManager.temporaryDirectory.appendingPathComponent(kParleyCacheDirectory)
        try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
    }
    
    internal func destination(forKey key: String) -> URL {
        destination.appendingPathComponent(key)
    }
}

extension ParleyEncryptedKeyValueDataSource: ParleyKeyValueDataSource {
    
    @discardableResult
    public func clear() -> Bool {
        do {
            try fileManager.removeItem(at: destination)
            try fileManager.createDirectory(at: destination, withIntermediateDirectories: true, attributes: nil)
            
            return true
        } catch {
            return false
        }
    }
    
    public func string(forKey key: String) -> String? {
        guard let data = data(forKey: key) else { return nil }
        return String(decoding: data, as: UTF8.self)
    }
    
    public func data(forKey key: String) -> Data? {
        let destination = destination(forKey: key)
        
        do {
            let encrypted = try Data(contentsOf: destination)
            
            return try crypter.decrypt(encrypted)
        } catch {
            return nil
        }
    }
    
    @discardableResult public func set(_ string: String?, forKey key: String) -> Bool {
        if let string = string {
            if let data = string.data(using: .utf8) {
                return set(data, forKey: key)
            } else {
                return false
            }
        } else {
            return removeObject(forKey: key)
        }
    }
    
    @discardableResult public func set(_ data: Data?, forKey key: String) -> Bool {
        if let data = data {
            let destination = destination(forKey: key)
            
            do {
                let encrypted = try crypter.encrypt(data)
                try encrypted.write(to: destination)
                
                return true
            } catch {
                return false
            }
        } else {
            return removeObject(forKey: key)
        }
    }
    
    @discardableResult public func removeObject(forKey key: String) -> Bool {
        let destination = destination(forKey: key)
        
        do {
            try fileManager.removeItem(at: destination)
            
            return true
        } catch {
            return false
        }
    }
}

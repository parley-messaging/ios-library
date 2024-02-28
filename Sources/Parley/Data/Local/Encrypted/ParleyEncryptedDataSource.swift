import Foundation
import UIKit

public class ParleyEncryptedDataSource: ParleyDataSource {
    
    private let crypter: ParleyCrypter
    private let destination: URL
    private let fileManager: FileManager
    
    public init(key: String) throws {
        self.crypter = try ParleyCrypter(key: key)
        self.fileManager = FileManager.default
        self.destination = fileManager.temporaryDirectory.appendingPathComponent(kParleyCacheDirectory)
        try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
    }
    
    @discardableResult public func clear() -> Bool {
        do {
            try fileManager.removeItem(at: self.destination)
            try fileManager.createDirectory(at: self.destination, withIntermediateDirectories: true, attributes: nil)
            
            return true
        } catch {
            return false
        }
    }
    
    private func destination(forKey key: String) -> URL {
        return self.destination.appendingPathComponent(key)
    }
}

extension ParleyEncryptedDataSource: ParleyKeyValueDataSource {
    
    public func string(forKey key: String) -> String? {
        
        if let data = self.data(forKey: key) {
            return String(decoding: data, as: UTF8.self)
        }
        
        return nil
    }
    
    public func data(forKey key: String) -> Data? {
        let destination = self.destination(forKey: key)
        
        do {
            let encrypted = try Data(contentsOf: destination)
            
            return try self.crypter.decrypt(encrypted)
        } catch {
            return nil
        }
    }
    
    @discardableResult public func set(_ string: String?, forKey key: String) -> Bool {
        if let string = string {
            if let data = string.data(using: .utf8) {
                return self.set(data, forKey: key)
            } else {
                return false
            }
        } else {
            return self.removeObject(forKey: key)
        }
    }
    
    @discardableResult public func set(_ data: Data?, forKey key: String) -> Bool {
        if let data = data {
            let destination = self.destination(forKey: key)
            
            do {
                let encrypted = try self.crypter.encrypt(data)
                try encrypted.write(to: destination)
                
                return true
            } catch {
                return false
            }
        } else {
            return self.removeObject(forKey: key)
        }
    }
    
    @discardableResult public func removeObject(forKey key: String) -> Bool {
        let destination = self.destination(forKey: key)
        
        do {
            try fileManager.removeItem(at: destination)
            
            return true
        } catch {
            return false
        }
    }
}

extension ParleyEncryptedDataSource: ParleyMessageDataSource {
    
    public func all() -> [Message]? {
        guard  let jsonData = self.data(forKey: kParleyCacheKeyMessages) else { return nil }
        return try? CodableHelper.shared.decode([Message].self, from: jsonData)
    }
    
    public func save(_ messages: [Message]) {
        let messages = try? CodableHelper.shared.toJSONString(messages)
        self.set(messages, forKey: kParleyCacheKeyMessages)
    }
    
    public func insert(_ message: Message, at index: Int) {
        var messages: [Message] = self.all() ?? []
        messages.insert(message, at: index)
        
        self.save(messages)
    }
    
    public func update(_ message: Message) {
        var messages: [Message] = self.all() ?? []
        guard let index = messages.firstIndex(where: { cachedMessage in cachedMessage.id == message.id || cachedMessage.uuid == message.uuid }) else { return }

        messages[index] = message
        
        self.save(messages)
    }
}

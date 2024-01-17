import Foundation
import UIKit

public class ParleyEncryptedDataSource: ParleyDataSource {
    
    private let crypter: ParleyCrypter
    private let destination: URL
    
    public init (key: Data) throws {
        self.crypter = try ParleyCrypter(key: key)
        
        self.destination = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(kParleyCacheDirectory)
        try? FileManager.default.createDirectory(at: self.destination, withIntermediateDirectories: true, attributes: nil)
    }
    
    @discardableResult public func clear() -> Bool {
        do {
            try FileManager.default.removeItem(at: self.destination)
            try FileManager.default.createDirectory(at: self.destination, withIntermediateDirectories: true, attributes: nil)
            
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
            try FileManager.default.removeItem(at: destination)
            
            return true
        } catch {
            return false
        }
    }
}

extension ParleyEncryptedDataSource: ParleyMessageDataSource {
    
    public func all() -> [Message]? {
        guard let jsonData = self.data(forKey: kParleyCacheKeyMessages),
              let messages = try? CodableHelper.shared.decode([Message].self, from: jsonData)
        else {
            return nil
        }

        messages.forEach { message in
            if message.type == .user, message.status == .pending, let uuid = message.uuid, let imageData = self.data(forKey: uuid), let imageUrl = message.imageURL {
                message.imageData = imageData
                
                switch ParleyImageType.map(from: imageUrl) {
                case .gif:
                    message.image = UIImage.gif(data: imageData)
                default:
                    message.image = UIImage(data: imageData)
                }
            }
        }

        return messages
    
    }
    
    public func save(_ messages: [Message]) {
        messages.forEach { message in
            if let uuid = message.uuid, message.type == .user, message.imageURL != nil {
                if message.status == .pending, let imageData = message.imageData {
                    self.set(imageData, forKey: uuid)
                } else {
                    self.removeObject(forKey: uuid)
                }
            }
        }
        
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

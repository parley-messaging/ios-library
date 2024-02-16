import Foundation
@testable import Parley

final class ParleyDataSourceMock: ParleyDataSource {

    private var messages = [Message]()
    private var dataDict = [String: Any]()
    
    func clear() -> Bool {
        messages.removeAll()
        return messages.isEmpty
    }
    
    func string(forKey key: String) -> String? {
        dataDict[key] as? String
    }
    
    func data(forKey key: String) -> Data? {
        dataDict[key] as? Data
    }
    
    func set(_ string: String?, forKey key: String) -> Bool {
        guard dataDict[key] == nil else { return false }
        dataDict[key] = string
        return true
    }
    
    func set(_ data: Data?, forKey key: String) -> Bool {
        guard dataDict[key] == nil else { return false }
        dataDict[key] = data
        return true
    }
    
    func removeObject(forKey key: String) -> Bool {
        dataDict[key] = nil
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
        guard let index = messages.firstIndex(where: {
            $0.id == message.id || $0.uuid == message.uuid
        }) else { return }
        messages[index] = message
    }
}

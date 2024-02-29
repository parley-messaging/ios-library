import Foundation

public class ParleyEncryptedMessageDataSource: ParleyEncryptedKeyValueDataSource, ParleyMessageDataSource {
    
    public func all() -> [Message]? {
        guard  let jsonData = data(forKey: kParleyCacheKeyMessages) else { return nil }
        return try? CodableHelper.shared.decode([Message].self, from: jsonData)
    }
    
    public func save(_ messages: [Message]) {
        let messages = try? CodableHelper.shared.toJSONString(messages)
        set(messages, forKey: kParleyCacheKeyMessages)
    }
    
    public func insert(_ message: Message, at index: Int) {
        var messages: [Message] = all() ?? []
        messages.insert(message, at: index)
        
        save(messages)
    }
    
    public func update(_ message: Message) {
        var messages: [Message] = all() ?? []
        guard let index = messages.firstIndex(where: { cachedMessage in
            cachedMessage.id == message.id || cachedMessage.uuid == message.uuid
        })  else { return }
        
        messages[index] = message
        
        save(messages)
    }
}

import Foundation

class MessagesManager {
    
    enum HandleType {
        case all
        case before
        case after
    }
    
    private(set) var originalMessages: [Message] = []
    private(set) var messages: [Message] = []

    private(set) var welcomeMessage: String?
    private(set) var stickyMessage: String?
    private(set) var paging: MessageCollection.Paging?
    
    var lastMessage: Message? {
        get {
            return self.originalMessages.first { message in
                return message.id != nil && message.status == .success
            }
        }
    }
    var pendingMessages: [Message] {
        get {
            originalMessages.reduce([Message]()) { partialResult, message in
                switch message.status {
                case .failed, .pending:
                    return partialResult + [message]
                default:
                    return partialResult
                }
            }
        }
    }

    internal func loadCachedData() {
        self.originalMessages.removeAll()
        
        if let cachedMessages = Parley.shared.dataSource?.all() {
            self.originalMessages.append(contentsOf: cachedMessages)
        }
        
        pendingMessages.filter({ $0.mediaSendRequest != nil }).forEach { message in
            if let data = message.mediaSendRequest?.image {
                message.image = UIImage(data: data)
            }
        }
        
        self.stickyMessage = nil
        self.welcomeMessage = Parley.shared.dataSource?.string(forKey: kParleyCacheKeyMessageInfo)
        
        if let cachedPaging = Parley.shared.dataSource?.string(forKey: kParleyCacheKeyPaging) {
            self.paging = MessageCollection.Paging(JSONString: cachedPaging)
        } else {
            self.paging = nil
        }

        self.formatMessages()
    }
    
    internal func handle(_ messageCollection: MessageCollection, _ handleType: HandleType) {
        switch handleType {
        case .before:
            self.originalMessages.append(contentsOf: messageCollection.messages)
        case .all, .after:
            let pendingMessages = self.pendingMessages
            self.originalMessages.removeAll { message -> Bool in
                return message.status == .pending || message.status == .failed
            }
            
            self.originalMessages.insert(contentsOf: messageCollection.messages, at: 0)
            self.originalMessages.insert(contentsOf: pendingMessages, at: 0)
        }
        
        Parley.shared.dataSource?.save(self.originalMessages)
        
        self.stickyMessage = messageCollection.stickyMessage
        
        self.welcomeMessage = messageCollection.welcomeMessage
        Parley.shared.dataSource?.set(self.welcomeMessage, forKey: kParleyCacheKeyMessageInfo)

        if handleType != .after {
            self.paging = messageCollection.paging
            Parley.shared.dataSource?.set(self.paging?.toJSONString(), forKey: kParleyCacheKeyPaging)
        }
        
        self.formatMessages()
    }
    
    internal func add(_ message: Message) -> [IndexPath] {
        if self.originalMessages.contains(message) {
            return []
        }
        
        var indexPaths: [IndexPath] = []
        
        let index = self.messages.first?.type == .agentTyping ? 1 : 0
        if let globalMessageTime = messages[index].time,
           let messageTime = message.time,
           self.messages.count == 0 || (self.messages.count > index && (self.messages[index].type == .info || !Calendar.current.isDate(globalMessageTime, inSameDayAs: messageTime))) {
            let dateMessage = Message()
            dateMessage.time = message.time
            dateMessage.type = .date
            
            indexPaths.append(IndexPath(row: index + 1, section: 0))
            self.messages.insert(dateMessage, at: index)
        }
        
        indexPaths.append(IndexPath(row: index, section: 0))
        self.messages.insert(message, at: index)
        
        self.originalMessages.insert(message, at: 0)
        Parley.shared.dataSource?.insert(message, at: 0)
        
        return indexPaths
    }

    internal func update(_ message: Message) {
        guard let originalMessagesIndex = originalMessages.firstIndex(where: { originalMessage in originalMessage.uuid == message.uuid }) else {
            return
        }
        guard let messagesIndex = messages.firstIndex(where: { currentMessage in currentMessage.uuid == message.uuid }) else {
            return
        }

        self.originalMessages[originalMessagesIndex] = message
        self.messages[messagesIndex] = message
        
        Parley.shared.dataSource?.update(message)
    }
    
    internal func addTypingMessage() -> [IndexPath] {
        let typingMessage = Message()
        typingMessage.type = .agentTyping
        
        self.messages.insert(typingMessage, at: 0)
        
        return [IndexPath(row: 0, section: 0)]
    }
    
    internal func removeTypingMessage() -> [IndexPath]? {
        if self.messages.first?.type == .agentTyping {
            self.messages.remove(at: 0)
            
            return [IndexPath(row: 0, section: 0)]
        }
        
        return nil
    }
    
    internal func formatMessages() {
        var formattedMessages: [Message] = []
    
        var lastDate = (originalMessages.first?.time ?? Date()).asDate()
        for (index, message) in originalMessages.enumerated() {
            if message.time?.asDate() != lastDate {
                let dateMessage = Message()
                dateMessage.time = message.time
                dateMessage.message = lastDate
                dateMessage.type = .date
                
                formattedMessages.append(dateMessage)
                
                lastDate = message.time?.asDate() ?? ""
            }
            
            formattedMessages.append(message)
            
            if index == originalMessages.count - 1 {
                let dateMessage = Message()
                dateMessage.time = message.time
                dateMessage.message = lastDate
                dateMessage.type = .date
                
                formattedMessages.append(dateMessage)
            }
        }
        
        if canLoadMore() {
            let loadingMessage = Message()
            loadingMessage.type = .loading
            
            formattedMessages.append(loadingMessage)
        } else if let welcomeMessage = self.welcomeMessage {
            let infoMessage = Message()
            infoMessage.type = .info
            infoMessage.message = welcomeMessage
            
            formattedMessages.append(infoMessage)
        }

        self.messages = formattedMessages
    }

    internal func canLoadMore() -> Bool {
        if let paging = self.paging, let before = paging.before, !before.isEmpty {
            return true
        }
        
        return false
    }

    internal func clear() {
        originalMessages.removeAll()
        messages.removeAll()
        welcomeMessage = nil
        stickyMessage = nil
        paging = nil
        loadCachedData()
    }
}

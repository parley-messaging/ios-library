import Foundation
import UIKit

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
        
        // Attach media as image if needed. Used when messages with media have a pending state which may be send at a later moment.
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
            dateMessage.message = message.time?.asDate()
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
    
        var lastDate = originalMessages.first?.time
        for (index, message) in originalMessages.enumerated() {
            if message.time?.asDate() != lastDate?.asDate() {
                // This message is older than the previous ones: Inserting date header
                // print("Adding date before: \(message.time!) - \(lastDate)")
                let dateMessage = Message()
                dateMessage.time = lastDate
                dateMessage.message = lastDate?.asDate()
                dateMessage.type = .date
                
                formattedMessages.append(dateMessage)
                
                lastDate = message.time
            }
            
            // print("Adding message for: \(message.time!)")
            formattedMessages.append(message)
            
            if index == originalMessages.count - 1 {
                // This is the first message in the chat: Show this date as header (`lastDate` is same day here, but that is the date of the latest message of that day)
                // print("Adding date after:  \(message.time!) - \(lastDate)")
                let dateMessage = Message()
                dateMessage.time = message.time
                dateMessage.message = message.time?.asDate()
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
    
    /// Only used for testing
    private func testMessages() {
        let userMessage_shortPending = Message()
        userMessage_shortPending.type = .user
        userMessage_shortPending.message = "Hello 👋"
        userMessage_shortPending.status = .pending
        
        let agentMessage_fullMessageWithActions = Message()
        agentMessage_fullMessageWithActions.id = 0
        agentMessage_fullMessageWithActions.type = .agent
        agentMessage_fullMessageWithActions.title = "Welcome"
        agentMessage_fullMessageWithActions.message = "Here are some quick actions for more information about *Parley*"
        agentMessage_fullMessageWithActions.imageURL = URL(string: "https://www.tracebuzz.com/assets/images/parley-blog.jpg")
        agentMessage_fullMessageWithActions.buttons = [
            createButton("Open app", "open-app://parley.nu"),
            createButton("Call us", "call://+31362022080"),
            createButton("Webuildapps", "https://webuildapps.com")
        ]
        
        let agentMessage_messageWithCarouselSmall = Message()
        agentMessage_messageWithCarouselSmall.id = 1
        agentMessage_messageWithCarouselSmall.type = .agent
        agentMessage_messageWithCarouselSmall.agent = Agent()
        agentMessage_messageWithCarouselSmall.agent?.name = "Webuildapps"
        agentMessage_messageWithCarouselSmall.message = "Here are some quick actions for more information about *Parley*"
        agentMessage_messageWithCarouselSmall.imageURL = URL(string: "https://www.tracebuzz.com/assets/images/parley-blog.jpg")
        agentMessage_messageWithCarouselSmall.buttons = [
            createButton("Home page", "https://www.parley.nu/")
        ]
        
        agentMessage_messageWithCarouselSmall.carousel = [
            createMessage("Parley libraries", "Parley provides open source SDK's for the Web, Android and iOS to easily integrate it with any platform.\n\nThe chat is fully customisable.", nil, [
                createButton("Android SDK", "https://github.com/parley-messaging/android-library"),
                createButton("iOS SDK", "https://github.com/parley-messaging/ios-library")
            ]),
            createMessage(nil, nil, "https://www.parley.nu/images/tab1_mobile.png", [
                createButton("Web documentation", "https://developers.parley.nu/docs/introduction"),
                createButton("Android documentation", "https://developers.parley.nu/docs/introduction-1"),
                createButton("iOS documentation", "https://developers.parley.nu/docs/introduction-2")
            ]),
        ]
        
        let agentMessage_messageWithCarouselImages = Message()
        agentMessage_messageWithCarouselImages.id = 2
        agentMessage_messageWithCarouselImages.type = .agent
        agentMessage_messageWithCarouselImages.agent = Agent()
        agentMessage_messageWithCarouselImages.agent?.name = "Webuildapps"
        agentMessage_messageWithCarouselImages.imageURL = URL(string: "https://parley.nu/images/tab6.png")
        agentMessage_messageWithCarouselImages.buttons = [
            createButton("Home page", "https://www.parley.nu/")
        ]
        
        agentMessage_messageWithCarouselImages.carousel = [
            createMessage(nil, nil, "https://www.parley.nu/images/tab2.png", nil),
            createMessage(nil, nil, "https://www.parley.nu/images/tab1_mobile.png", nil),
            createMessage(nil, nil, "https://parley.nu/images/tab6.png", nil),
            createMessage(nil, nil, "http://www.socialmediatoolvergelijken.nl/tools/tracebuzz/img/tracebuzz_1.png", nil),
        ]
        
        originalMessages.removeAll()
//        originalMessages.append(userMessage_shortPending) // Will be send
//        originalMessages.append(agentMessage_fullMessageWithActions)
        originalMessages.append(agentMessage_messageWithCarouselSmall)
//        originalMessages.append(agentMessage_messageWithCarouselImages)
    }
    
    /// Only used for testing
    private func createMessage(_ title: String?, _ message: String?, _ image: String?, _ buttons: [MessageButton]?) -> Message {
        let m = Message()
        m.type = .agent
        m.title = title
        m.message = message
        if let image = image {
            m.imageURL = URL(string: image)
        }
        m.buttons = buttons
        return m
    }
    
    /// Only used for testing
    private func createButton(_ title: String, _ payload: String) -> MessageButton {
        let b = MessageButton()
        b.title = title
        b.payload = payload
        return b
    }
}

import Foundation

final class MessagesInteractor {
    
    private let presenter: MessagesPresenterProtocol
    private let messagesManager: MessagesManagerProtocol
    private let messageRepository: MessageRepositoryProtocol
    private let reachabilityProvider: ReachabilityProvider
    
    private(set) var agentTyping = false
    private(set) var isLoadingMessages = false
    private(set) var messages: ParleyChronologicalMessageCollection
    private(set) var isScrolledAtBottom = false
    
    private(set) var presentedQuickReplies: [String]?
    
    private var quickReplies: [String]? {
        guard let lastMessagePosistion = messages.lastPosistion() else { return nil }
        let message = messages[lastMessagePosistion]
        
        if let quickReplies = message.quickReplies, !quickReplies.isEmpty {
            return quickReplies
        } else {
            return nil
        }
    }
    
    init(
        presenter: MessagesPresenterProtocol,
        messagesManager: MessagesManagerProtocol,
        messageCollection: ParleyChronologicalMessageCollection,
        messagesRepository: MessageRepositoryProtocol,
        reachabilityProvider: ReachabilityProvider
    ) {
        self.presenter = presenter
        self.messagesManager = messagesManager
        self.messages = messageCollection
        self.messageRepository = messagesRepository
        self.reachabilityProvider = reachabilityProvider
    }
    
    @MainActor
    func setScrolledToBottom(_ isScrolledToBottom: Bool) {
        presenter.set(isScrolledToBottom: isScrolledToBottom)
    }
}

// MARK: Methods
extension MessagesInteractor {
    
    @MainActor
    func handleViewDidLoad() {
        messages.set(messages: messagesManager.messages)
        
        if let welcomeMessage = messagesManager.welcomeMessage, !welcomeMessage.isEmpty {
            presenter.set(welcomeMessage: welcomeMessage)
        }
        
        if let stickyMessage = messagesManager.stickyMessage, !stickyMessage.isEmpty {
            presenter.present(stickyMessage: stickyMessage)
        }
        
        presenter.set(sections: messages.sections)
        
        presentQuickRepliesState()
        
        presenter.presentMessages()
    }
    
    @MainActor
    func handleAgentBeganTyping() {
        guard agentTyping == false else { return }
        agentTyping = true
        presenter.presentAgentTyping(agentTyping)
    }
    
    @MainActor
    func handleAgentStoppedTyping() {
        guard agentTyping else { return }
        agentTyping = false
        presenter.presentAgentTyping(agentTyping)
    }
    
    @MainActor
    func handleLoadMessages() async {
        guard
            reachabilityProvider.reachable,
            !isLoadingMessages,
            messagesManager.canLoadMore(),
            let oldestMessageId = messagesManager.getOldestMessage()?.id
        else { return }
        
        isLoadingMessages = true
        presenter.presentLoadingMessages(isLoadingMessages)
        
        if let collection = try? await findMessage(before: oldestMessageId) {
            handle(collection: collection, .before)
        }
            
        isLoadingMessages = false
        presenter.presentLoadingMessages(isLoadingMessages)
    }
    
    @MainActor
    func handle(collection: MessageCollection, _ handleType: MessagesManager.HandleType) {
        messagesManager.handle(collection, handleType)
        
        presenter.set(welcomeMessage: collection.welcomeMessage)
        switch handleType {
        case .all:
            messages.set(collection: collection)
            presenter.set(sections: messages.sections)
        case .before, .after:
            insertNewMessages(messages: collection.messages)
        }

        presenter.presentMessages()
        presentQuickRepliesState()
        
        presenter.present(stickyMessage: collection.stickyMessage)
    }
    
    @MainActor
    func handleNewMessage(_ message: Message) {
        if message.time == nil {
            message.time = Date()
        }
        
        guard messagesManager.add(message) else { return }
        messages.add(message: message)
        presentQuickRepliesState()
        
        if message.hasQuickReplies == false {
            presenter.presentAdd(message: message)
        }
    }
    
    func handleMessageSent(_ message: Message) async {
        message.status = .success
        messagesManager.update(message)
        messages.update(message: message)
        await presenter.presentUpdate(message: message)
    }
    
    func handleMessageFailedToSend(_ message: Message) async {
        message.status = .failed
        messagesManager.update(message)
        messages.update(message: message)
        await presenter.presentUpdate(message: message)
    }
    
    @MainActor
    func clear() {
        messages.clear()
        messagesManager.clear()
        presenter.set(sections: messages.sections)
        presenter.presentMessages()
        presentQuickRepliesState()
    }
}

private extension MessagesInteractor {
    
    func findMessage(before messageId: Int) async throws -> MessageCollection {
        try await withCheckedThrowingContinuation { continuation in
            messageRepository.findBefore(messageId) { messageCollection in
                continuation.resume(returning: messageCollection)
            } onFailure: { error in
                continuation.resume(throwing: error)
            }
        }
    }
    
    func insertNewMessages(messages: [Message]) {
        var posisitionsAdded = [ParleyChronologicalMessageCollection.Position]()
        posisitionsAdded.reserveCapacity(messages.count)
        
        for message in messages {
            posisitionsAdded.append(self.messages.add(message: message))
        }
        
        presenter.set(sections: self.messages.sections)
    }
    
    @MainActor
    func presentQuickRepliesState() {
        if let quickReplies {
            guard presentedQuickReplies != quickReplies else { return }
            presenter.present(quickReplies: quickReplies)
            presentedQuickReplies = quickReplies
        } else {
            guard presentedQuickReplies != nil else { return }
            presenter.presentHideQuickReplies()
            presentedQuickReplies = nil
        }
    }
}

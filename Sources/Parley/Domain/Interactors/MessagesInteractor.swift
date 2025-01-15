import Foundation

class MessagesInteractor {
    
    private let presenter: MessagesPresenterProtocol
    private let messagesManager: MessagesManagerProtocol
    private let messageRepository: MessageRepositoryProtocol
    private let reachabilityProvider: ReachibilityProvider
    
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
        reachabilityProvider: ReachibilityProvider
    ) {
        self.presenter = presenter
        self.messagesManager = messagesManager
        self.messages = messageCollection
        self.messageRepository = messagesRepository
        self.reachabilityProvider = reachabilityProvider
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
        presentAgentTyping()
    }
    
    @MainActor
    func handleAgentStoppedTyping() {
        guard agentTyping else { return }
        agentTyping = false
        presentAgentTyping()
    }
    
    @MainActor
    func handleLoadMessages() async {
        guard
            reachabilityProvider.reachable,
            !isLoadingMessages,
            messagesManager.canLoadMore(),
            let lastMessageId = messagesManager.getOldestMessage()?.id
        else { return }
        
        isLoadingMessages = true
        presenter.presentLoadingMessages(isLoadingMessages)
        
        if let collection = try? await findMessage(before: lastMessageId) {
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
            presenter.presentMessages()
            presentQuickRepliesState()
        case .before, .after:
            insertNewMessages(messages: collection.messages)
        }
        
        presenter.present(stickyMessage: collection.stickyMessage)
    }
    
    @MainActor
    func handleNewMessage(_ message: Message) {
        if message.time == nil {
            message.time = Date()
        }
        
        messagesManager.add(message)
        messages.add(message: message)
        presentQuickRepliesState()
        
        if (message.quickReplies ?? []).isEmpty {
            presenter.presentAdd(message: message)
        }
    }
    
    func handleMessageSent(_ message: Message) async {
        message.status = .success
        messagesManager.update(message)
        _ = messages.update(message: message)
        await presenter.presentUpdate(message: message)
    }
    
    func handleMessageFailedToSend(_ message: Message) async {
        message.status = .failed
        messagesManager.update(message)
        _ = messages.update(message: message)
        await presenter.presentUpdate(message: message)
    }
    
    @MainActor
    func clear() {
        messages.clear()
        presenter.set(sections: messages.sections)
        presenter.presentMessages()
        presentQuickRepliesState()
    }
    
    @MainActor
    func isScrolledToBottom(_ isScrolledToBottom: Bool) {
        presenter.set(isScrolledToBottom: isScrolledToBottom)
    }
}

private extension MessagesInteractor {
    
    @MainActor
    func presentAgentTyping() {
        presenter.presentAgentTyping(agentTyping)
    }
    
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
    
    func isQuickReplyMessage(_ message: Message) -> Bool {
        message.quickReplies?.isEmpty == false
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

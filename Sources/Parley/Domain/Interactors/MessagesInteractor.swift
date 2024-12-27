import Foundation

class MessagesInteractor {
    
    private let presenter: MessagesPresenterProtocol
    private let messagesManager: MessagesManagerProtocol
    private let messageRepository: MessageRepositoryProtocol
    private let reachabilityProvider: ReachibilityProvider
    
    private(set) var agentTyping: Bool = false
    private(set) var isLoadingMessages: Bool = false
    private(set) var messages: ParleyChronologicalMessageCollection
    
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
            await handle(collection: collection, .before)
        }
            
        isLoadingMessages = false
        presenter.presentLoadingMessages(isLoadingMessages)
    }
    
    func handle(collection: MessageCollection, _ handleType: MessagesManager.HandleType) async {
        messagesManager.handle(collection, handleType)
        
        presenter.set(welcomeMessage: collection.welcomeMessage)
        switch handleType {
        case .all:
            messages.set(collection: collection)
            presenter.set(sections: messages.sections)
            await presenter.presentMessages()
        case .before, .after:
            await insertNewMessages(messages: collection.messages)
        }
        
        await presenter.present(stickyMessage: collection.stickyMessage)
    }
    
    @MainActor
    func handleNewMessage(_ message: Message) {
        let posistion = messages.add(message: message)
        presenter.presentAdd(message: message, at: posistion)
    }
    
    func handleMessageSent(_ message: Message) async {
        message.status = .success
        messagesManager.update(message)
        if let posistion = messages.update(message: message) {
            await presenter.presentUpdate(message: message, at: posistion)
        }
    }
    
    func handleMessageFailedToSend(_ message: Message) async {
        message.status = .failed
        messagesManager.update(message)
        if let posistion = messages.update(message: message) {
            await presenter.presentUpdate(message: message, at: posistion)
        }
    }
    
    @MainActor
    func clear() {
        messages.clear()
        presenter.set(sections: messages.sections)
        presenter.presentMessages()
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
    
    private func insertNewMessages(messages: [Message]) async {
        var posisitionsAdded = [ParleyChronologicalMessageCollection.Position]()
        posisitionsAdded.reserveCapacity(messages.count)
        
        for message in messages {
            posisitionsAdded.append(self.messages.add(message: message))
        }
        
        presenter.set(sections: self.messages.sections)
    }
}

import Foundation

@ParleyDomainActor
final class MessagesInteractor {
    
    private let presenter: MessagesPresenterProtocol
    private let messagesManager: MessagesManagerProtocol
    private let messageRepository: MessageRepository
    private let reachabilityProvider: ReachabilityProvider
    
    private(set) var agentTyping = false
    private(set) var isLoadingMessages = false
    private(set) var messages: ParleyChronologicalMessageCollection
    private(set) var isScrolledAtBottom = false
    
    private(set) var presentedQuickReplies: [String]?
    
    private var quickReplies: [String]? {
        guard let lastMessagePosistion = messages.lastPosistion() else { return nil }
        let message = messages[lastMessagePosistion]
        
        if !message.quickReplies.isEmpty {
            return message.quickReplies
        } else {
            return nil
        }
    }
    
    init(
        presenter: MessagesPresenterProtocol,
        messagesManager: MessagesManagerProtocol,
        messageCollection: ParleyChronologicalMessageCollection,
        messagesRepository: MessageRepository,
        reachabilityProvider: ReachabilityProvider
    ) {
        self.presenter = presenter
        self.messagesManager = messagesManager
        self.messages = messageCollection
        self.messageRepository = messagesRepository
        self.reachabilityProvider = reachabilityProvider
    }
    
    func setScrolledToBottom(_ isScrolledToBottom: Bool) {
        presenter.set(isScrolledToBottom: isScrolledToBottom)
    }
}

// MARK: Methods
extension MessagesInteractor {
    
    func handleViewDidLoad() async {
        await messages.set(messages: messagesManager.messages)
        
        if let welcomeMessage = await messagesManager.welcomeMessage, !welcomeMessage.isEmpty {
            presenter.set(welcomeMessage: welcomeMessage)
        }
        
        if let stickyMessage = await messagesManager.stickyMessage, !stickyMessage.isEmpty {
            await presenter.present(stickyMessage: stickyMessage)
        }
        
        presenter.set(sections: messages.sections)
        
        await presentQuickRepliesState()
        
        await presenter.presentMessages()
        
        await presenter.presentScrollToBotom(animated: false)
    }
    
    func handleAgentBeganTyping() async {
        guard agentTyping == false else { return }
        agentTyping = true
        await presenter.presentAgentTyping(agentTyping)
    }
    
    func handleAgentStoppedTyping() async {
        guard agentTyping else { return }
        agentTyping = false
        await presenter.presentAgentTyping(agentTyping)
    }
    
    func handleLoadMessages() async {
        guard
            await reachabilityProvider.reachable,
            !isLoadingMessages,
            await messagesManager.canLoadMore(),
            let oldestMessageId = await messagesManager.getOldestMessage()?.remoteId
        else { return }
        
        isLoadingMessages = true
        await presenter.presentLoadingMessages(isLoadingMessages)
        
        if let collection = try? await messageRepository.findBefore(oldestMessageId) {
            await handle(collection: collection, .before)
        }
            
        isLoadingMessages = false
        await presenter.presentLoadingMessages(isLoadingMessages)
    }
    
    func handle(collection: MessageCollection, _ handleType: MessagesManager.HandleType) async {
        await messagesManager.handle(collection, handleType)
        
        presenter.set(welcomeMessage: collection.welcomeMessage)
        switch handleType {
        case .all:
            messages.set(collection: collection)
            presenter.set(sections: messages.sections)
        case .before, .after:
            await insertNewMessages(messages: collection.messages)
        }

        await presenter.presentMessages()
        await presentQuickRepliesState()
        
        await presenter.present(stickyMessage: collection.stickyMessage)
    }
    
    func handleNewMessage(_ message: Message) async {
        guard await messagesManager.add(message) else { return }
        messages.add(message: message)
        await presentQuickRepliesState()
        
        if message.hasQuickReplies == false {
            await presenter.presentAdd(message: message)
        }
    }
    
    func handleMessageSent(_ message: inout Message) async {
        message.status = .success
        await messagesManager.update(message)
        messages.update(message: message)
        await presenter.presentUpdate(message: message)
    }
    
    func handleMessageFailedToSend(_ message: inout Message) async {
        message.status = .failed
        await messagesManager.update(message)
        messages.update(message: message)
        await presenter.presentUpdate(message: message)
    }
    
    func clear() async {
        messages.clear()
        await messagesManager.clear()
        presenter.set(sections: messages.sections)
        await presenter.presentMessages()
        await presentQuickRepliesState()
    }
}

private extension MessagesInteractor {
    
    func insertNewMessages(messages: [Message]) async {
        var posisitionsAdded = [ParleyChronologicalMessageCollection.Position]()
        posisitionsAdded.reserveCapacity(messages.count)
        
        for message in messages {
            if let addedMessagePosisition = self.messages.add(message: message) {
                posisitionsAdded.append(addedMessagePosisition)
            }
        }
        
        presenter.set(sections: self.messages.sections)
    }
    
    func presentQuickRepliesState() async {
        if let quickReplies {
            guard presentedQuickReplies != quickReplies else { return }
            await presenter.present(quickReplies: quickReplies)
            presentedQuickReplies = quickReplies
        } else {
            guard presentedQuickReplies != nil else { return }
            await presenter.presentHideQuickReplies()
            presentedQuickReplies = nil
        }
    }
}

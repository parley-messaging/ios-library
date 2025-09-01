import Foundation

@ParleyDomainActor
protocol MessagesPresenterProtocol: AnyObject, Sendable {
    @MainActor func set(display: ParleyMessagesDisplay) async
    
    func set(isScrolledToBottom: Bool)
    
    func set(welcomeMessage: String?)
    
    func set(sections: [ParleyChronologicalMessageCollection.Section])
    
    func present(stickyMessage: String?) async
    
    func presentAgentTyping(_ isTyping: Bool) async
    
    func presentLoadingMessages(_ isLoading: Bool) async
    
    func presentAdd(message: Message) async
    func presentUpdate(message: Message) async
    
    func presentMessages() async
    func present(quickReplies: [String]) async
    func presentHideQuickReplies() async
    func presentScrollToBotom(animated: Bool) async
}

@ParleyDomainActor
final class MessagesPresenter {
    
    // MARK: DI
    private let store: MessagesStore
    @MainActor private weak var display: ParleyMessagesDisplay?
    
    // MARK: Properties
    private(set) var isAgentTyping: Bool = false
    private(set) var welcomeMessage: String?
    private(set) var stickyMessage: String?
    private(set) var isLoadingMessages: Bool = false
    private(set) var currentSnapshot: MessagesSnapshot
    private var isScrolledToBottom: Bool = false
    private let usesAdaptiveWelcomePosistioning: Bool
    
    @MainActor
    init(
        store: MessagesStore,
        display: ParleyMessagesDisplay?,
        usesAdaptiveWelcomePosistioning: Bool
    ) {
        self.store = store
        self.display = display
        self.usesAdaptiveWelcomePosistioning = usesAdaptiveWelcomePosistioning
        
        self.currentSnapshot = MessagesSnapshot(
            welcomeMessage: welcomeMessage,
            calendar: .autoupdatingCurrent,
            adaptiveWelcomePositioning: usesAdaptiveWelcomePosistioning
        )
    }
    
    func set(isScrolledToBottom: Bool) {
        self.isScrolledToBottom = isScrolledToBottom
    }
    
    @MainActor
    func set(display: ParleyMessagesDisplay) {
        self.display = display
    }
}

// MARK: Methods
extension MessagesPresenter: MessagesPresenterProtocol {
    
    func set(welcomeMessage: String?) {
        self.welcomeMessage = welcomeMessage
        _ = currentSnapshot.set(welcomeMessage: welcomeMessage)
    }
    
    func set(sections: [ParleyChronologicalMessageCollection.Section]) {
        var snapshot = MessagesSnapshot(
            welcomeMessage: welcomeMessage,
            calendar: currentSnapshot.calendar,
            adaptiveWelcomePositioning: usesAdaptiveWelcomePosistioning
        )
        
        _ = snapshot.set(welcomeMessage: welcomeMessage)
        _ = snapshot.setLoading(isLoadingMessages)
        _ = snapshot.set(agentTyping: isAgentTyping)
        
        for section in sections {
            let sectionWithoutQuickReplies = section.messages.filter {
                $0.quickReplies.isEmpty
            }
            let result = snapshot.insertSection(messages: sectionWithoutQuickReplies)
            assert(result != nil, "Failed to insert section.")
        }
        
        currentSnapshot = snapshot
    }
    
    func present(stickyMessage: String?) async {
        self.stickyMessage = stickyMessage
        if let stickyMessage {
            await MainActor.run {
                display?.display(stickyMessage: stickyMessage)
            }
        } else {
            await MainActor.run {
                display?.displayHideStickyMessage()
            }
        }
    }
    
    func presentAgentTyping(_ isTyping: Bool) async {
        let wasScrolledToBottom = isScrolledToBottom
        guard let change = currentSnapshot.set(agentTyping: isTyping) else { return }
        self.isAgentTyping = isTyping
        
        await MainActor.run { [currentSnapshot, store, display] in
            presentSnapshotChange(change, preUpdate: {
                store.apply(snapshot: currentSnapshot)
            }) {
                if wasScrolledToBottom {
                    display?.displayScrollToBottom(animated: false)
                }
            }
        }
    }
    
    func presentUpdate(message: Message) async {
        let wasScrolledToBottom = isScrolledToBottom
        guard let change = currentSnapshot.set(message: message) else { return }
        await store.apply(snapshot: currentSnapshot)
        
        await MainActor.run { [currentSnapshot, store, display] in
            presentSnapshotChange(change, preUpdate: {
                store.apply(snapshot: currentSnapshot)
            }) {
                if wasScrolledToBottom {
                    display?.displayScrollToBottom(animated: false)
                }
            }
        }
    }
    
    func presentLoadingMessages(_ isLoading: Bool) async {
        let wasScrolledToBottom = isScrolledToBottom
        guard let change = currentSnapshot.setLoading(isLoading) else { return }
        self.isLoadingMessages = isLoading
        await store.apply(snapshot: currentSnapshot)
        
        await MainActor.run { [currentSnapshot, store, display] in
            presentSnapshotChange(change, preUpdate: {
                store.apply(snapshot: currentSnapshot)
            }) {
                if wasScrolledToBottom {
                    display?.displayScrollToBottom(animated: false)
                }
            }
        }
    }
    
    func presentAdd(message: Message) async {
        let wasScrolledToBottom = isScrolledToBottom
        guard let change = currentSnapshot.insert(message: message) else { return }
        guard change.isEmpty == false else { return }
        await store.apply(snapshot: currentSnapshot)
        await MainActor.run { [currentSnapshot, store, display] in
            presentSnapshotChange(change, preUpdate: {
                store.apply(snapshot: currentSnapshot)
            }) {
                if wasScrolledToBottom {
                    display?.displayScrollToBottom(animated: false)
                }
            }
        }
    }
    
    func presentMessages() async {
        _ = currentSnapshot.set(welcomeMessage: welcomeMessage)
        _ = currentSnapshot.setLoading(isLoadingMessages)
        _ = currentSnapshot.set(agentTyping: isAgentTyping)
        
        await MainActor.run { [currentSnapshot] in
            store.apply(snapshot: currentSnapshot)
            display?.reload()
        }
    }
    
    func present(quickReplies: [String]) async {
        await MainActor.run {
            display?.display(quickReplies: quickReplies)
        }
    }
    
    func presentHideQuickReplies() async {
        await MainActor.run {
            display?.displayHideQuickReplies()
        }
    }
    
    func presentScrollToBotom(animated: Bool) async {
        await MainActor.run {
            display?.displayScrollToBottom(animated: animated)
        }
    }
}

// MARK: Privates
private extension MessagesPresenter {
    
    @MainActor
    func presentSnapshotChange(
        _ change: SnapshotChange,
        preUpdate: (@MainActor () -> Void)?,
        postUpdate: (@MainActor () -> Void)?
    ) {
        guard change.isEmpty == false else { return }
        
        display?.performBatchUpdates(change, preUpdate: preUpdate, postUpdate: postUpdate)
    }
}

extension MessagesPresenter {
    

}

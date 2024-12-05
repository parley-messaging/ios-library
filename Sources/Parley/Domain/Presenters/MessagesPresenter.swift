import Foundation

protocol MessagesPresenterProtocol: AnyObject {
    func set(display: ParleyMessagesDisplay)
    
    func set(welcomeMessage: String?)
    func set(messages: [Message])
    
    @MainActor func present(stickyMessage: String?)
    
    @MainActor func presentAgentTyping(_ isTyping: Bool)
    
    @MainActor func presentLoadingMessages(_ isLoading: Bool)
    
    @MainActor func presentSet(messages: [Message])
    
    @MainActor func presentAdd(messages: [Message], posistionsAdded: [ParleyChronologicalMessageCollection.Posisition])
    
    @MainActor func presentMessages()
}

final class MessagesPresenter {
    
    struct Section {
        var cells = [MessagesStore.CellKind]()
    }
    
    // MARK: DI
    private let store: MessagesStore
    private weak var display: ParleyMessagesDisplay?
    
    // MARK: Properties
    private var welcomeMessage: String?
    private var stickyMessage: String?
    private var sections = [Section]()
    
    init(store: MessagesStore, display: ParleyMessagesDisplay?) {
        self.store = store
        self.display = display
    }
    
    func set(display: ParleyMessagesDisplay) {
        self.display = display
    }
}

// MARK: Methods
extension MessagesPresenter: MessagesPresenterProtocol {

    func set(welcomeMessage: String?) {
        self.welcomeMessage = welcomeMessage
    }
    
    func set(messages: [Message]) {
        
    }

    @MainActor
    func present(stickyMessage: String?) {
        self.stickyMessage = stickyMessage
        if let stickyMessage {
            display?.display(stickyMessage: stickyMessage)
        } else {
            display?.displayHideStickyMessage()
        }
    }
    
    @MainActor
    func presentAgentTyping(_ isTyping: Bool) {
        if isTyping {
            store.addSection(cells: [.typingIndicator])
            display?.insertRows(at: [.init(row: .zero, section: sections.endIndex - 1)], with: .none)
        } else {
            guard
                let lastSection = sections.last,
                let firstCell = lastSection.cells.first,
                case .typingIndicator = firstCell
            else { return }
            sections.remove(at: sections.endIndex - 1)
            display?.deleteRows(at: [.init(row: .zero, section: sections.endIndex)], with: .none)
        }
    }
    
    @MainActor
    func presentLoadingMessages(_ isLoading: Bool) {
        // ..
        display?.reload()
    }
    
    @MainActor
    func presentSet(messages: [Message]) {
        // ..
        display?.reload()
    }
    
    @MainActor
    func presentAdd(messages: [Message], posistionsAdded: [ParleyChronologicalMessageCollection.Posisition]) {
        // ..
        display?.reload()
    }
    
    @MainActor
    func presentMessages() {
        // ..
        display?.reload()
    }
}

// MARK: Privates
private extension MessagesPresenter {
    
}

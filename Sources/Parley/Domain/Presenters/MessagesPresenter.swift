import Foundation

protocol MessagesPresenterProtocol: AnyObject {
    func set(display: ParleyMessagesDisplay)
    
    func set(isScrolledToBottom: Bool)
    
    func set(welcomeMessage: String?)
    
    func set(sections: [ParleyChronologicalMessageCollection.Section])
    
    @MainActor func present(stickyMessage: String?)
    
    @MainActor func presentAgentTyping(_ isTyping: Bool)
    
    @MainActor func presentLoadingMessages(_ isLoading: Bool)
    
    @MainActor func presentAdd(message: Message)
    @MainActor func presentUpdate(message: Message)
    
    @MainActor func presentMessages()
    @MainActor func present(quickReplies: [String])
    @MainActor func presentHideQuickReplies()
}

final class MessagesPresenter {
    
    // MARK: DI
    private let store: MessagesStore
    private weak var display: ParleyMessagesDisplay?
    
    // MARK: Properties
    private(set) var isAgentTyping: Bool = false
    private(set) var welcomeMessage: String?
    private(set) var stickyMessage: String?
    private(set) var isLoadingMessages: Bool = false
    private(set) var currentSnapshot: Snapshot
    private var isScrolledToBottom: Bool = false
    
    init(store: MessagesStore, display: ParleyMessagesDisplay?) {
        self.store = store
        self.display = display
        self.currentSnapshot = Snapshot(welcomeMessage: welcomeMessage)
    }
    
    func set(display: ParleyMessagesDisplay) {
        self.display = display
    }
    
    func set(isScrolledToBottom: Bool) {
        self.isScrolledToBottom = isScrolledToBottom
    }
}

// MARK: Methods
extension MessagesPresenter: MessagesPresenterProtocol {

    func set(welcomeMessage: String?) {
        self.welcomeMessage = welcomeMessage
        _ = currentSnapshot.set(welcomeMessage: welcomeMessage)
    }
    
    func set(sections: [ParleyChronologicalMessageCollection.Section]) {
        var snapshot = Snapshot(welcomeMessage: welcomeMessage)
        _ = snapshot.set(welcomeMessage: welcomeMessage)
        _ = snapshot.setLoading(isLoadingMessages)
        _ = snapshot.set(agentTyping: isAgentTyping)
        
        for var section in sections {
            section.messages.removeAll(where: { $0.quickReplies?.isEmpty == false })
            _ = snapshot.append(section: section.messages, date: section.date)
        }
        
        currentSnapshot = snapshot
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
        guard let change = currentSnapshot.set(agentTyping: isTyping) else { return }
        self.isAgentTyping = isTyping
        store.apply(snapshot: currentSnapshot)
        presentSnapshotChange(change)
    }
    
    @MainActor
    func presentUpdate(message: Message) {
        guard let change = currentSnapshot.set(message: message) else { return }
        store.apply(snapshot: currentSnapshot)
        presentSnapshotChange(change)
    }
    
    @MainActor
    func presentLoadingMessages(_ isLoading: Bool) {
        guard let change = currentSnapshot.setLoading(isLoading) else { return }
        self.isLoadingMessages = isLoading
        store.apply(snapshot: currentSnapshot)
        presentSnapshotChange(change)
    }
    
    @MainActor func presentAdd(message: Message) {
        guard let change = currentSnapshot.append(message: message) else { return }
        store.apply(snapshot: currentSnapshot)
        presentSnapshotChange(change)
        if isScrolledToBottom, let lastIndexPath = change.indexPaths.last {
            display?.scrollTo(indexPaths: lastIndexPath, at: .bottom, animated: true)
        }
    }
    
    @MainActor func presentAdd(section: [Message], date: Date) {
        let change = currentSnapshot.append(section: section, date: date)
        store.apply(snapshot: currentSnapshot)
        presentSnapshotChange(change)
        if isScrolledToBottom, let lastIndexPath = change.indexPaths.last {
            display?.scrollTo(indexPaths: lastIndexPath, at: .bottom, animated: true)
        }
    }
    
    @MainActor
    func presentMessages() {
        _ = currentSnapshot.set(welcomeMessage: welcomeMessage)
        _ = currentSnapshot.setLoading(isLoadingMessages)
        _ = currentSnapshot.set(agentTyping: isAgentTyping)
        
        store.apply(snapshot: currentSnapshot)
        
        display?.reload()
    }
    
    @MainActor func present(quickReplies: [String]) {
        display?.display(quickReplies: quickReplies)
    }
    
    @MainActor func presentHideQuickReplies() {
        display?.displayHideQuickReplies()
    }
}

// MARK: Privates
private extension MessagesPresenter {
    
    @MainActor
    func presentSnapshotChange(_ change: Snapshot.SnapshotChange) {
        guard change.indexPaths.isEmpty == false else { return }
        
        switch change.kind {
        case .added:
            display?.insertRows(at: change.indexPaths, with: .none)
        case .changed:
            display?.reloadRows(at: change.indexPaths, with: .none)
        case .deleted:
            display?.deleteRows(at: change.indexPaths, with: .none)
        }
    }
}

extension MessagesPresenter {
    
    struct Snapshot {
        
        struct SnapshotChange: Equatable {
            enum SnapshotChangeKind {
                case added, changed, deleted
            }
            let indexPaths: [IndexPath]
            let kind: SnapshotChangeKind
        }
        
        typealias CellKind = MessagesStore.CellKind
        typealias SectionKind = MessagesStore.SectionKind
        
        private(set) var welcomeMessage: String?
        private(set) var agentTyping = false
        private(set) var isLoading = false
        
        private(set) var sections: [SectionKind]
        private(set) var cells: [[CellKind]]
        
        var isEmpty: Bool {
            sections.isEmpty && cells.isEmpty
        }
        
        init(welcomeMessage: String?) {
            self.welcomeMessage = welcomeMessage
            sections = [SectionKind]()
            cells = [[CellKind]]()
            
            if let welcomeMessage {
                sections.append(.info)
                cells.append([.info(welcomeMessage)])
            }
        }
        
        /// append a message to the last message section, if available.
        /// - Parameters:
        ///   - message: Message to add
        /// - returns: A change, or none if there is no message section.
        mutating func append(message: Message) -> SnapshotChange? {
            guard let cell = makeMessageCell(message) else { return nil }
            
            var indexPaths = [IndexPath]()
            
            guard let lastSectionIndex = lastMessagesSectionIndex() else { return nil }
            cells[lastSectionIndex].append(cell)
            indexPaths.append(IndexPath(row: cells[lastSectionIndex].endIndex - 1, section: lastSectionIndex))
            
            return SnapshotChange(indexPaths: indexPaths, kind: .added)
        }
        
        private func makeMessageCell(_ message: Message) -> MessagesStore.CellKind? {
            guard !hasQuickReplies(message) else { return nil }

            if let carousel = message.carousel, !carousel.isEmpty {
                return MessagesStore.CellKind.carousel(mainMessage: message, carousel: carousel)
            } else {
                return MessagesStore.CellKind.message(message)
            }
        }
        
        private func hasQuickReplies(_ message: Message) -> Bool {
            if let quickReplies = message.quickReplies {
                return !quickReplies.isEmpty
            } else {
                return false
            }
        }
        
        mutating func append(section: [Message], date: Date) -> SnapshotChange {
            let sectionIndexToInsert = nextMessagesSectionIndex()
            sections.insert(.messages, at: sectionIndexToInsert)
            cells.insert([.dateHeader(date)], at: sectionIndexToInsert)
            
            var indexPaths = [IndexPath]()
            indexPaths.reserveCapacity(section.count)
            
            indexPaths.append(IndexPath(row: 0, section: sectionIndexToInsert))
            
            for (index, message) in section.enumerated() {
                guard let cell = makeMessageCell(message) else { continue }
                let messageIndex = index + 1 // offset for date header
                indexPaths.append(IndexPath(row: messageIndex, section: sectionIndexToInsert))
                cells[sectionIndexToInsert].insert(cell, at: messageIndex)
            }
            
            return SnapshotChange(indexPaths: indexPaths, kind: .added)
        }
        
        private func nextMessagesSectionIndex() -> Int {
            var sectionIndex = sections.endIndex - 1
            
            while sectionIndex >= 0 {
                if sections[sectionIndex] == .messages {
                    return sectionIndex + 1
                }
                sectionIndex -= 1
            }
            
            return sections.endIndex
        }
        
        private func lastMessagesSectionIndex() -> Int? {
            var sectionIndex = sections.endIndex - 1
            
            while sectionIndex >= 0 {
                if sections[sectionIndex] == .messages {
                    return sectionIndex
                }
                sectionIndex -= 1
            }
            
            return nil
        }
        
        mutating func set(agentTyping: Bool) -> SnapshotChange? {
            guard self.agentTyping != agentTyping else { return nil }
            self.agentTyping = agentTyping
            return agentTyping ? addAgentTypingCell() : removeAgentTypingCell()
        }
        
        private mutating func addAgentTypingCell() -> SnapshotChange {
            let insertIndexPath = IndexPath(row: 0, section: sections.endIndex)
            sections.append(.typingIndicator)
            cells.append([.typingIndicator])
            return SnapshotChange(indexPaths: [insertIndexPath], kind: .added)
        }
        
        private mutating func removeAgentTypingCell() -> SnapshotChange {
            let deletetingIndexPath = IndexPath(row: 0, section: sections.endIndex - 1)
            _ = sections.popLast()
            _ = cells.popLast()
            return SnapshotChange(indexPaths: [deletetingIndexPath], kind: .deleted)
        }
        
        mutating func setLoading(_ isLoading: Bool) -> SnapshotChange? {
            guard self.isLoading != isLoading else { return nil }
            self.isLoading = isLoading
            return isLoading ? addLoadingCell() : removeLoadingCell()
        }
        
        private mutating func addLoadingCell() -> SnapshotChange {
            let sectionIndexToInsert = welcomeMessage == nil ? 0 : 1
            sections.insert(.loading, at: sectionIndexToInsert)
            cells.insert([.loading], at: sectionIndexToInsert)
            return SnapshotChange(indexPaths: [IndexPath(row: 0, section: sectionIndexToInsert)], kind: .added)
        }
        
        private mutating func removeLoadingCell() -> SnapshotChange {
            let sectionIndexToRemove = welcomeMessage == nil ? 0 : 1
            sections.remove(at: sectionIndexToRemove)
            cells.remove(at: sectionIndexToRemove)
            return SnapshotChange(indexPaths: [IndexPath(row: 0, section: sectionIndexToRemove)], kind: .deleted)
        }
        
        mutating func set(welcomeMessage: String?) -> SnapshotChange? {
            guard self.welcomeMessage != welcomeMessage else { return nil }
            
            if let welcomeMessage, self.welcomeMessage == nil {
                self.welcomeMessage = welcomeMessage
                return addWelcomeMessageCell(welcomeMessage)
            } else if let welcomeMessage, self.welcomeMessage != nil {
                self.welcomeMessage = welcomeMessage
                return updateWelcomeMessageCell(welcomeMessage)
            } else {
                return deleteWelcomeMessageCell()
            }
        }
        
        private mutating func addWelcomeMessageCell(_ welcomeMessage: String) -> SnapshotChange {
            let insertedIndexPath = IndexPath(row: .zero, section: .zero)
            sections.insert(.info, at: .zero)
            cells.insert([.info(welcomeMessage)], at: .zero)
            return SnapshotChange(indexPaths: [insertedIndexPath], kind: .added)
        }
        
        private mutating func updateWelcomeMessageCell(_ welcomeMessage: String) -> SnapshotChange {
            let changedIndexPath = IndexPath(row: .zero, section: .zero)
            cells[.zero][.zero] = .info(welcomeMessage)
            return SnapshotChange(indexPaths: [changedIndexPath], kind: .changed)
        }
        
        private mutating func deleteWelcomeMessageCell() -> SnapshotChange {
            let deletedIndexPath = IndexPath(row: .zero, section: .zero)
            sections.removeFirst()
            cells.removeFirst()
            return SnapshotChange(indexPaths: [deletedIndexPath], kind: .deleted)
        }
        
        mutating func set(message updatedMessage: Message) -> SnapshotChange? {
            guard let updatedCell = makeMessageCell(updatedMessage) else { return nil }
            
            for (sectionIndex, section) in cells.enumerated() {
                for (cellIndex, cell) in section.enumerated() {
                    if case let .message(message) = cell {
                        if message.id == updatedMessage.id || message.uuid == updatedMessage.uuid {
                            cells[sectionIndex][cellIndex] = updatedCell
                            return SnapshotChange(indexPaths: [
                                IndexPath(row: cellIndex, section: sectionIndex)
                            ], kind: .changed)
                        }
                    }
                }
            }
            
            return nil
        }
    }
}

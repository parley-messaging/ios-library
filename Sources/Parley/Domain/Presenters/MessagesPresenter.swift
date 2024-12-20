import Foundation

protocol MessagesPresenterProtocol: AnyObject {
    func set(display: ParleyMessagesDisplay)
    
    func set(welcomeMessage: String?)
    
    func set(sections: [ParleyChronologicalMessageCollection.Section])
    
    @MainActor func present(stickyMessage: String?)
    
    @MainActor func presentAgentTyping(_ isTyping: Bool)
    
    @MainActor func presentLoadingMessages(_ isLoading: Bool)
    
    @MainActor func presentAdd(message: Message, at posistion: ParleyChronologicalMessageCollection.Posisition)
    @MainActor func presentUpdate(message: Message, at posistion: ParleyChronologicalMessageCollection.Posisition)
    @MainActor func presentDelete(at posistion: ParleyChronologicalMessageCollection.Posisition)
    
    @MainActor func presentMessages()
}

final class MessagesPresenter {
    
    // MARK: DI
    private let store: MessagesStore
    private weak var display: ParleyMessagesDisplay?
    
    // MARK: Properties
    private(set) var isAgentTyping: Bool = false
    private(set) var welcomeMessage: String?
    private(set) var isLoadingMessages: Bool = false
    private(set) var currentSnapshot: Snapshot
    
    init(store: MessagesStore, display: ParleyMessagesDisplay?) {
        self.store = store
        self.display = display
        self.currentSnapshot = Snapshot(welcomeMessage: welcomeMessage)
    }
    
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
        var snapshot = Snapshot(welcomeMessage: welcomeMessage)
        _ = snapshot.set(welcomeMessage: welcomeMessage)
        _ = snapshot.setLoading(isLoadingMessages)
        _ = snapshot.set(agentTyping: isAgentTyping)
        
        for section in sections {
            _ = snapshot.insert(section: section.messages)
        }
        
        currentSnapshot = snapshot
    }

    @MainActor
    func present(stickyMessage: String?) {
        if let stickyMessage {
            display?.display(stickyMessage: stickyMessage)
        } else {
            display?.displayHideStickyMessage()
        }
    }
    
    @MainActor
    func presentAgentTyping(_ isTyping: Bool) {
        self.isAgentTyping = isTyping
        let change = currentSnapshot.set(agentTyping: isTyping)
        store.apply(snapshot: currentSnapshot)
        presentSnapshotChange(change)
    }
    
    @MainActor
    func presentUpdate(message: Message, at posistion: ParleyChronologicalMessageCollection.Posisition) {
        let change = currentSnapshot.update(message: message, section: posistion.section, row: posistion.row)
        store.apply(snapshot: currentSnapshot)
        presentSnapshotChange(change)
    }
    
    @MainActor
    func presentLoadingMessages(_ isLoading: Bool) {
        let change = currentSnapshot.setLoading(isLoading)
        store.apply(snapshot: currentSnapshot)
        presentSnapshotChange(change)
    }
    
    @MainActor func presentAdd(message: Message, at posistion: ParleyChronologicalMessageCollection.Posisition) {
        let change = currentSnapshot.insert(message: message, section: posistion.section, row: posistion.row)
        store.apply(snapshot: currentSnapshot)
        presentSnapshotChange(change)
    }
    
    @MainActor func presentDelete(at posistion: ParleyChronologicalMessageCollection.Posisition) {
        let change = currentSnapshot.delete(section: posistion.section, row: posistion.row)
        store.apply(snapshot: currentSnapshot)
        presentSnapshotChange(change)
    }
    
    @MainActor
    func presentMessages() {
        _ = currentSnapshot.set(welcomeMessage: welcomeMessage)
        _ = currentSnapshot.setLoading(isLoadingMessages)
        _ = currentSnapshot.set(agentTyping: isAgentTyping)
        
        store.apply(snapshot: currentSnapshot)
        
        display?.reload()
    }
}

// MARK: Privates
private extension MessagesPresenter {
    
    @MainActor
    func presentSnapshotChange(_ change: Snapshot.SnapshotChange) {
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
            
            static let noChange = SnapshotChange(indexPaths: [], kind: .changed)
        }
        
        typealias CellKind = MessagesStore.CellKind
        typealias SectionKind = MessagesStore.SectionKind
        
        private(set) var welcomeMessage: String?
        private(set) var agentTyping = false
        private(set) var isLoading = false
        
        var loadingSectionIndex: Int {
            welcomeMessage != nil ? 1 : 0
        }
        
        private(set) var sections: [SectionKind]
        private(set) var cells: [[CellKind]]
        
        init(welcomeMessage: String?) {
            self.welcomeMessage = welcomeMessage
            sections = [SectionKind]()
            cells = [[CellKind]]()
            
            if let welcomeMessage {
                sections.append(.info)
                cells.append([.info(welcomeMessage)])
            }
        }
        
        /// Inserts a message with a specified (section, row)
        /// - Parameters:
        ///   - message: Message to add
        ///   - section: section to add to, based only on messages
        ///   - row: row to add to, based only on messages
        mutating func insert(message: Message, section: Int, row: Int) -> SnapshotChange {
            guard let time = message.time else { return .noChange }
            
            var indexPaths = [IndexPath]()
            
            var correctedSection = section
            let correctedRow = row + 1 // Offset for date header
            
            if welcomeMessage != nil {
                correctedSection += 1
            }
            
            if isLoading {
                correctedSection += 1
            }
            
            if sections[safe: correctedSection] == nil {
                sections.append(.messages)
            }
            
            if cells[safe: correctedSection] == nil {
                cells.append([.dateHeader(time)])
                indexPaths.append(IndexPath(row: 0, section: correctedSection))
            }
            
            cells[correctedSection].insert(makeMessageCell(message), at: correctedRow)
            indexPaths.append(IndexPath(row: correctedRow, section: correctedSection))
            
            return SnapshotChange(indexPaths: indexPaths, kind: .added)
        }
        
        private func makeMessageCell(_ message: Message) -> MessagesStore.CellKind {
            if let carousel = message.carousel, !carousel.isEmpty {
                MessagesStore.CellKind.carousel(mainMessage: message, carousel: carousel)
            } else {
                MessagesStore.CellKind.message(message)
            }
        }
        
        mutating func insert(section: [Message]) -> SnapshotChange {
            let sectionIndexToInsert = lastMessagesSectionIndex() + 1
            sections.insert(.messages, at: sectionIndexToInsert)
            cells.insert([], at: sectionIndexToInsert)
            
            var indexPaths = [IndexPath]()
            indexPaths.reserveCapacity(section.count)
            
            for (index, message) in section.enumerated() {
                indexPaths.append(IndexPath(row: index, section: sectionIndexToInsert))
                cells[sectionIndexToInsert][index] = makeMessageCell(message)
            }
            
            return SnapshotChange(indexPaths: indexPaths, kind: .added)
        }
        
        private func lastMessagesSectionIndex() -> Int {
            var sectionIndex = sections.endIndex - 1
            
            while sectionIndex >= 0 {
                if sections[sectionIndex] == .messages {
                    break
                }
                sectionIndex -= 1
            }
            
            return sectionIndex
        }
        
        mutating func set(agentTyping: Bool) -> SnapshotChange {
            guard self.agentTyping != agentTyping else { return .noChange }
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
        
        mutating func setLoading(_ isLoading: Bool) -> SnapshotChange {
            guard self.isLoading != isLoading else { return .noChange }
            self.isLoading = isLoading
            return isLoading ? addLoadingCell() : removeLoadingCell()
        }
        
        private mutating func addLoadingCell() -> SnapshotChange {
            let insertedIndexPath = IndexPath(row: 0, section: sections.endIndex)
            sections.append(.loading)
            cells.append([.loading])
            return SnapshotChange(indexPaths: [insertedIndexPath], kind: .added)
        }
        
        private mutating func removeLoadingCell() -> SnapshotChange {
            let deletetingIndexPath = IndexPath(row: 0, section: sections.endIndex - 1)
            _ = sections.popLast()
            _ = cells.popLast()
            return SnapshotChange(indexPaths: [deletetingIndexPath], kind: .deleted)
        }
        
        mutating func set(welcomeMessage: String?) -> SnapshotChange {
            guard self.welcomeMessage != welcomeMessage else { return .noChange }
            self.welcomeMessage = welcomeMessage
            
            if let welcomeMessage, self.welcomeMessage == nil {
                return addWelcomeMessageCell(welcomeMessage)
            } else if let welcomeMessage, self.welcomeMessage != nil {
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
        
        mutating func update(message: Message, section: Int, row: Int) -> SnapshotChange {
            var correctedSection = section
            let correctedRow = row + 1 // Offset for date header
            
            if welcomeMessage != nil {
                correctedSection += 1
            }
            
            if isLoading {
                correctedSection += 1
            }
            
            cells[correctedSection][correctedRow] = makeMessageCell(message)
            
            return SnapshotChange(indexPaths: [
                IndexPath(row: correctedRow, section: correctedSection)
            ], kind: .changed)
        }
        
        mutating func delete(section: Int, row: Int) -> SnapshotChange {
            var correctedSection = section
            let correctedRow = row + 1 // Offset for date header
            
            if welcomeMessage != nil {
                correctedSection += 1
            }
            
            if isLoading {
                correctedSection += 1
            }
            
            cells[correctedSection].remove(at: row)
            
            return SnapshotChange(indexPaths: [
                IndexPath(row: correctedRow, section: correctedSection)
            ], kind: .deleted)
        }
    }
}

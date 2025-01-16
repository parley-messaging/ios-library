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
        self.currentSnapshot = Snapshot(welcomeMessage: welcomeMessage, calendar: .autoupdatingCurrent)
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
        var snapshot = Snapshot(welcomeMessage: welcomeMessage, calendar: currentSnapshot.calendar)
        _ = snapshot.set(welcomeMessage: welcomeMessage)
        _ = snapshot.setLoading(isLoadingMessages)
        _ = snapshot.set(agentTyping: isAgentTyping)
        
        for var section in sections {
            section.messages.removeAll(where: { $0.quickReplies?.isEmpty == false })
            let result = snapshot.insertSection(messages: section.messages)
            assert(result != nil, "Failed to insert section.")
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
        guard let change = currentSnapshot.insert(message: message) else { return }
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
        
        struct Section {
            let date: Date?
            let sectionKind: SectionKind
            private(set) var cells: [Cell]
            var calendar: Calendar = .autoupdatingCurrent
            
            private init(
                date: Date?,
                sectionKind: SectionKind,
                cells: [Cell],
                calendar: Calendar
            ) {
                self.date = date
                self.sectionKind = sectionKind
                self.cells = cells
                self.calendar = calendar
            }
            
            mutating func set(cell: Cell, at index: Int) {
                cells[index] = cell
            }
            
            mutating func insert(cell: Cell) -> Int {
                switch cell.kind {
                case .info:
                    return insert(cell: cell)
                case .loading:
                    return insertLoading(cell)
                case .dateHeader:
                    return insertDateHeader(cell)
                case .typingIndicator:
                    return insertTypingIndicator(cell)
                case .message(let message):
                    return insertMessage(cell, message: message)
                case .carousel(let carousel, _):
                    return insertCarousel(cell, carousel: carousel)
                }
            }
            
            private mutating func insertInfo(_ cell: Cell) -> Int {
                let index = 0
                cells.insert(cell, at: index)
                return index
            }
            
            private mutating func insertLoading(_ cell: Cell) -> Int {
                for (index, cell) in cells.enumerated() {
                    switch cell.kind {
                    case .info:
                        continue
                    default:
                        cells.insert(cell, at: index)
                        return index
                    }
                }
                cells.append(cell)
                return cells.endIndex - 1

            }
            
            private mutating func insertTypingIndicator(_ cell: Cell) -> Int {
                cells.append(cell)
                return cells.endIndex - 1
            }
            
            private mutating func insertDateHeader(_ cell: Cell) -> Int {
                for (index, cell) in cells.enumerated() {
                    switch cell.kind {
                    case .info, .loading:
                        continue
                    default:
                        cells.insert(cell, at: index)
                        return index
                    }
                }
                cells.insert(cell, at: 0)
                return 0
            }
            
            private mutating func insertMessage(_ cell: Cell, message: Message) -> Int {
                for (index, cell) in cells.enumerated() {
                    switch cell.kind {
                    case .info, .loading, .dateHeader, .typingIndicator:
                        continue
                    case .message(let otherMessage):
                        if message < otherMessage {
                            cells.insert(cell, at: index)
                            return index
                        }
                    case .carousel(let mainCarouselMessage, _):
                        if message < mainCarouselMessage {
                            cells.insert(cell, at: index)
                            return index
                        }
                    }
                }
                cells.append(cell)
                return cells.endIndex - 1
            }
            
            private mutating func insertCarousel(_ cell: Cell, carousel: Message) -> Int {
                for (index, cell) in cells.enumerated() {
                    switch cell.kind {
                    case .info, .loading, .dateHeader, .typingIndicator:
                        continue
                    case .message(let message):
                        if carousel < message {
                            cells.insert(cell, at: index)
                            return index
                        }
                    case .carousel(let otherCarouselMessage, _):
                        if carousel < otherCarouselMessage {
                            cells.insert(cell, at: index)
                            return index
                        }
                    }
                }
                cells.append(cell)
                return cells.endIndex - 1
            }
            
            static func info(message: String, calendar: Calendar = .autoupdatingCurrent) -> Section {
                Section(
                    date: nil,
                    sectionKind: .info,
                    cells: [.info(message)],
                    calendar: calendar
                )
            }
            
            static func typingIndicator(calendar: Calendar = .autoupdatingCurrent) -> Section {
                Section(
                    date: nil,
                    sectionKind: .typingIndicator,
                    cells: [.typingIndicator()],
                    calendar: calendar
                )
            }
            
            static func loading(calendar: Calendar = .autoupdatingCurrent) -> Section {
                Section(
                    date: nil,
                    sectionKind: .loading,
                    cells: [.loading()],
                    calendar: calendar
                )
            }
            
            static func messages(messages: [Message], calendar: Calendar = .autoupdatingCurrent) -> Section? {
                guard let earliestMessageDate = messages.compactMap(\.time).sorted(by: <).first else { return nil }
                let startOfDateOfEarliestMessage = calendar.startOfDay(for: earliestMessageDate)
                let dateHeaderCell = Cell.date(startOfDateOfEarliestMessage, calendar: calendar)
                let messageCells = messages.compactMap { Cell.message($0, calendar: calendar) }
                let allCells: [Cell] = [dateHeaderCell] + messageCells
                return Section(
                    date: startOfDateOfEarliestMessage,
                    sectionKind: .messages,
                    cells: allCells,
                    calendar: calendar
                )
            }
        }
        
        struct Cell {
            let date: Date?
            let kind: CellKind
            let calander: Calendar
            
            private init(date: Date?, kind: CellKind, calender: Calendar) {
                self.date = date
                self.kind = kind
                self.calander = calender
            }
                        
            static func info(_ message: String, calendar: Calendar = .autoupdatingCurrent) -> Cell {
                Cell(date: nil, kind: .info(message), calender: calendar)
            }
            
            static func loading(calendar: Calendar = .autoupdatingCurrent) -> Cell {
                Cell(date: nil, kind: .loading, calender: calendar)
            }
            
            static func date(_ date: Date, calendar: Calendar) -> Cell {
                let startOfDay = calendar.startOfDay(for: date)
                return Cell(date: startOfDay, kind: .dateHeader(startOfDay), calender: calendar)
            }
            
            static func message(_ message: Message, calendar: Calendar = .autoupdatingCurrent) -> Cell? {
                guard
                    !hasQuickReplies(message),
                    message.ignore() == false
                else { return nil }
                
                let kind = MessagesStore.CellKind.message(message)
                return Cell(date: message.time, kind: kind, calender: calendar)
            }
            
            static func carousel(_ message: Message, calendar: Calendar = .autoupdatingCurrent) -> Cell? {
                guard let carousel = message.carousel else { return nil }
                let kind = CellKind.carousel(mainMessage: message, carousel: carousel)
                let date = message.time ?? carousel.compactMap(\.time).first
                return Cell(date: date, kind: kind, calender: calendar)
            }
            
            static func typingIndicator(calendar: Calendar = .autoupdatingCurrent) -> Cell {
                Cell(date: nil, kind: .typingIndicator, calender: calendar)
            }
            
            private static func hasQuickReplies(_ message: Message) -> Bool {
                if let quickReplies = message.quickReplies {
                    return !quickReplies.isEmpty
                } else {
                    return false
                }
            }
        }
        
        private(set) var welcomeMessage: String?
        private(set) var agentTyping = false
        private(set) var isLoading = false
        
        private(set) var sections: [Section]
        let calendar: Calendar
        
        var isEmpty: Bool {
            sections.isEmpty
        }
        
        var typingIndicatorIndex: Int? {
            sections.firstIndex(where: { $0.sectionKind == .typingIndicator })
        }
        
        init(welcomeMessage: String?, calendar: Calendar = .autoupdatingCurrent) {
            self.calendar = calendar
            self.welcomeMessage = welcomeMessage
            sections = [Section]()
            
            if let welcomeMessage {
                let section = Section.info(message: welcomeMessage, calendar: calendar)
                sections.append(section)
            }
        }
        
        mutating func insertSection(messages: [Message]) -> Int? {
            guard
                let newSection = Section.messages(messages: messages, calendar: calendar),
                let newSectionDate = newSection.date
            else { return nil }
            
            let insertionIndex = sections.firstIndex(where: { existingSection in
                if existingSection.sectionKind == .typingIndicator {
                    return true
                }
                guard let existingSectionDate = existingSection.date else {
                    return false
                }
                return existingSectionDate > newSectionDate
            })
            
            if let index = insertionIndex {
                sections.insert(newSection, at: index)
                return index
            } else if let typingIndicatorIndex {
                sections.insert(newSection, at: typingIndicatorIndex)
                return typingIndicatorIndex
            } else {
                sections.append(newSection)
                return sections.endIndex - 1
            }
        }
        
        /// append a message to the last message section, if available.
        /// - Parameters:
        ///   - message: Message to add
        /// - returns: A change, or none if there is no message section.
        mutating func insert(message: Message) -> SnapshotChange? {
            guard
                let cell = Cell.message(message, calendar: calendar),
                let date = message.time
            else { return nil }
            
            let sectionDate = startOfDay(date)
            var indexPaths = [IndexPath]()
            
            if let existingSectionIndex = getSectionIndex(for: sectionDate) {
                let index = sections[existingSectionIndex].insert(cell: cell)
                indexPaths.append(IndexPath(row: index, section: existingSectionIndex))
                return SnapshotChange(indexPaths: indexPaths, kind: .added)
            } else {
                let newSectionIndex = newMessageSectionIndex(for: sectionDate)
                guard let section = Section.messages(messages: [message], calendar: calendar) else { return nil }
                sections.insert(section, at: newSectionIndex)
                indexPaths.append(IndexPath(row: 0, section: newSectionIndex)) // Date Header
                indexPaths.append(IndexPath(row: 1, section: newSectionIndex)) // Message Cell
                return SnapshotChange(indexPaths: indexPaths, kind: .added)
            }
        }
        
        private func getSectionIndex(for date: Date) -> Int? {
            for (index, section) in sections.enumerated() {
                if section.date == date {
                    return index
                }
            }
            return nil
        }
        
        private func newMessageSectionIndex(for date: Date) -> Int {
            var index = sections.endIndex - 1
            while index >= 0 {
                let section = sections[index]
                defer { index -= 1 }
                switch section.sectionKind {
                case .messages:
                    guard let sectionDate = sections[index].date else { break }
                    if sectionDate > date {
                        return index + 1
                    }
                default:
                    continue
                }
            }
            
            if sections.last?.sectionKind == .typingIndicator {
                return sections.endIndex - 1
            } else {
                return sections.endIndex
            }
        }
        
        mutating func set(agentTyping: Bool) -> SnapshotChange? {
            guard self.agentTyping != agentTyping else { return nil }
            self.agentTyping = agentTyping
            return agentTyping ? addAgentTypingCell() : removeAgentTypingCell()
        }
        
        private mutating func addAgentTypingCell() -> SnapshotChange {
            let insertIndexPath = IndexPath(row: 0, section: sections.endIndex)
            sections.append(.typingIndicator())
            return SnapshotChange(indexPaths: [insertIndexPath], kind: .added)
        }
        
        private mutating func removeAgentTypingCell() -> SnapshotChange {
            let deletingIndexPath = IndexPath(row: 0, section: sections.endIndex - 1)
            _ = sections.popLast()
            return SnapshotChange(indexPaths: [deletingIndexPath], kind: .deleted)
        }
        
        mutating func setLoading(_ isLoading: Bool) -> SnapshotChange? {
            guard self.isLoading != isLoading else { return nil }
            self.isLoading = isLoading
            return isLoading ? addLoadingCell() : removeLoadingCell()
        }
        
        private mutating func addLoadingCell() -> SnapshotChange {
            let sectionIndexToInsert = welcomeMessage == nil ? 0 : 1
            sections.insert(.loading(), at: sectionIndexToInsert)
            return SnapshotChange(indexPaths: [IndexPath(row: 0, section: sectionIndexToInsert)], kind: .added)
        }
        
        private mutating func removeLoadingCell() -> SnapshotChange {
            let sectionIndexToRemove = welcomeMessage == nil ? 0 : 1
            sections.remove(at: sectionIndexToRemove)
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
            sections.insert(.info(message: welcomeMessage), at: .zero)
            return SnapshotChange(indexPaths: [insertedIndexPath], kind: .added)
        }
        
        private mutating func updateWelcomeMessageCell(_ welcomeMessage: String) -> SnapshotChange {
            let changedIndexPath = IndexPath(row: .zero, section: .zero)
            sections[0].set(cell: .info(welcomeMessage), at: .zero)
            return SnapshotChange(indexPaths: [changedIndexPath], kind: .changed)
        }
        
        private mutating func deleteWelcomeMessageCell() -> SnapshotChange {
            let deletedIndexPath = IndexPath(row: .zero, section: .zero)
            sections.remove(at: .zero)
            return SnapshotChange(indexPaths: [deletedIndexPath], kind: .deleted)
        }
        
        mutating func set(message updatedMessage: Message) -> SnapshotChange? {
            guard
                let messageDate = updatedMessage.time,
                let updatedCell = Cell.message(updatedMessage)
            else { return nil }
            let sectionDate = startOfDay(messageDate)
            guard let sectionIndex = getSectionIndex(for: sectionDate) else { return nil }
            for (index, cell) in sections[sectionIndex].cells.enumerated() {
                switch cell.kind {
                case .message(let oldMessage):
                    if oldMessage.id == updatedMessage.id || oldMessage.uuid == updatedMessage.uuid {
                        sections[sectionIndex].set(cell: updatedCell, at: index)
                        return SnapshotChange(indexPaths: [IndexPath(row: index, section: sectionIndex)], kind: .changed)
                    }
                default:
                    continue
                }
            }
            return nil
        }
        
        private func startOfDay(_ date: Date) -> Date {
            calendar.startOfDay(for: date)
        }
        
        func infoSection(message: String) -> Section {
            Section.info(message: message, calendar: calendar)
        }
        
        func typingIndicatorSection() -> Section {
            Section.typingIndicator(calendar: calendar)
        }
    }
}

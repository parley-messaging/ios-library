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
    private(set) var currentSnapshot: Snapshot
    private var isScrolledToBottom: Bool = false
    private var usesAdaptiveWelcomePosistioning = false
    
    @MainActor
    init(
        store: MessagesStore,
        display: ParleyMessagesDisplay?,
        usesAdaptiveWelcomePosistioning: Bool
    ) {
        self.store = store
        self.display = display
        self.usesAdaptiveWelcomePosistioning = usesAdaptiveWelcomePosistioning
        
        self.currentSnapshot = Snapshot(
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
        var snapshot = Snapshot(
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
        guard let change = currentSnapshot.set(agentTyping: isTyping) else { return }
        self.isAgentTyping = isTyping
        await store.apply(snapshot: currentSnapshot)
        await presentSnapshotChange(change)
        await MainActor.run {
            display?.displayScrollToBottom(animated: false)
        }
    }
    
    func presentUpdate(message: Message) async {
        guard let change = currentSnapshot.set(message: message) else { return }
        await store.apply(snapshot: currentSnapshot)
        await presentSnapshotChange(change)
    }
    
    func presentLoadingMessages(_ isLoading: Bool) async {
        guard let change = currentSnapshot.setLoading(isLoading) else { return }
        self.isLoadingMessages = isLoading
        await store.apply(snapshot: currentSnapshot)
        await presentSnapshotChange(change)
    }
    
    func presentAdd(message: Message) async {
        guard let change = currentSnapshot.insert(message: message) else { return }
        await store.apply(snapshot: currentSnapshot)
        await presentSnapshotChange(change)
        if isScrolledToBottom, let lastIndexPath = change.indexPaths.last {
            await MainActor.run {
                display?.scrollTo(indexPaths: lastIndexPath, at: .bottom, animated: true)
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
    
    func presentSnapshotChange(_ change: Snapshot.SnapshotChange) async {
        guard change.indexPaths.isEmpty == false else { return }
        
        await MainActor.run {
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
        
        
        // MARK: - Helpers
        
        private struct WelcomePosition {
            let section: Int
            let row: Int
            var indexPath: IndexPath { .init(row: row, section: section) }
        }
        
        // MARK: - Public types (unchanged, trimmed for brevity)
        
        struct Section {
            let date: Date?
            let sectionKind: SectionKind
            var cells: [Cell]
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
                    return insertInfo(cell)
                case .loading:
                    return insertLoading(cell)
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
            
            private mutating func insertMessage(_ cell: Cell, message: Message) -> Int {
                for (index, cell) in cells.enumerated() {
                    switch cell.kind {
                    case .info, .loading, .typingIndicator:
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
                    case .info, .loading, .typingIndicator:
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
                let messageCells = messages.compactMap { Cell.message($0, calendar: calendar) }
                return Section(
                    date: startOfDateOfEarliestMessage,
                    sectionKind: .messages(startOfDateOfEarliestMessage),
                    cells: messageCells,
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
            
            static func message(_ message: Message, calendar: Calendar = .autoupdatingCurrent) -> Cell? {
                guard
                    !hasQuickReplies(message),
                    message.ignore() == false
                else { return nil }
                
                let kind = MessagesStore.CellKind.message(message)
                return Cell(date: message.time, kind: kind, calender: calendar)
            }
            
            static func carousel(_ message: Message, calendar: Calendar = .autoupdatingCurrent) -> Cell? {
                let carousel = message.carousel
                let kind = CellKind.carousel(mainMessage: message, carousel: carousel)
                let date = message.time
                return Cell(date: date, kind: kind, calender: calendar)
            }
            
            static func typingIndicator(calendar: Calendar = .autoupdatingCurrent) -> Cell {
                Cell(date: nil, kind: .typingIndicator, calender: calendar)
            }
            
            private static func hasQuickReplies(_ message: Message) -> Bool {
                return !message.quickReplies.isEmpty
            }
        }
        
        // MARK: - Stored properties
        
        private(set) var welcomeMessage: String?
        private(set) var agentTyping = false
        private(set) var isLoading = false
        
        private(set) var sections: [Section]
        let calendar: Calendar
        
        private let adaptiveWelcomePositioning: Bool
        
        // MARK: - Convenience
        
        var typingIndicatorIndex: Int? {
            sections.firstIndex(where: { $0.sectionKind == .typingIndicator })
        }
        
        var isEmpty: Bool { sections.isEmpty }
        
        // MARK: - Initialisation
        
        init(
            welcomeMessage: String?,
            calendar: Calendar = .autoupdatingCurrent,
            adaptiveWelcomePositioning: Bool
        ) {
            self.calendar = calendar
            self.adaptiveWelcomePositioning = adaptiveWelcomePositioning
            self.welcomeMessage = welcomeMessage
            sections = []
            
            if let welcomeMessage, adaptiveWelcomePositioning == false {
                sections.append(.info(message: welcomeMessage, calendar: calendar))
            }
        }
        
        // MARK: - Welcome message
        
        mutating func set(welcomeMessage: String?) -> SnapshotChange? {
            guard self.welcomeMessage != welcomeMessage else { return nil }
            
            if adaptiveWelcomePositioning {
                switch (self.welcomeMessage, welcomeMessage) {
                case (nil, .some(let new)):
                    self.welcomeMessage = new
                    return adaptiveAddWelcome(new)
                case (.some, .some(let new)):
                    self.welcomeMessage = new
                    return adaptiveUpdateWelcome(new)
                case (.some, nil):
                    self.welcomeMessage = nil
                    return adaptiveDeleteWelcome()
                default:
                    return nil
                }
            } else {
                if let welcomeMessage, self.welcomeMessage == nil {
                    self.welcomeMessage = welcomeMessage
                    return defaultAddWelcome(welcomeMessage)
                } else if let welcomeMessage {
                    self.welcomeMessage = welcomeMessage
                    return defaultUpdateWelcome(welcomeMessage)
                } else {
                    return defaultDeleteWelcome()
                }
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
                let cell = Cell.message(message, calendar: calendar)
            else { return nil }
            
            let date = message.time
            
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
                indexPaths.append(IndexPath(row: 0, section: newSectionIndex))
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
        
        private mutating func defaultAddWelcome(_ message: String) -> SnapshotChange {
            sections.insert(.info(message: message), at: .zero)
            return .init(indexPaths: [.init(row: 0, section: 0)], kind: .added)
        }
        
        private mutating func defaultUpdateWelcome(_ message: String) -> SnapshotChange {
            sections[0].set(cell: .info(message), at: 0)
            return .init(indexPaths: [.init(row: 0, section: 0)], kind: .changed)
        }
        
        private mutating func defaultDeleteWelcome() -> SnapshotChange {
            sections.remove(at: 0)
            return .init(indexPaths: [.init(row: 0, section: 0)], kind: .deleted)
        }
        
        // MARK: smart add / update / delete
        
        private mutating func adaptiveAddWelcome(_ message: String) -> SnapshotChange {
            let position = adaptiveWelcomeInsertionPosition()
            insertWelcomeCell(message, at: position)
            return .init(indexPaths: [position.indexPath], kind: .added)
        }
        
        private mutating func adaptiveUpdateWelcome(_ message: String) -> SnapshotChange? {
            guard let current = findWelcomeIndexPath() else {
                // nothing found, just add it
                return adaptiveAddWelcome(message)
            }
            sections[current.section].set(cell: .info(message), at: current.row)
            return .init(indexPaths: [current], kind: .changed)
        }
        
        private mutating func adaptiveDeleteWelcome() -> SnapshotChange? {
            guard let current = findWelcomeIndexPath() else { return nil }
            var deletedSectionIndex: Int?
            sections[current.section].cells.remove(at: current.row)
            if sections[current.section].cells.isEmpty {
                sections.remove(at: current.section)
                deletedSectionIndex = current.section
            }
            // for diff-util a single row deletion is enough – section deletion handled elsewhere
            return .init(indexPaths: [current], kind: .deleted)
        }
        
        // MARK: insertion helpers
        
        private mutating func insertWelcomeCell(_ message: String, at pos: WelcomePosition) {
            if sections.indices.contains(pos.section) {
                // insert in existing section
                sections[pos.section].cells.insert(.info(message), at: pos.row)
            } else {
                // create section
                sections.insert(.info(message: message), at: pos.section)
            }
        }
        
        private func adaptiveWelcomeInsertionPosition() -> WelcomePosition {
            // 1. Empty conversation  -> very top (own section 0)
            guard !sections.isEmpty else { return .init(section: 0, row: 0) }
            
            // 2. Try to place inside the “today” section
            let today = calendar.startOfDay(for: Date())
            if let todaySectionIdx = sections.firstIndex(where: {
                if case .messages(let date) = $0.sectionKind { return date == today }
                return false
            }) {
                return .init(section: todaySectionIdx, row: 0)
            }
            
            // 3. Otherwise bottom, but above typing indicator if it exists
            if let typingIdx = typingIndicatorIndex {
                return .init(section: typingIdx, row: 0)
            } else {
                return .init(section: sections.endIndex, row: 0)
            }
        }
        
        private func findWelcomeIndexPath() -> IndexPath? {
            guard let old = welcomeMessage else { return nil }
            for (sectionIdx, section) in sections.enumerated() {
                for (rowIdx, cell) in section.cells.enumerated() {
                    if case .info(let msg) = cell.kind, msg == old {
                        return .init(row: rowIdx, section: sectionIdx)
                    }
                }
            }
            return nil
        }
        
        // MARK: - Loading
        
        mutating func setLoading(_ isLoading: Bool) -> SnapshotChange? {
            guard self.isLoading != isLoading else { return nil }
            self.isLoading = isLoading
            return isLoading ? addLoadingCell() : removeLoadingCell()
        }
        
        private mutating func addLoadingCell() -> SnapshotChange {
            let insertIndex: Int
            if !adaptiveWelcomePositioning {
                insertIndex = welcomeMessage == nil ? 0 : 1
            } else {
                // Top unless welcome is sitting in its own first section
                insertIndex = 0
            }
            sections.insert(.loading(), at: insertIndex)
            return .init(indexPaths: [.init(row: 0, section: insertIndex)], kind: .added)
        }
        
        private mutating func removeLoadingCell() -> SnapshotChange {
            let removeIndex: Int
            if !adaptiveWelcomePositioning {
                removeIndex = welcomeMessage == nil ? 0 : 1
            } else {
                removeIndex = sections.firstIndex { $0.sectionKind == .loading } ?? 0
            }
            sections.remove(at: removeIndex)
            return .init(indexPaths: [.init(row: 0, section: removeIndex)], kind: .deleted)
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
            let messageDate = updatedMessage.time
            guard let updatedCell = Cell.message(updatedMessage) else { return nil }
            let sectionDate = startOfDay(messageDate)
            guard let sectionIndex = getSectionIndex(for: sectionDate) else { return nil }
            for (index, cell) in sections[sectionIndex].cells.enumerated() {
                switch cell.kind {
                case .message(let oldMessage):
                    if oldMessage.remoteId == updatedMessage.remoteId || oldMessage.id == updatedMessage.id {
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

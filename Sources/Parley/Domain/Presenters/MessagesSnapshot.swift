import Foundation

struct MessagesSnapshot {
    
    typealias CellKind = MessagesStore.CellKind
    typealias SectionKind = MessagesStore.SectionKind
    
    
    // MARK: - Helpers
    
    private struct WelcomePosition {
        let section: Int
        var indexPath: IndexPath { .init(row: .zero, section: section) }
    }
    
    // MARK: - Public types (unchanged, trimmed for brevity)
    
    struct Section {
        let date: Date?
        var sectionKind: SectionKind
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
        
        static func info(message: String, date: Date?, calendar: Calendar = .autoupdatingCurrent) -> Section {
            Section(
                date: nil,
                sectionKind: .info(date),
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
        
        static func messages(messages: [Message], showsDate: Bool, calendar: Calendar = .autoupdatingCurrent) -> Section? {
            guard let earliestMessageDate = messages.earliestMessage?.time else {
                assertionFailure("At least one message should have a date") ; return nil
            }
            let startOfDateOfEarliestMessage = calendar.startOfDay(for: earliestMessageDate)
            let messageCells = messages.compactMap { Cell.message($0, calendar: calendar) }
            return Section(
                date: startOfDateOfEarliestMessage,
                sectionKind: .messages(showsDate ? startOfDateOfEarliestMessage : nil),
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
        
        if let welcomeMessage {
            sections.append(.info(message: welcomeMessage, date: nil, calendar: calendar))
        }
    }
    
    // MARK: - Welcome message
    
    mutating func set(welcomeMessage: String?) -> SnapshotChange? {
        switch (self.welcomeMessage, welcomeMessage) {
        case (nil, .some(let new)):
            self.welcomeMessage = new
            return addInfoSection(new)
        case (.some(let existing), .some(let new)):
            self.welcomeMessage = new
            if existing != new {
                return updateInfoSection(new)
            } else {
                guard
                    let currentInfoSection = findInfoSectionIndex(),
                    let messageSection = sections[safe: currentInfoSection + 1],
                    let messageSectionDate = messageSection.date,
                    case .messages(let dateHeader) = messageSection.sectionKind,
                    dateHeader == nil
                else { return nil }
                
                sections[currentInfoSection].sectionKind = .info(messageSectionDate)
                return SnapshotChange(sectionChanges: [
                    SnapshotChange.SectionChange(section: currentInfoSection, kind: .reload)
                ])
            }
        case (.some, nil):
            self.welcomeMessage = nil
            return deleteInfoSection()
        default:
            return nil
        }
    }
    
    /// Inserts a new section from messages from the same day
    /// - Parameter messages: messages from the same day
    /// - Returns: A change to the snapshot
    mutating func insertSection(messages: [Message]) -> SnapshotChange? {
        guard let earliestMessageDate = messages.earliestMessage?.time else { return nil }
        let isMessagesFromToday = calendar.isDateInToday(earliestMessageDate)
        let shouldShowNewMessageDate = if adaptiveWelcomePositioning {
            isMessagesFromToday ? false : true
        } else {
            true
        }
        
        guard
            let newSection = Section.messages(
                messages: messages,
                showsDate: shouldShowNewMessageDate,
                calendar: calendar
            ),
            let newSectionDate = newSection.date
        else { return nil }
        
        var change = SnapshotChange()
        
        let insertionIndex = newMessageSectionIndex(for: newSectionDate)
        
        if shouldShowNewMessageDate == false,
           adaptiveWelcomePositioning,
           let infoSectionIndex = findInfoSectionIndex()
        {
            sections[infoSectionIndex].sectionKind = .info(calendar.startOfDay(for: earliestMessageDate))
            change.sectionChanges.append(
                SnapshotChange.SectionChange(section: infoSectionIndex, kind: .reload)
            )
        }
        
        sections.insert(newSection, at: insertionIndex)
        
        let sectionChange = SnapshotChange.SectionChange(section: insertionIndex, kind: .insert)
        let rowChanges = messages.indices.map { row in
            SnapshotChange.RowChange(
                indexPath: IndexPath(row: row, section: insertionIndex),
                kind: .insert
            )
        }
        change.sectionChanges.append(sectionChange)
        change.rowChanges.append(contentsOf: rowChanges)
        return change
    }
    
    /// append a message to the last message section, if available.
    /// - Parameters:
    ///   - message: Message to add
    /// - returns: A change, or none if there is no message section.
    mutating func insert(message: Message) -> SnapshotChange? {
        guard let cell = Cell.message(message, calendar: calendar) else { return nil }
        
        let date = message.time
        let sectionDate = startOfDay(date)
        let isMessageToday = calendar.isDateInToday(date)
        
        if let existingSectionIndex = findSectionIndex(for: sectionDate) {
            let index = sections[existingSectionIndex].insert(cell: cell)
            return SnapshotChange(rowChanges: [
                SnapshotChange.RowChange(
                    indexPath: IndexPath(row: index, section: existingSectionIndex),
                    kind: .insert
                )
            ])
        } else {
            var snapshotChanges = SnapshotChange()
            
            if adaptiveWelcomePositioning,
               let infoSectionIndex = findInfoSectionIndex(),
               isMessageToday
            {
                sections[infoSectionIndex].sectionKind = .info(sectionDate)
                snapshotChanges.sectionChanges.append(
                    SnapshotChange.SectionChange(section: infoSectionIndex, kind: .reload)
                )
            }
            
            // Creating new section
            let newSectionIndex = newMessageSectionIndex(for: sectionDate)
            guard let section = Section.messages(
                messages: [message],
                showsDate: (isMessageToday && welcomeMessage != nil) ? false : true,
                calendar: calendar
            ) else { return nil }
            sections.insert(section, at: newSectionIndex)
            snapshotChanges.sectionChanges.append(SnapshotChange.SectionChange(section: newSectionIndex, kind: .insert))
            snapshotChanges.rowChanges.append(
                SnapshotChange.RowChange(
                    indexPath: IndexPath(row: 0, section: newSectionIndex),
                    kind: .insert
                )
            )
            
            return snapshotChanges
        }
    }
    
    private func findSectionIndex(for date: Date) -> Int? {
        for (index, section) in sections.enumerated() {
            if section.date == date {
                return index
            }
        }
        return nil
    }
    
    private func newMessageSectionIndex(for date: Date) -> Int {
        var indexAfterLastMessageSection = sections.endIndex - 1
        while indexAfterLastMessageSection >= 0 {
            let section = sections[indexAfterLastMessageSection]
            defer { indexAfterLastMessageSection -= 1 }
            switch section.sectionKind {
            case .messages:
                guard let sectionDate = sections[indexAfterLastMessageSection].date else { break }
                if sectionDate > date {
                    return indexAfterLastMessageSection
                }
            default:
                continue
            }
        }
        
        // No past message section found, looking to insert at the bottom
        let isMessageToday = calendar.isDateInToday(date)
        return if sections.last?.sectionKind == .typingIndicator {
            if adaptiveWelcomePositioning,
               case .info = sections[sections.endIndex - 2].sectionKind,
               isMessageToday == false
            {
                sections.endIndex - 2
            } else {
                sections.endIndex - 1
            }
        } else {
            if adaptiveWelcomePositioning,
                case .info = sections.last?.sectionKind,
               isMessageToday == false
            {
                sections.endIndex - 1
            } else {
                sections.endIndex
            }
        }
    }
    
    private func newInfoSectionIndex() -> Int {
        if adaptiveWelcomePositioning {
            if sections.last?.sectionKind == .typingIndicator {
                return sections.endIndex - 1
            } else {
                return sections.endIndex
            }
        } else {
            return .zero
        }
    }
    
    // MARK: adaptive add / update / delete
    
    private mutating func addInfoSection(_ message: String) -> SnapshotChange {
        var changes = SnapshotChange()
        let (section, date) = welcomeInsertionPosition()
        
        sections.insert(.info(message: message, date: date, calendar: calendar), at: section)
        changes.sectionChanges.append(SnapshotChange.SectionChange(section: section, kind: .insert))
        changes.rowChanges.append(SnapshotChange.RowChange(indexPath: IndexPath(row: 0, section: section), kind: .insert))
        
        // Check if next section is a messages section
        if adaptiveWelcomePositioning,
           let nextSectionSection = sections[safe: section + 1],
           case .messages(let messageDate) = nextSectionSection.sectionKind,
           messageDate != nil,
           date != nil
        {
            // There is a message section at the index where we are trying to insert. This is possible, but it would result in a duplicate date header. Therefore, we need to remove the date header from the current message section and reload the section to make sure it removes it in the tableview.
            sections[section + 1].sectionKind = .messages(nil)
            changes.sectionChanges.append(
                SnapshotChange.SectionChange(
                    section: section + 1,
                    kind: .reload
                )
            )
        }
        
        
        return changes
    }
    
    private mutating func updateInfoSection(_ message: String) -> SnapshotChange? {
        guard let infoSectionIndex = findInfoSectionIndex() else { return nil }
        sections[infoSectionIndex].set(cell: .info(message), at: infoSectionIndex)
        return SnapshotChange(rowChanges: [
            SnapshotChange.RowChange(
                indexPath: IndexPath(row: 0, section: infoSectionIndex),
                kind: .reload
            )
        ])
    }
    
    private mutating func deleteInfoSection() -> SnapshotChange? {
        guard let currentInfoSectionIndex = findInfoSectionIndex() else { return nil }
        
        sections.remove(at: currentInfoSectionIndex)
        
        return SnapshotChange(sectionChanges: [
            SnapshotChange.SectionChange(section: currentInfoSectionIndex, kind: .delete)
        ])
    }
    
    private func welcomeInsertionPosition() -> (sectionIndex: Int, Date?) {
        if sections.isEmpty || adaptiveWelcomePositioning == false {
            return (.zero, nil)
        }
        
        // 2. Try to place with the "today" section
        let today = calendar.startOfDay(for: Date())
        if let todaySectionIndex = findTodayMessageSection() {
            // Return position to insert info section before messages section
            return (todaySectionIndex, today)
        }
        
        // 3. Otherwise bottom of chat, but above typing indicator if it exists
        if let typingIndex = typingIndicatorIndex {
            // Insert new section before typing indicator
            return (typingIndex, nil)
        } else {
            // Insert new section at the very end
            return (sections.endIndex, nil)
        }
    }
    
    private func findTodayMessageSection() -> Int? {
        let today = calendar.startOfDay(for: Date())
        return sections.firstIndex(where: {
            if case .messages(let date) = $0.sectionKind {
                return date == today
            }
            return false
        })
    }
    
    private func findInfoSectionIndex() -> Int? {
        guard welcomeMessage != nil else { return nil }
        
        guard adaptiveWelcomePositioning else {
            if case .info = sections.first?.sectionKind {
                return .zero
            } else {
                return nil
            }
        }
        
        for (sectionIndex, section) in sections.enumerated() {
            if case .info = section.sectionKind {
                return sectionIndex
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
        let insertIndex: Int = adaptiveWelcomePositioning ? 0 : welcomeMessage == nil ? 0 : 1
        sections.insert(.loading(calendar: calendar), at: insertIndex)
        return SnapshotChange(sectionChanges: [
            SnapshotChange.SectionChange(section: insertIndex, kind: .insert)
        ], rowChanges: [
            SnapshotChange.RowChange(indexPath: IndexPath(row: 0, section: insertIndex), kind: .insert)
        ])
    }
    
    private mutating func removeLoadingCell() -> SnapshotChange? {
        let removeIndex: Int
        if adaptiveWelcomePositioning {
            guard let loadingSectionIndex = sections.firstIndex(where: { $0.sectionKind == .loading }) else {
                return nil
            }
            removeIndex = loadingSectionIndex
        } else {
            removeIndex = welcomeMessage == nil ? 0 : 1
        }
        sections.remove(at: removeIndex)
        return SnapshotChange(sectionChanges: [
            SnapshotChange.SectionChange(section: removeIndex, kind: .delete)
        ])
    }
    
    mutating func set(agentTyping: Bool) -> SnapshotChange? {
        guard self.agentTyping != agentTyping else { return nil }
        self.agentTyping = agentTyping
        return agentTyping ? addAgentTypingCell() : removeAgentTypingCell()
    }
    
    private mutating func addAgentTypingCell() -> SnapshotChange {
        let insertIndexPath = IndexPath(row: 0, section: sections.endIndex)
        sections.append(.typingIndicator())
        return SnapshotChange(sectionChanges: [
            SnapshotChange.SectionChange(section: insertIndexPath.section, kind: .insert)
        ], rowChanges: [
            SnapshotChange.RowChange(indexPath: insertIndexPath, kind: .insert)
        ])
    }
    
    private mutating func removeAgentTypingCell() -> SnapshotChange {
        _ = sections.popLast()
        return SnapshotChange(sectionChanges: [
            SnapshotChange.SectionChange(section: sections.endIndex, kind: .delete)
        ])
    }
    
    mutating func set(message updatedMessage: Message) -> SnapshotChange? {
        let messageDate = updatedMessage.time
        guard let updatedCell = Cell.message(updatedMessage) else { return nil }
        let sectionDate = startOfDay(messageDate)
        guard let sectionIndex = findSectionIndex(for: sectionDate) else { return nil }
        for (index, cell) in sections[sectionIndex].cells.enumerated() {
            switch cell.kind {
            case .message(let oldMessage):
                if oldMessage.remoteId == updatedMessage.remoteId || oldMessage.id == updatedMessage.id {
                    sections[sectionIndex].set(cell: updatedCell, at: index)
                    return SnapshotChange(rowChanges: [
                        SnapshotChange.RowChange(indexPath: IndexPath(row: index, section: sectionIndex), kind: .reload)
                    ])
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
        Section.info(message: message, date: nil, calendar: calendar)
    }
    
    func typingIndicatorSection() -> Section {
        Section.typingIndicator(calendar: calendar)
    }
}

extension MessagesSnapshot {
    
    subscript(section sectionIndex: Int) -> MessagesSnapshot.SectionKind? {
        self.sections[safe: sectionIndex]?.sectionKind
    }
    
    subscript(section sectionIndex: Int, row rowIndex: Int) -> MessagesSnapshot.CellKind? {
        self.sections[safe: sectionIndex]?.cells[safe: rowIndex]?.kind
    }
}

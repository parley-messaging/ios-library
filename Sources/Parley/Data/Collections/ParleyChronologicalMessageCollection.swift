import Foundation

protocol ParleyMessageSection {
    var date: Date { get }
    var messages: [Message] { get }
}

public struct ParleyChronologicalMessageCollection {
    
    private var indexMap = [Date: [Section].Index]()
    private(set) var sections = [Section]()
    private let calendar: Calendar
    
    public init(calendar: Calendar) {
        self.calendar = calendar
    }
    
    struct Position: Equatable {
        let section: Int
        let row: Int
        
        static let zero = Position(section: .zero, row: .zero)
    }
    
    subscript(section sectionIndex: Int, row rowIndex: Int) -> Message {
        get {
            sections[sectionIndex].messages[rowIndex]
        } set(newMessage) {
            sections[sectionIndex].messages[rowIndex] = newMessage
        }
    }
    
    subscript(position: Position) -> Message {
        get {
            sections[position.section].messages[position.row]
        } set(newMessage) {
            sections[position.section].messages[position.row] = newMessage
        }
    }
}

// MARK: Methods
extension ParleyChronologicalMessageCollection {
    
    @discardableResult
    mutating func add(message: Message) -> Position {
        let messageDate = calendar.startOfDay(for: message.time)
        
        if let sectionIndex = indexMap[messageDate] {
            let rowIndex = sections[sectionIndex].add(message: message)
            return Position(section: sectionIndex, row: rowIndex)
        } else {
            let newSection = Section(date: messageDate, message: message)
            let insertIndex: Int
            if let smallerThanIndex = sections.firstIndex(where: { newSection.date < $0.date }) {
                insertIndex = smallerThanIndex
            } else {
                insertIndex = sections.endIndex
            }
            sections.insert(newSection, at: insertIndex)
            index()
            return Position(section: insertIndex, row: .zero)
        }
    }
    
    mutating func set(collection: MessageCollection) {
        set(messages: collection.messages)
    }
    
    mutating func set(messages: [Message]) {
        sections.removeAll(keepingCapacity: true)
        
        let messagesByDate = messages.byDate(calender: calendar)
        sections.reserveCapacity(messagesByDate.keys.count)
        let sectionsByDate = messagesByDate.map { (date: Date, messages: [Message]) in
            Section(date: date, messages: messages)
        }
        
        sections = sectionsByDate
        sort()
    }
    
    func lastPosistion() -> Position? {
        let lastSection = sections.count - 1
        guard lastSection >= .zero else { return nil }
        
        let lastRow = sections[lastSection].messages.count - 1
        guard lastRow >= .zero else { return nil }
        
        return Position(section: lastSection, row: lastRow)
    }
    
    @discardableResult
    mutating func update(message updatedMessage: Message) -> Position? {
        guard let messagePosistion = find(message: updatedMessage) else { return nil }
        sections[messagePosistion.section].messages.remove(at: messagePosistion.row)
        return add(message: updatedMessage)
    }
    
    func find(message messageToFind: Message) -> Position? {
        for (sectionIndex, section) in sections.enumerated() {
            for (row, message) in section.messages.enumerated() {
                if message.id == messageToFind.id {
                    return Position(section: sectionIndex, row: row)
                }
            }
        }
        return nil
    }
    
    mutating func clear() {
        indexMap.removeAll()
        sections.removeAll()
    }
}

// MARK: Privates
private extension ParleyChronologicalMessageCollection {
    
    mutating func sort() {
        sections.sort(by: <)
        index()
    }
    
    mutating func index() {
        indexMap.removeAll(keepingCapacity: true)
        for (index, section) in sections.enumerated() {
            indexMap[section.date] = index
        }
    }
}

// MARK: Section
extension ParleyChronologicalMessageCollection {

    struct Section: ParleyMessageSection, Comparable {
        let date: Date
        fileprivate(set) var messages: [Message]
        
        init(date: Date, message: Message) {
            self.date = date
            self.messages = [Message]()
            self.messages.append(message)
        }
        
        init(date: Date, messages: [Message]) {
            self.date = date
            self.messages = messages
            self.sort()
        }
        
        mutating func add(message: Message) -> Int {
             
            var index = messages.endIndex
            
            // Find correct index from bottom up
            while index > 0 {
                let previousIndex = index - 1
                let previousMessage = messages[previousIndex]
                
                if previousMessage.time > message.time {
                    index -= 1
                    continue
                } else {
                    messages.insert(message, at: index)
                    return index
                }
            }
            
            messages.insert(message, at: index)
            return index
        }
        
        mutating func set(messages: [Message]) {
            self.messages = messages
            sort()
        }
        
        private mutating func sort() {
            messages.sort(by: <)
        }
        
        static func < (lhs: Section, rhs: Section) -> Bool {
            lhs.date < rhs.date
        }
    }
}

extension ParleyChronologicalMessageCollection: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        var description: String = ""
        for section in sections {
            description += "*\(section.date.asDate())*\n"
            
            for message in section.messages {
                guard let messageText = message.message else { continue }
                description += "\t\(messageText.prefix(20))\n"
            }
        }
        return description
    }
}

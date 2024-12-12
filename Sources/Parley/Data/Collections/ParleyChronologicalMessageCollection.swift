import Foundation

protocol ParleyMessageSection {
    var date: Date { get }
    var messages: [Message] { get }
}

public struct ParleyChronologicalMessageCollection {
    
    private var indexMap = [Date: Int]()
    private(set) var sections = [Section]()
    private let calender: Calendar
    
    public init(calender: Calendar) {
        self.calender = calender
    }
    
    struct Posisition: Equatable {
        let section: Int
        let row: Int
        
        static let zero = Posisition(section: .zero, row: .zero)
    }
    
    subscript(section sectionIndex: Int, row rowIndex: Int) -> Message {
        get {
            sections[sectionIndex].messages[rowIndex]
        } set(newMessage) {
            sections[sectionIndex].messages[rowIndex] = newMessage
        }
    }
}

// MARK: Methods
extension ParleyChronologicalMessageCollection {
    
    mutating func add(message: Message) -> Posisition {
        assert(message.time != nil, "time may not be empty")
        let messageDate = calender.startOfDay(for: message.time!)
        
        if let sectionIndex = indexMap[messageDate] {
            let rowIndex = sections[sectionIndex].add(message: message)
            return Posisition(section: sectionIndex, row: rowIndex)
        } else {
            let newSection = Section(date: messageDate, message: message)
            let insertIndex: Int
            if let largerThanIndex = sections.firstIndex(where: { newSection.date < $0.date }) {
                insertIndex = largerThanIndex + 1
            } else {
                insertIndex = sections.endIndex
            }
            sections.insert(newSection, at: insertIndex)
            index()
            return Posisition(section: insertIndex, row: .zero)
        }
    }
    
    mutating func set(collection: MessageCollection) {
        set(messages: collection.messages)
    }
    
    mutating func set(messages: [Message]) {
        self.sections.removeAll(keepingCapacity: true)
        
        let messagesByDate = messages.byDate(calender: calender)
        self.sections.reserveCapacity(messagesByDate.keys.count)
        let sectionsByDate = messagesByDate.map { (date: Date, messages: [Message]) in
            Section(date: date, messages: messages)
        }
        
        self.sections = sectionsByDate
        sort()
    }
    
    func lastPosistion() -> Posisition {
        guard !sections.isEmpty else { return .zero }
        let lastSection = sections.endIndex - 1
        let lastRow = sections[lastSection].messages.endIndex - 1
        return Posisition(section: lastSection, row: lastRow)
    }
    
    mutating func update(message updatedMessage: Message) {
        guard let messagePosistion = find(message: updatedMessage) else { return }
        sections[messagePosistion.section].messages.remove(at: messagePosistion.row)
        _ = add(message: updatedMessage)
    }
    
    func find(message messageToFind: Message) -> Posisition? {
        for (sectionIndex, section) in sections.enumerated() {
            for (row, message) in section.messages.enumerated() {
                if message.id == messageToFind.id || message.uuid == messageToFind.uuid {
                    return Posisition(section: sectionIndex, row: row)
                }
            }
        }
        return nil
    }
    
    func getAllMessages() -> [Message] {
        var messages = [Message]()
        for section in sections {
            messages.append(contentsOf: section.messages)
        }
        return messages
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
        var messages: [Message]
        
        init(date: Date, message: Message) {
            self.date = date
            self.messages = [Message]()
            self.messages.append(message)
        }
        
        init(date: Date, messages: [Message]) {
            self.date = date
            self.messages = messages.filter({ $0.time != nil })
            self.sort()
        }
        
        mutating func add(message: Message) -> Int {
            assert(message.time != nil, "time may not be empty")
             
            var index = messages.endIndex
            
            while index > 0 {
                let previousIndex = index - 1
                let previousMessage = messages[previousIndex]
                
                if previousMessage.time! > message.time! {
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
            self.messages = messages.filter({ $0.time != nil })
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

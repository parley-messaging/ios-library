import Testing
import XCTest
@testable import Parley

@Suite("Chronological Message Collection Tests")
class ChronologicalMessageCollectionTests {
    
    @Test
    func creationIsEmpty() {
        let collection = makeCollection()
        
        #expect(collection.sections.isEmpty)
        #expect(collection.lastPosistion() == nil)
    }
    
    @Test
    func addMessageToEmtyCollection() {
        var collection = makeCollection()
        let message = Message.makeTestData(time: Date())
        let posistion = collection.add(message: message)
        #expect(posistion == .zero)
        #expect(collection[section: 0, row: 0] === message)
        #expect(collection.sections.count == 1)
        checkChronologicalOrder(collection)
    }
    
    @Test
    func addMessageToNonEmptyCollectionInTheSameSection() {
        var collection = makeCollection()
        let firstMessage = Message.makeTestData(time: Date())
        let firstMessagePosistion = collection.add(message: firstMessage)
        
        let secondMessage = Message.makeTestData(time: Date(timeIntervalSinceNow: 1))
        let secondMessagePosistion = collection.add(message: secondMessage)
        
        #expect(firstMessagePosistion == .init(section: 0, row: 0))
        #expect(secondMessagePosistion == .init(section: 0, row: 1))
        #expect(collection[section: 0, row: 0] === firstMessage)
        #expect(collection[section: 0, row: 1] === secondMessage)
        #expect(collection.sections.count == 1)
        checkChronologicalOrder(collection)
    }
    
    @Test
    func addMessageToNonEmptyCollectionInDifferentSection() {
        var collection = makeCollection()
        let firstMessage = Message.makeTestData(time: Date(timeIntSince1970: 1))
        let firstMessagePosistion = collection.add(message: firstMessage)
        
        let secondMessage = Message.makeTestData(time: Date())
        let secondMessagePosistion = collection.add(message: secondMessage)
        
        #expect(firstMessagePosistion == .init(section: 0, row: 0))
        #expect(secondMessagePosistion == .init(section: 1, row: 0))
        #expect(collection[section: 0, row: 0] === firstMessage)
        #expect(collection[section: 1, row: 0] === secondMessage)
        #expect(collection.sections.count == 2)
        checkChronologicalOrder(collection)
    }
    
    @Test
    func setMessagesInSameSectionCollection() {
        var collection = makeCollection()
        let messages: [Message] = [
            .makeTestData(id: 0, time: Date(timeIntSince1970: 1)),
            .makeTestData(id: 1, time: Date(timeIntSince1970: 2)),
            .makeTestData(id: 2, time: Date(timeIntSince1970: 3)),
        ]
        
        collection.set(messages: messages)
        
        #expect(collection[section: .zero, row: 0] === messages[0])
        #expect(collection[section: .zero, row: 1] === messages[1])
        #expect(collection[section: .zero, row: 2] === messages[2])
        #expect(collection.sections.count == 1)
        checkChronologicalOrder(collection)
    }
    
    @Test
    func setMessageCollectionInSameSectionCollection() {
        var collection = makeCollection()
        let messages: [Message] = [
            .makeTestData(id: 0, time: Date(timeIntSince1970: 1)),
            .makeTestData(id: 1, time: Date(timeIntSince1970: 2)),
            .makeTestData(id: 2, time: Date(timeIntSince1970: 3)),
        ]
        
        let messageCollection = MessageCollection.makeTestData(messages: messages)
        
        collection.set(collection: messageCollection)
        
        #expect(collection[section: .zero, row: 0] === messages[0])
        #expect(collection[section: .zero, row: 1] === messages[1])
        #expect(collection[section: .zero, row: 2] === messages[2])
        #expect(collection.sections.count == 1)
        checkChronologicalOrder(collection)
    }
    
    @Test(arguments: 1...10)
    func addSortedMessagesInTheSameSection(count: Int) async throws {
        var collection = makeCollection()
        let range = (0...count)
        
        var messages = [Message]()
        
        for i in range {
            let message = Message()
            message.time = .init(timeIntSince1970: i + 1)
            messages.append(message)
        }
        
        for message in messages {
            _ = collection.add(message: message)
        }
        
        for i in range {
            #expect(collection[section: .zero, row: i] == messages[i])
        }
        
        checkChronologicalOrder(collection)
    }
    
    @Test(arguments: 1...10)
    func addUnsortedMessagesInTheSameSection(count: Int) {
        var collection = makeCollection()
        let range = (0...count)
        
        var messages = [Message]()
        
        for i in range {
            let message = Message()
            message.time = .init(timeIntSince1970: i + 1)
            messages.append(message)
        }
        
        messages.shuffle()
        
        for message in messages {
            _ = collection.add(message: message)
        }

        checkChronologicalOrder(collection)
    }
    
    @Test(arguments: 1...10)
    func addSortedMessagesInDifferentSection(count: Int) {
        var collection = makeCollection()
        let range = (0...count)
        
        var messages = [Message]()
        
        for i in range {
            let message = Message()
            message.time = Date(daysSince1970: i)
            messages.append(message)
        }
        
        for message in messages {
            _ = collection.add(message: message)
        }

        checkChronologicalOrder(collection)
    }
    
    @Test(arguments: 1...10)
    func addUnsortedMessagesInDifferentSection(count: Int) {
        var collection = makeCollection()
        let range = (0...count)
        
        var messages = [Message]()
        
        for i in range {
            let message = Message()
            message.time = Date(daysSince1970: i)
            messages.append(Message())
        }
        
        messages.shuffle()
        
        for message in messages {
            _ = collection.add(message: message)
        }

        checkChronologicalOrder(collection)
    }
    
    @Test
    func clearCollection() {
        var collection = makeCollection()
        _ = collection.add(message: .makeTestData())
        
        #expect(getAllMessages(collection).count == 1)
        
        collection.clear()
        
        #expect(getAllMessages(collection).count == 0)
    }
}

private extension ChronologicalMessageCollectionTests {
    
    func makeCollection() -> ParleyChronologicalMessageCollection {
        ParleyChronologicalMessageCollection(calendar: .current)
    }
    
    func checkChronologicalOrder(_ collection: ParleyChronologicalMessageCollection) {
        var lastMessage: Message?
        
        for section in collection.sections {
            for message in section.messages {
                if let lastMessage {
                    if lastMessage.time! > message.time! {
                        Issue.record("Collection is not chronological.")
                    }
                }
                lastMessage = message
            }
        }
    }
    
    func getAllMessages(_ collection: ParleyChronologicalMessageCollection) -> [Message] {
        Array(collection.sections.map(\.messages).joined())
    }
}

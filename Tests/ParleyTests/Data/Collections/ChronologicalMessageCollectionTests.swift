import Testing
import XCTest
@testable import Parley

@Suite("Chronological Message Collection Tests")
class ChronologicalMessageCollectionTests {
    
    @Test
    func testCreationIsEmpty() {
        let collection = makeCollection()
        let lastPosistion = collection.lastPosistion()
        
        #expect(collection.sections.isEmpty)
        #expect(lastPosistion == .init(section: .zero, row: .zero))
    }
    
    @Test(arguments: 1...25)
    func addSortedMessages(count: Int) async throws {
        var collection = makeCollection()
        let range = (0...count)
        
        var messages = [Message]()
        
        for i in range {
            messages.append(Message())
            messages[i].time = .init(timeIntSince1970: i + 1)
        }
        for message in messages {
            _ = collection.add(message: message)
        }
        
        for i in range {
            #expect(collection[section: .zero, row: i] == messages[i])
        }
    }
    
    @Test
    func clearCollection() {
        var collection = makeCollection()
        _ = collection.add(message: .makeTestData())
        
        #expect(collection.getAllMessages().count == 1)
        
        collection.clear()
        
        #expect(collection.getAllMessages().count == 0)
    }
}

private extension ChronologicalMessageCollectionTests {
    
    func makeCollection() -> ParleyChronologicalMessageCollection {
        ParleyChronologicalMessageCollection(calender: .current)
    }
}

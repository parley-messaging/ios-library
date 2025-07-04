import Foundation
import Testing
@testable import Parley

@Suite("Message Tests")
struct MessageTests {
    
    private let messageString = """
{
    "uuid": "238ff956-32d3-42c0-ae93-57bb9cd043a4",
    "typeId":2,
    "message": "Example message",
    "time": 81919,
    "status": 1,
    "id": 42,
    "title": "Message title"
    "status": 2
}
"""

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    @Test
    func testDecodeEncode() throws {
        let expectedResult = createMessage()

        let decodedSut = try decoder.decode(MessageResponse.self, from: Data(messageString.utf8))
        let encodedSut = try encoder.encode(decodedSut)
        let result = try decoder.decode(MessageResponse.self, from: encodedSut)

        // Due to a custom Comparable implementation not all properties are
        // checked. So we check them manually.
        #expect(result.type == expectedResult.type)
        #expect(result.message == expectedResult.message)
        #expect(result.remoteId == expectedResult.remoteId)
        #expect(result.title == expectedResult.title)
        #expect(result.time == expectedResult.time)
        #expect(result.status == expectedResult.status)
    }

    private func createMessage() -> MessageResponse {
        return MessageResponse.init(
            remoteId: 42,
            time: Date(timeIntervalSince1970: 81919),
            title: "Message title",
            message: "Example message",
            type: .agent,
            status: .sent
        )
    }
}

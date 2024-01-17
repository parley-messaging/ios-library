import Foundation
import XCTest
@testable import Parley

final class MessageTests: XCTestCase {

    private let messageString = "{\"uuid\":\"238ff956-32d3-42c0-ae93-57bb9cd043a4\",\"typeId\":2,\"message\""
        + ":\"Example message\",\"time\":81919,\"status\":1,\"id\":42,\"title\":\"Message title\"}"

    private var decoder: JSONDecoder!
    private var encoder: JSONEncoder!

    override func setUpWithError() throws {
        decoder = JSONDecoder()
        encoder = JSONEncoder()
    }

    override func tearDownWithError() throws {
        decoder = nil
        encoder = nil
    }

    func testDecodeEncode() throws {
        let expectedResult = makeMessage()

        let decodedSut = try decoder.decode(Message.self, from: Data(messageString.utf8))
        let encodedSut = try encoder.encode(decodedSut)
        let result = try decoder.decode(Message.self, from: encodedSut)

        XCTAssertEqual(result, expectedResult)
        // Due to a custom Comparable implementation not all properties are
        // checked. So we check them manually.
        XCTAssertEqual(result.type, expectedResult.type)
        XCTAssertEqual(result.message, expectedResult.message)
        XCTAssertEqual(result.id, expectedResult.id)
        XCTAssertEqual(result.uuid, expectedResult.uuid)
        XCTAssertEqual(result.title, expectedResult.title)
        XCTAssertEqual(result.time, expectedResult.time)
        XCTAssertEqual(result.status, expectedResult.status)
    }

    private func makeMessage() -> Message {
        let message = Message()
        message.type = .agent
        message.message = "Example message"
        message.id = 42
        message.time = Date(timeIntervalSince1970: 81919)
        message.uuid = "238ff956-32d3-42c0-ae93-57bb9cd043a4"
        message.title = "Message title"
        message.status = .pending

        return message
    }

}

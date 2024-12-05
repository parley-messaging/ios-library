import Foundation
import XCTest
@testable import Parley

final class MessageCollectionTest: XCTestCase {

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

    func testDecode() throws {
        let messageCollectionString = """
            {\"data\":[],\"notifications\":[],\"status\":\"SUCCESS\",\"metadata\":{\"values\":{\"url\":\"messages\"},
            \"method\":\"get\",\"duration\":0.022},\"agent\":{\"id\":0,\"name\":\"First Name\",\"avatar\":\"avatar.png\",
            \"isTyping\":null},\"paging\":{\"before\":\"\",\"after\":\"\\/messages\\/after:188373\"},\"stickyMessage\":null,
            \"welcomeMessage\":\"\"}
        """

        let messageCollection = MessageCollection(
            messages: [],
            agent: Agent(id: 0, name: "First Name", avatar: "avatar.png"),
            paging: MessageCollection.Paging(before: "", after: "/messages/after:188373"),
            stickyMessage: nil,
            welcomeMessage: ""
        )

        let result = try decoder.decode(MessageCollection.self, from: Data(messageCollectionString.utf8))

        XCTAssertEqual(messageCollection, result)
    }

}

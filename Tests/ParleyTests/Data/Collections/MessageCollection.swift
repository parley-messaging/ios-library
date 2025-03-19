import Foundation
import Testing
@testable import Parley

@Suite("Message Collection Test")
struct MessageCollectionTest {

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    @Test
    func testDecode() throws {
        let messageCollectionString = """
{
    "data": [],
    "notifications": [],
    "status": "SUCCESS",
    "metadata": { 
        "values": {
            "url": "messages"
        },
        "method": "get",
        "duration": 0.022
    },
    "agent": {
        "id": 0,
        "name": 
        "First Name", 
        "avatar": "avatar.png",
        "isTyping": null
    },
    "paging": {
        "before": "",
        "after": "/messages/after:188373"
    },
    "stickyMessage": null,
    "welcomeMessage": ""
}
"""

        let messageCollection = MessageCollectionResponse(
            messages: [],
            agent: AgentResponse(id: 0, name: "First Name", avatar: "avatar.png"),
            paging: MessageCollectionResponse.Paging(before: "", after: "/messages/after:188373"),
            stickyMessage: nil,
            welcomeMessage: ""
        )

        let result = try decoder.decode(MessageCollectionResponse.self, from: Data(messageCollectionString.utf8))

        #expect(messageCollection.toDomainModel() == result.toDomainModel())
    }

}

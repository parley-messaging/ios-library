import Foundation

@testable import Parley

extension Message {
    static func makeTestData(
        id: Int? = 1,
        time: Date? = Date(),
        title: String? = "Title",
        message: String? = "Message",
        responseInfoType: String? = "responseInfoType",
        media: MediaObject? = nil,
        buttons: [MessageButton]? = nil,
        carousel: [Message]? = nil,
        quickReplies: [String]? = nil,
        type: MessageType? = .user,
        status: MessageStatus = .success,
        agent: Agent? = Agent(id: 1, name: "Agent", avatar: nil),
        referrer: String? = "referrer"
    ) -> Message {
        let result = Message()

        result.id = id
        result.time = time
        result.title = title
        result.message = message
        result.responseInfoType = responseInfoType
        result.media = media
        result.buttons = buttons
        result.carousel = carousel
        result.quickReplies = quickReplies
        result.type = type
        result.status = status
        result.agent = agent
        result.referrer = referrer

        return result
    }
}

import Foundation

@testable import Parley

extension Message {
    static func makeTestData(
        id: UUID = UUID(),
        remoteId: Int? = 1,
        time: Date = Date(),
        title: String? = "Title",
        message: String? = "Message",
        responseInfoType: String? = "responseInfoType",
        media: MediaObject? = nil,
        buttons: [MessageButton] = [],
        carousel: [Message] = [],
        quickReplies: [String] = [],
        type: MessageType = .user,
        status: MessageStatus = .success,
        agent: Agent? = Agent(id: 1, name: "Agent", avatar: nil),
        referrer: String? = "referrer"
    ) -> Message {
        return Message.exsisting(
            remoteId: remoteId,
            localId: id,
            time: time,
            title: title,
            message: message,
            responseInfoType: responseInfoType,
            media: media,
            buttons: buttons,
            carousel: carousel,
            quickReplies: quickReplies,
            type: type,
            status: status,
            agent: agent,
            referrer: referrer
        )
    }
}

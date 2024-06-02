import Foundation
import UIKit

public final class Message: Codable, Equatable {

    enum MessageStatus: Int, Codable {
        case failed = 0
        case pending = 1
        case success = 2
    }

    enum MessageType: Int, Codable {
        /// A message from the user that is still being sent.
        case loading = -3

        /// Agent typing indicator
        case agentTyping = -2

        /// Date header
        case date = -1

        /// Informational message
        case info = 0

        /// Message from the user
        case user = 1

        /// Message from the agent
        case agent = 2

        /// Automatic message from the backend system.
        /// Comparable to the `info` field in that is used for informational content.
        case auto = 3

        /// Message from the system, as the user
        case systemMessageUser = 4

        /// Message from the system, as the agent
        case systemMessageAgent = 5
    }

    var id: Int?

    /// Used to identify pending or failed messages.
    var uuid: String?

    var time: Date?

    var title: String?
    var message: String?
    var responseInfoType: String?

    var media: MediaObject?

    var hasMedium: Bool {
        media != nil
    }

    var hasButtons: Bool {
        guard let buttons else { return false }
        return !buttons.isEmpty
    }

    var buttons: [MessageButton]?

    var carousel: [Message]?

    var quickReplies: [String]?

    var type: MessageType?
    var status: MessageStatus = .success

    var agent: Agent?

    var referrer: String?

    public init() {
        uuid = UUID().uuidString
        time = Date()
    }

    enum CodingKeys: String, CodingKey {
        case id
        case messageId
        case uuid
        case time
        case title
        case message
        case responseInfoType
        case media
        case buttons
        case carousel
        case quickReplies
        case type = "typeId"
        case status
        case agent
        case referrer
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        if let id = try? values.decodeIfPresent(Int.self, forKey: .id) {
            self.id = id
        } else if let id = try? values.decodeIfPresent(Int.self, forKey: .messageId) {
            self.id = id
        } else if let id = try? values.decodeIfPresent(String.self, forKey: .messageId) {
            self.id = Int(id)
        }

        uuid = try values.decodeIfPresent(String.self, forKey: .uuid)

        if let timeInt = try values.decodeIfPresent(Int.self, forKey: .time) {
            time = Date(timeIntSince1970: timeInt)
        } else {
            time = nil
        }
        title = try values.decodeIfPresent(String.self, forKey: .title)
        message = try values.decodeIfPresent(String.self, forKey: .message)
        if message?.isEmpty == true {
            message = nil
        }
        responseInfoType = try values.decodeIfPresent(String.self, forKey: .responseInfoType)
        media = try values.decodeIfPresent(MediaObject.self, forKey: .media)
        buttons = try values.decodeIfPresent([MessageButton].self, forKey: .buttons)
        carousel = try values.decodeIfPresent([Message].self, forKey: .carousel)
        quickReplies = try values.decodeIfPresent([String].self, forKey: .quickReplies)
        type = try values.decodeIfPresent(Message.MessageType.self, forKey: .type)
        status = try values.decodeIfPresent(Message.MessageStatus.self, forKey: .status) ?? .success
        agent = try values.decodeIfPresent(Agent.self, forKey: .agent)
        referrer = try values.decodeIfPresent(String.self, forKey: .referrer)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(uuid, forKey: .uuid)
        if let time {
            try container.encode(Int(time.timeIntervalSince1970), forKey: .time)
        }
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(message, forKey: .message)
        try container.encodeIfPresent(responseInfoType, forKey: .responseInfoType)
        try container.encodeIfPresent(media, forKey: .media)
        try container.encodeIfPresent(buttons, forKey: .buttons)
        try container.encodeIfPresent(carousel, forKey: .carousel)
        try container.encodeIfPresent(quickReplies, forKey: .quickReplies)
        try container.encodeIfPresent(type?.rawValue, forKey: .type)
        try container.encodeIfPresent(status.rawValue, forKey: .status)
        try container.encodeIfPresent(agent, forKey: .agent)
        try container.encodeIfPresent(referrer, forKey: .referrer)
    }

    public func ignore() -> Bool {
        switch type {
        case .auto, .systemMessageUser, .systemMessageAgent:
            true
        case .agentTyping, .loading:
            false
        case .date, .info, .agent, .user:
            (
                title == nil &&
                    message == nil &&
                    buttons?.count ?? 0 == 0 &&
                    carousel?.count ?? 0 == 0 &&
                    media == nil
            )
        case .none:
            true
        }
    }

    public static func == (lhs: Message, rhs: Message) -> Bool {
        if let uuid = rhs.uuid {
            lhs.uuid == uuid
        } else {
            lhs.id == rhs.id
        }
    }

    public func getFormattedMessage() -> String? {
        message
    }
}

extension Message: Comparable {

    public static func < (lhs: Message, rhs: Message) -> Bool {
        switch lhs.type {
        case .info, .loading:
            false
        case .agentTyping:
            true
        default:
            if lhs.time == nil && rhs.time == nil {
                false
            } else if lhs.time == nil {
                true
            } else if rhs.time == nil {
                false
            } else {
                lhs.time! < rhs.time!
            }
        }
    }

    public static func > (lhs: Message, rhs: Message) -> Bool {
        !(lhs < rhs)
    }
}

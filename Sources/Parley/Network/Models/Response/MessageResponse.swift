import Foundation

struct MessageResponse: Codable {
    
    enum DecodeError: Error {
        case invalidId
        case dateInvalid
        case typeNotFound(String?)
    }

    enum MessageStatus: Int, Codable {
        case failed = 0
        case pending = 1
        case success = 2
        
        func toDomainModel() -> Message.MessageStatus {
            switch self {
            case .failed: return .failed
            case .pending: return .pending
            case .success: return .success
            }
        }
    }

    enum MessageType: Int, Codable {
        case user = 1
        case agent = 2
        case auto = 3
        case systemMessageUser = 4
        case systemMessageAgent = 5
        
        func toDomainModel() -> Message.MessageType {
            switch self {
            case .user: return .user
            case .agent: return .agent
            case .auto: return .auto
            case .systemMessageUser: return .systemMessageUser
            case .systemMessageAgent: return .systemMessageAgent
            }
        }
        
        static func from(_ type: Message.MessageType?) -> Self? {
            guard let type else { return nil }
            switch type {
            case .user: return .user
            case .agent: return .agent
            case .auto: return .auto
            case .systemMessageUser: return .systemMessageUser
            case .systemMessageAgent: return .systemMessageAgent
            }
        }
    }

    let remoteId: Message.RemoteId?
    var time: Date

    var title: String?
    var message: String?
    var responseInfoType: String?

    var media: MediaObject?

    var buttons: [MessageButtonResponse]?

    var carousel: [Self]?

    var quickReplies: [String]?
    var hasQuickReplies: Bool {
        (quickReplies ?? []).isEmpty == false
    }

    var type: MessageType?
    var status: MessageStatus = .success

    var agent: AgentResponse?

    var referrer: String?
    
    init(
        remoteId: Message.RemoteId?,
        time: Date = Date(),
        title: String? = nil,
        message: String? = nil,
        responseInfoType: String? = nil,
        media: MediaObject? = nil,
        buttons: [MessageButtonResponse]? = nil,
        carousel: [Self]? = nil,
        quickReplies: [String]? = nil,
        type: MessageType? = nil,
        status: MessageStatus = .success,
        agent: AgentResponse? = nil,
        referrer: String? = nil
    ) {
        self.remoteId = remoteId
        self.time = time
        self.title = title
        self.message = message
        self.responseInfoType = responseInfoType
        self.media = media
        self.buttons = buttons
        self.carousel = carousel
        self.quickReplies = quickReplies
        self.type = type
        self.status = status
        self.agent = agent
        self.referrer = referrer
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

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        if let id = try? values.decodeIfPresent(Int.self, forKey: .id) {
            self.remoteId = id
        } else if let id = try? values.decodeIfPresent(Int.self, forKey: .messageId) {
            self.remoteId = id
        } else if let messageId = try? values.decodeIfPresent(String.self, forKey: .messageId) {
            if let id = Int(messageId) {
                self.remoteId = Message.RemoteId(id)
            } else {
                throw DecodeError.invalidId
            }
        } else {
            self.remoteId = nil
        }

        if let timeInt = try values.decodeIfPresent(Int.self, forKey: .time) {
            time = try Self.convertTime(timeInt)
        } else {
            time = Date()
        }
        
        title = try values.decodeIfPresent(String.self, forKey: .title)
        message = try values.decodeIfPresent(String.self, forKey: .message)
        if message?.isEmpty == true {
            message = nil
        }
        responseInfoType = try values.decodeIfPresent(String.self, forKey: .responseInfoType)
        media = try values.decodeIfPresent(MediaObject.self, forKey: .media)
        buttons = try values.decodeIfPresent([MessageButtonResponse].self, forKey: .buttons)
        type = try values.decodeIfPresent(Self.MessageType.self, forKey: .type)
        
        carousel = try values.decodeIfPresent([Self].self, forKey: .carousel)
        if let carousel {
            if let type {
                for carouselMessageIndex in carousel.indices {
                    self.carousel?[carouselMessageIndex].type = self.type
                }
            } else {
                throw DecodeError.typeNotFound("Expected message with carousel to have a type so that the carousel can inherit the same type")
            }
        }
        
        quickReplies = try values.decodeIfPresent([String].self, forKey: .quickReplies)
        
        status = try values.decodeIfPresent(Self.MessageStatus.self, forKey: .status) ?? .success
        agent = try values.decodeIfPresent(AgentResponse.self, forKey: .agent)
        referrer = try values.decodeIfPresent(String.self, forKey: .referrer)
    }
    
    static func convertTime(_ timeInt: Int) throws(DecodeError) -> Date {
        guard timeInt > .zero else { throw .dateInvalid }
        return Date(timeIntervalSince1970: TimeInterval(timeInt))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(remoteId, forKey: .id)
        try container.encode(Int(time.timeIntervalSince1970), forKey: .time)
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
    
    func toDomainModel(id: UUID) -> Message {
        Message.exsisting(
            remoteId: remoteId,
            localId: id,
            time: time,
            title: title,
            message: message,
            responseInfoType: responseInfoType,
            media: media,
            buttons: buttons?.map { $0.toDomainModel() } ?? [],
            carousel: carousel?.map { $0.toDomainModel(id: UUID()) } ?? [],
            quickReplies: quickReplies ?? [],
            type: type?.toDomainModel(),
            status: status.toDomainModel(),
            agent: agent?.toDomainModel(),
            referrer: referrer
        )
    }
}

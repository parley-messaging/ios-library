import Foundation

struct StoredMessage: Codable, Identifiable {

    enum SendStatus: Int, Codable {
        case failed, pending, success
        
        func toDomainModel() -> Message.SendStatus {
            switch self {
            case .failed: return .failed
            case .pending: return .pending
            case .success: return .success
            }
        }
        
        static func from(_ status: Message.SendStatus) -> Self {
            switch status {
            case .failed: return .failed
            case .pending: return .pending
            case .success: return .success
            }
        }
    }
    
    enum Status: Int, Codable {
        case sent = 2
        case received = 3
        case read = 4
        
        func toDomainModel() -> Message.Status {
            switch self {
            case .sent: return .sent
            case .received: return .received
            case .read: return .read
            }
        }
        
        static func from(_ status: Message.Status) -> Self {
            switch status {
            case .sent: return .sent
            case .received: return .received
            case .read: return .read
            }
        }
    }

    enum MessageType: Int, Codable {
        case user, agent, auto
        case systemMessageUser, systemMessageAgent
        
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
    
    public var id: UUID { localId }
    
    let remoteId: Int?
    let localId: UUID
    var time: Date
    var title: String?
    var message: String?
    var responseInfoType: String?
    var media: MediaObject?
    var buttons: [StoredMessageButton]
    var carousel: [Self]
    var quickReplies: [String]
    var type: MessageType?
    let status: Status?
    var sendStatus: SendStatus
    var agent: StoredAgent?
    var referrer: String?
    
    init(message: Message) {
        self.remoteId = message.remoteId
        self.localId = message.localId
        self.time = message.time
        self.title = message.title
        self.message = message.message
        self.responseInfoType = message.responseInfoType
        self.media = message.media
        self.carousel = message.carousel.map { StoredMessage(message: $0) }
        self.buttons = message.buttons.map(StoredMessageButton.from(_:))
        self.quickReplies = message.quickReplies
        self.type = Self.MessageType.from(message.type)
        if let status = message.status {
            self.status = Self.Status.from(status)
        } else {
            self.status = nil
        }
        self.sendStatus = Self.SendStatus.from(message.sendStatus)
        if let agent = message.agent {
            self.agent = StoredAgent.from(agent)
        }
        self.referrer = message.referrer
    }
    
    func toDomainModel() -> Message {
        Message.exsisting(
            remoteId: remoteId,
            localId: localId,
            time: time,
            title: title,
            message: message,
            responseInfoType: responseInfoType,
            media: media,
            buttons: self.buttons.map { $0.toDomainModel() },
            carousel: carousel.map { $0.toDomainModel() },
            quickReplies: quickReplies,
            type: type?.toDomainModel(),
            status: status?.toDomainModel(),
            sendStatus: sendStatus.toDomainModel(),
            agent: agent?.toDomainModel(),
            referrer: referrer
        )
    }
}

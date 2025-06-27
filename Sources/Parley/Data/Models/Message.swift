import Foundation
import UIKit

public struct Message: Equatable, Sendable, Identifiable {
    
    typealias RemoteId = Int

    enum SendStatus {
        case failed
        case pending
        case success
    }
    
    enum Status {
        case sent, received, read
    }

    enum MessageType {
        /// Message from the user
        case user

        /// Message from the agent
        case agent

        /// Automatic message from the backend system.
        case auto

        /// Message from the system, as the user
        case systemMessageUser

        /// Message from the system, as the agent
        case systemMessageAgent
    }

    var remoteId: RemoteId?
    let localId: UUID
    public var id: UUID { localId }

    var time: Date

    var title: String?
    var message: String?
    var responseInfoType: String?

    var media: MediaObject?

    var hasMedium: Bool {
        media != nil
    }

    var hasImage: Bool {
        media?.getMediaType().isImageType == true
    }

    var hasFile: Bool {
        media?.getMediaType().isImageType == false
    }
    
    var buttons: [MessageButton]
    var hasButtons: Bool {
        return !buttons.isEmpty
    }

    var carousel: [Message]

    var quickReplies: [String]
    var hasQuickReplies: Bool {
        quickReplies.isEmpty == false
    }

    var type: MessageType?
    var status: Status?
    var sendStatus: SendStatus

    var agent: Agent?

    var referrer: String?
    
    private init(
        remoteId: Int?,
        localId: UUID,
        time: Date,
        title: String?,
        message: String?,
        responseInfoType: String?,
        media: MediaObject?,
        buttons: [MessageButton],
        carousel: [Message],
        quickReplies: [String],
        type: MessageType?,
        status: Status?,
        sendStatus: SendStatus,
        agent: Agent?,
        referrer: String?
    ) {
        self.remoteId = remoteId
        self.localId = localId
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
        self.sendStatus = sendStatus
        self.agent = agent
        self.referrer = referrer
    }

    public func ignore() -> Bool {
        guard let type else { return true }
        switch type {
        case .auto, .systemMessageUser, .systemMessageAgent:
            return true
        case .agent, .user:
            return (
                title == nil &&
                message == nil &&
                buttons.isEmpty &&
                carousel.isEmpty &&
                media == nil
            )
        }
    }

    public static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.localId == rhs.localId
    }

    public func getFormattedMessage() -> String? {
        message
    }
}

// MARK: Initializers
extension Message {
    
    static func newTextMessage(
        _ message: String,
        type: MessageType,
        sendStatus: SendStatus = .pending
    ) -> Message {
        Message(
            localId: UUID(),
            time: Date(),
            message: message,
            media: nil,
            type: .user,
            status: nil,
            sendStatus: sendStatus
        )
    }
    
    static func newMediaMessage(_ media: MediaObject, status: SendStatus) -> Message {
        Message(
            localId: UUID(),
            time: Date(),
            message: nil,
            media: media,
            type: .user,
            status: nil,
            sendStatus: status
        )
    }
    
    static func exsisting(
        remoteId: Int?,
        localId: UUID,
        time: Date,
        title: String?,
        message: String?,
        responseInfoType: String?,
        media: MediaObject?,
        buttons: [MessageButton],
        carousel: [Message],
        quickReplies: [String],
        type: MessageType?,
        status: Status?,
        sendStatus: SendStatus,
        agent: Agent?,
        referrer: String?
    ) -> Message {
        Message(
            remoteId: remoteId,
            localId: localId,
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
            sendStatus: sendStatus,
            agent: agent,
            referrer: referrer
        )
    }
    
    static func push(
        remoteId: Int?,
        message: String?,
        type: MessageType
    ) -> Message {
        Message(
            remoteId: remoteId,
            localId: UUID(),
            time: Date(),
            title: nil,
            message: message,
            responseInfoType: nil,
            media: nil,
            buttons: [],
            carousel: [],
            quickReplies: [],
            type: type,
            status: nil,
            sendStatus: .success,
            agent: nil,
            referrer: nil
        )
    }
    
    private init(
        localId: UUID,
        time: Date,
        message: String?,
        media: MediaObject?,
        type: MessageType,
        status: Status?,
        sendStatus: SendStatus
    ) {
        self.remoteId = nil
        self.localId = localId
        self.time = time
        self.title = nil
        self.message = message
        self.responseInfoType = nil
        self.media = media
        self.buttons = []
        self.carousel = []
        self.quickReplies = []
        self.type = type
        self.status = status
        self.sendStatus = sendStatus
        self.agent = nil
        self.referrer = nil
    }
}

extension Message: Comparable {

    public static func < (lhs: Message, rhs: Message) -> Bool {
        lhs.time < rhs.time
    }

    public static func > (lhs: Message, rhs: Message) -> Bool {
        !(lhs < rhs)
    }
}

extension [Message] {
    
    func byDate(calender: Calendar) -> [Date: [Message]] {
        var messagesByDate: [Date: [Message]] = [:]
        
        for message in self {
            let date = calender.startOfDay(for: message.time)
            
            if messagesByDate[date] == nil {
                messagesByDate[date] = []
            }
            
            messagesByDate[date]?.append(message)
        }
        
        return messagesByDate
    }
}

import ObjectMapper
import Foundation
import UIKit

public class Message: Mappable, Equatable {
    
    enum MessageStatus: Int {
        case failed = 0
        case pending = 1
        case success = 2
    }
    
    enum MessageType: Int, Codable {
        case loading = -3
        case agentTyping = -2
        case date = -1
        case info = 0
        case user = 1
        case agent = 2
        case auto = 3
        case systemMessageUser = 4
        case systemMessageAgent = 5
        
        static let ignored: [MessageType] = [.auto, .systemMessageUser, .systemMessageAgent]
    }
    
    var id: Int?
    
    /// Used to identify pending or failed messages.
    var uuid: String?
    
    var time: Date?
    
    var title: String?
    var message: String?
    
    @available(*, deprecated, message: "Please use 'media' instead of 'image'.")
    var image: UIImage?
    var imageURL: URL?
    var imageData: Data?
    
    var media: MediaObject?
    internal var mediaSendRequest: MediaModel?
    
    internal var hasMedium: Bool {
        imageURL != nil || imageData != nil || media != nil || image != nil
    }
    
    internal var hasButtons: Bool {
        (buttons?.count ?? 0) > 0
    }
    
    var buttons: [MessageButton]?
    
    var carousel: [Message]?
    
    var quickReplies: [String]?
    
    var type: MessageType!
    var status: MessageStatus = .success
    
    var agent: Agent?
    
    var referrer: String?
    
    public init() {
        self.uuid = UUID().uuidString
        
        self.time = Date()
    }

    public required init?(map: Map) {
        //
    }

    public func mapping(map: Map) {
        self.id             <- map["id"]
        if self.id == nil {
            self.id         <- map["messageId"]
        }
        if self.id == nil {
            self.id         <- (map["messageId"], StringToIntTransform())
        }
        
        self.uuid           <- map["uuid"]
        
        self.time           <- (map["time"], TimeIntervalSince1970DateTransform())
        
        self.title          <- map["title"]
        self.message        <- map["message"]
        if self.message?.isEmpty == true {
            self.message = nil
        }
        self.mediaSendRequest <- (map["mediaSendRequest"], CodableTransform<MediaModel>())
        
        self.imageURL       <- (map["image"], StringToURLTransform())
        self.media          <- (map["media"], CodableTransform<MediaObject>())
        
        self.buttons        <- map["buttons"]
        
        self.carousel       <- map["carousel"]
        
        self.quickReplies   <- map["quickReplies"]
        
        self.type           <- (map["typeId"], EnumTransform<MessageType>())
        self.status         <- (map["status"], EnumTransform<MessageStatus>())
        
        self.agent          <- map["agent"]
        
        self.referrer <- map["referrer"]
    }
    
    public func ignore() -> Bool {
        return (self.title == nil && self.message == nil &&
            self.imageURL == nil && self.image == nil &&
            self.buttons?.count ?? 0 == 0 && self.carousel?.count ?? 0 == 0
            && media == nil)
            || MessageType.ignored.contains(self.type)
    }

    public static func == (lhs: Message, rhs: Message) -> Bool {
        if let uuid = rhs.uuid {
            return lhs.uuid == uuid
        } else {
            return lhs.id == rhs.id
        }
    }

    public func getFormattedMessage() -> String? {
        guard let message = message else {
            return nil
        }
        return message
    }
    
}

// MARK: - Accessibility
extension Message {
    
    internal func getAccessibilityLabelDescription() -> String {
        var accessibilityLabel = "parley_voice_over_message_label_message".localized
        
        appendAgentNameIfAvailable(to: &accessibilityLabel)
        appendBody(to: &accessibilityLabel)
        appendAccessibilityLabelDescriptionEnding(to: &accessibilityLabel)
        
        return accessibilityLabel
    }
    
    private func appendAgentNameIfAvailable(to accessibilityLabel: inout String) {
        if let agentName = agent?.name {
            let format = "parley_voice_over_message_label_sender".localized
            accessibilityLabel.append(.localizedStringWithFormat(format, agentName))
        }
        
        accessibilityLabel.append(".")
    }
    
    private func appendBody(to accessibilityLabel: inout String) {
        if title != nil || message != nil {
            if let title {
                accessibilityLabel.append(title)
            }
            
            if let message {
                accessibilityLabel.append(message)
            }
        }
        
        if hasMedium {
            accessibilityLabel.appendWithCorrectSpacing("parley_voice_over_message_media_attached".localized)
        }
    }
    
    private func appendAccessibilityLabelDescriptionEnding(to accessibilityLabel: inout String) {
        switch status {
        case .failed:
            accessibilityLabel.appendWithCorrectSpacing("parley_voice_over_message_failed".localized)
        case .pending:
            accessibilityLabel.appendWithCorrectSpacing("parley_voice_over_message_pending".localized)
        case .success:
            break
        }
        
        if let time {
            let format = "parley_voice_over_message_time".localized
            accessibilityLabel.appendWithCorrectSpacing(.localizedStringWithFormat(format, time.asTime()))
        }
    }
}

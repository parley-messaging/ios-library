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
    
    var uuid: String? // Used to identify pending or failed messages.
    
    var time: Date?
    
    var title: String?
    var message: String?
    
    var imageURL: URL?
  
    var media: MediaObject?
    var cachedMedia: MediaModel?
    
    @available(*, deprecated, message: "Please use 'media' instead of 'image'.")
    var image: UIImage?
    var imageData: Data?
    
    var buttons: [MessageButton]?
    
    var carousel: [Message]?
    
    var quickReplies: [String]?
    
    var type: MessageType!
    var status: MessageStatus = .success
    
    var agent: Agent?
    
    var referrer: String?
    
    public init() {
        self.uuid = NSUUID().uuidString
        
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
        // Format plain urls to markdown urls
        return message.replacingOccurrences(of: "(?<=[^\\(\\[])https?://\\S+\\b", with: "[$0]($0)", options: .regularExpression)
    }
}

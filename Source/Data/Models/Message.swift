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
    
    // MARK: Accessibility properties
    /// - Note: Only used when deployment target is below iOS 13.
    private var accessibilityCustomActionCallback: (target: AnyObject, selector: Selector)?
    
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

// MARK: - Accessibility - Custom Actions
extension Message {
    
    @available(iOS 11, *)
    /// -- Note: This method requires the `accessibilityCustomActionCallback` property on the `Message` class,
    /// this is not preferred. This function also needs to use Selectors which in turn requires this class to receive the custom actions callback.
    /// All this is needed to know what button the user selected on which message.
    /// - Remark: Use `Message.Accessibility.getAccessibilityCustomActions(for:, actionHandler:)` when ** iOS 13** is the minimum supported version.
    internal func getAccessibilityCustomActions(target: AnyObject, selector: Selector) -> [UIAccessibilityCustomAction]? {
        guard let buttons, !buttons.isEmpty else { return nil }
        
        accessibilityCustomActionCallback = (target, selector)
        
        var actions = [UIAccessibilityCustomAction]()
        for button in buttons {
            let action = UIAccessibilityCustomAction(name: button.title, target: self, selector: #selector(customActionTriggered(_:)))
            action.accessibilityTraits = [.button]
            actions.append(action)
        }
        
        return actions
    }
    
    @objc private func customActionTriggered(_ action: UIAccessibilityCustomAction) {
        guard
            let id,
            let accessibilityCustomActionCallback,
            let buttons,
            let button = buttons.first(where: { $0.title == action.name })
        else { return }
     
        let (target, selector) = accessibilityCustomActionCallback
        _ = target.perform(selector, with: id, with: button.title)
    }
}

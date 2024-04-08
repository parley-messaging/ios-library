import UIKit

public class ParleyViewAppearance {
    
    public var backgroundColor: UIColor? = UIColor(white: 0.92, alpha: 1.0)
    
    public var loaderTintColor: UIColor = UIColor(red:0.29, green:0.37, blue:0.51, alpha:0.6)
    public var textColor: UIColor = UIColor(white: 0.62, alpha: 1.0)
    
    public var notificationsPosition: ParleyPositionVertical = .top
    public var offlineNotification: ParleyNotificationViewAppearance
    public var pushDisabledNotification: ParleyNotificationViewAppearance
    public var sticky = ParleyStickyViewAppearance()
    public var compose = ParleyComposeViewAppearance()
    
    public var agentMessage = MessageTableViewCellAppearance.agent()
    public var userMessage = MessageTableViewCellAppearance.user()
    
    public var suggestions = ParleySuggestionsViewAppearance()
    
    public var typingBalloon = AgentTypingTableViewCellAppearance()
    public var loading = LoadingTableViewCellAppearance()
    public var date = DateTableViewCellAppearance()
    public var info = InfoTableViewCellAppearance()
    
    public init(fontRegularName: String? = nil, fontItalicName: String? = nil, fontBoldName: String? = nil) {
        let offlineIcon = UIImage(named: "ic_error_no_connection", in: .module, compatibleWith: nil)!
        self.offlineNotification = ParleyNotificationViewAppearance(icon: offlineIcon)
        
        let pushDisabledIcon = UIImage(named: "ic_notification_important", in: .module, compatibleWith: nil)!
        self.pushDisabledNotification = ParleyNotificationViewAppearance(icon: pushDisabledIcon)
        
        if let fontRegularName = fontRegularName {
            self.offlineNotification.font = UIFont(name: fontRegularName, size: 13)!
            self.pushDisabledNotification.font = UIFont(name: fontRegularName, size: 13)!
        
            self.sticky.regularFont = UIFont(name: fontRegularName, size: 13)!
            
            self.compose.font = UIFont(name: fontRegularName, size: 17)!
            
            self.agentMessage.timeFont = UIFont(name: fontRegularName, size: 12)!
            self.agentMessage.messageRegularFont = UIFont(name: fontRegularName, size: 14)!
            self.agentMessage.buttonFont = UIFont(name: fontRegularName, size: 16)!
            
            self.agentMessage.carousel?.timeFont = UIFont(name: fontRegularName, size: 12)!
            self.agentMessage.carousel?.messageRegularFont = UIFont(name: fontRegularName, size: 14)!
            self.agentMessage.carousel?.buttonFont = UIFont(name: fontRegularName, size: 16)!
            
            self.userMessage.timeFont = UIFont(name: fontRegularName, size: 12)!
            self.userMessage.messageRegularFont = UIFont(name: fontRegularName, size: 14)!
            self.userMessage.buttonFont = UIFont(name: fontRegularName, size: 16)!
            
            self.userMessage.carousel?.timeFont = UIFont(name: fontRegularName, size: 12)!
            self.userMessage.carousel?.messageRegularFont = UIFont(name: fontRegularName, size: 14)!
            self.userMessage.carousel?.buttonFont = UIFont(name: fontRegularName, size: 16)!
            
            self.info.regularFont = UIFont(name: fontRegularName, size: 14)!
        }
        
        if let fontItalicName = fontItalicName {
            self.sticky.italicFont = UIFont(name: fontItalicName, size: 13)!
            
            self.agentMessage.messageItalicFont = UIFont(name: fontItalicName, size: 14)!
            self.agentMessage.carousel?.messageItalicFont = UIFont(name: fontItalicName, size: 14)!
            
            self.userMessage.messageItalicFont = UIFont(name: fontItalicName, size: 14)!
            self.userMessage.carousel?.messageItalicFont = UIFont(name: fontItalicName, size: 14)!
            
            self.info.italicFont = UIFont(name: fontItalicName, size: 14)!
        }
        
        if let fontBoldName = fontBoldName {
            self.sticky.boldFont = UIFont(name: fontBoldName, size: 13)!
            
            self.agentMessage.nameFont = UIFont(name: fontBoldName, size: 14)!
            self.agentMessage.titleFont = UIFont(name: fontBoldName, size: 14)!
            self.agentMessage.messageBoldFont = UIFont(name: fontBoldName, size: 14)!
            
            self.agentMessage.carousel?.nameFont = UIFont(name: fontBoldName, size: 14)!
            self.agentMessage.carousel?.titleFont = UIFont(name: fontBoldName, size: 14)!
            self.agentMessage.carousel?.messageBoldFont = UIFont(name: fontBoldName, size: 14)!
            
            self.userMessage.nameFont = UIFont(name: fontBoldName, size: 14)!
            self.userMessage.titleFont = UIFont(name: fontBoldName, size: 14)!
            self.userMessage.messageBoldFont = UIFont(name: fontBoldName, size: 14)!
            
            self.userMessage.carousel?.nameFont = UIFont(name: fontBoldName, size: 14)!
            self.userMessage.carousel?.titleFont = UIFont(name: fontBoldName, size: 14)!
            self.userMessage.carousel?.messageBoldFont = UIFont(name: fontBoldName, size: 14)!
            
            self.suggestions.suggestion.suggestionFont = UIFont(name: fontBoldName, size: 14)!
            
            self.date.textFont = UIFont(name: fontBoldName, size: 10)!
            self.info.boldFont = UIFont(name: fontBoldName, size: 14)!
        }
    }
}

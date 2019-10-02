public class ParleyViewAppearance {
    
    public var backgroundColor: UIColor? = UIColor(white:0.92, alpha:1.0)
    
    public var textColor: UIColor = UIColor(white:0.62, alpha:1.0)
    
    public var offlineNotification: ParleyNotificationViewAppearance
    public var pushDisabledNotification: ParleyNotificationViewAppearance
    public var sticky = ParleyStickyViewAppearance()
    public var compose = ParleyComposeViewAppearance()
    
    public var messageUserBalloon = MessageUserTableViewCellAppearance()
    public var imageUserBalloon = ImageUserTableViewCellAppearance()
    
    public var messageAgentBalloon = MessageAgentTableViewCellAppearance()
    public var imageAgentBalloon = ImageAgentTableViewCellAppearance()
    
    public var typingBalloon = AgentTypingTableViewCellAppearance()
    public var loading = LoadingTableViewCellAppearance()
    public var date = DateTableViewCellAppearance()
    public var info = InfoTableViewCellAppearance()
    
    public init() {
        let offlineIcon = UIImage(named: "ic_error_no_connection", in: Bundle(for: type(of: self)), compatibleWith: nil)!
        self.offlineNotification = ParleyNotificationViewAppearance(icon: offlineIcon)
        
        let pushDisabledIcon = UIImage(named: "ic_notification_important", in: Bundle(for: type(of: self)), compatibleWith: nil)!
        self.pushDisabledNotification = ParleyNotificationViewAppearance(icon: pushDisabledIcon)
    }
    
    public init(fontRegularName: String, fontItalicName: String, fontBoldName: String) {
        let offlineIcon = UIImage(named: "ic_error_no_connection", in: Bundle(for: type(of: self)), compatibleWith: nil)!
        self.offlineNotification = ParleyNotificationViewAppearance(icon: offlineIcon)
        
        let pushDisabledIcon = UIImage(named: "ic_notification_important", in: Bundle(for: type(of: self)), compatibleWith: nil)!
        self.pushDisabledNotification = ParleyNotificationViewAppearance(icon: pushDisabledIcon)
        
        self.offlineNotification.font = UIFont(name: fontRegularName, size: 13)!
        self.pushDisabledNotification.font = UIFont(name: fontRegularName, size: 13)!
        
        self.sticky.regularFont = UIFont(name: fontRegularName, size: 13)!
        self.sticky.italicFont = UIFont(name: fontItalicName, size: 13)!
        self.sticky.boldFont = UIFont(name: fontBoldName, size: 13)!
        
        self.compose.font = UIFont(name: fontRegularName, size: 17)!
        
        self.messageAgentBalloon.agentFont = UIFont(name: fontBoldName, size: 14)!
        self.imageAgentBalloon.agentFont = UIFont(name: fontBoldName, size: 14)!
        
        self.messageUserBalloon.messageRegularFont = UIFont(name: fontRegularName, size: 14)!
        self.messageUserBalloon.messageItalicFont = UIFont(name: fontItalicName, size: 14)!
        self.messageUserBalloon.messageBoldFont = UIFont(name: fontBoldName, size: 14)!
        
        self.messageAgentBalloon.messageRegularFont = UIFont(name: fontRegularName, size: 14)!
        self.messageAgentBalloon.messageItalicFont = UIFont(name: fontItalicName, size: 14)!
        self.messageAgentBalloon.messageBoldFont = UIFont(name: fontBoldName, size: 14)!
        
        self.messageUserBalloon.timeFont = UIFont(name: fontRegularName, size: 12)!
        self.imageUserBalloon.timeFont = UIFont(name: fontRegularName, size: 12)!
        self.messageAgentBalloon.timeFont = UIFont(name: fontRegularName, size: 12)!
        self.imageAgentBalloon.timeFont = UIFont(name: fontRegularName, size: 12)!
        
        self.date.textFont = UIFont(name: fontBoldName, size: 10)!
        
        self.info.regularFont = UIFont(name: fontRegularName, size: 14)!
        self.info.italicFont = UIFont(name: fontItalicName, size: 14)!
        self.info.boldFont = UIFont(name: fontBoldName, size: 14)!
    }
}

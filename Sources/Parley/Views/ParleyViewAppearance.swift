import UIKit

public class ParleyViewAppearance {

    public var backgroundColor: UIColor? = UIColor(white: 0.92, alpha: 1.0)

    public var loaderTintColor = UIColor(red: 0.29, green: 0.37, blue: 0.51, alpha: 0.6)
    public var textColor = UIColor(white: 0.62, alpha: 1.0)

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
        offlineNotification = ParleyNotificationViewAppearance(icon: offlineIcon)

        let pushDisabledIcon = UIImage(named: "ic_notification_important", in: .module, compatibleWith: nil)!
        pushDisabledNotification = ParleyNotificationViewAppearance(icon: pushDisabledIcon)

        if let fontRegularName = fontRegularName {
            offlineNotification.font = UIFont(name: fontRegularName, size: 13)!
            pushDisabledNotification.font = UIFont(name: fontRegularName, size: 13)!

            sticky.textViewAppearance.regularFont = UIFont(name: fontRegularName, size: 13)!

            compose.font = UIFont(name: fontRegularName, size: 17)!

            agentMessage.timeFont = UIFont(name: fontRegularName, size: 12)!
            agentMessage.messageTextViewAppearance.regularFont = UIFont(name: fontRegularName, size: 14)!
            agentMessage.buttonFont = UIFont(name: fontRegularName, size: 16)!

            agentMessage.carousel?.timeFont = UIFont(name: fontRegularName, size: 12)!
            agentMessage.carousel?.messageTextViewAppearance.regularFont = UIFont(name: fontRegularName, size: 14)!
            agentMessage.carousel?.buttonFont = UIFont(name: fontRegularName, size: 16)!

            userMessage.timeFont = UIFont(name: fontRegularName, size: 12)!
            userMessage.messageTextViewAppearance.regularFont = UIFont(name: fontRegularName, size: 14)!
            userMessage.buttonFont = UIFont(name: fontRegularName, size: 16)!

            userMessage.carousel?.timeFont = UIFont(name: fontRegularName, size: 12)!
            userMessage.carousel?.messageTextViewAppearance.regularFont = UIFont(name: fontRegularName, size: 14)!
            userMessage.carousel?.buttonFont = UIFont(name: fontRegularName, size: 16)!

            info.textViewAppearance.regularFont = UIFont(name: fontRegularName, size: 14)!
        }

        if let fontItalicName = fontItalicName {
            sticky.textViewAppearance.italicFont = UIFont(name: fontItalicName, size: 13)!

            agentMessage.messageTextViewAppearance.italicFont = UIFont(name: fontItalicName, size: 14)!
            agentMessage.carousel?.messageTextViewAppearance.italicFont = UIFont(name: fontItalicName, size: 14)!

            userMessage.messageTextViewAppearance.italicFont = UIFont(name: fontItalicName, size: 14)!
            userMessage.carousel?.messageTextViewAppearance.italicFont = UIFont(name: fontItalicName, size: 14)!

            info.textViewAppearance.italicFont = UIFont(name: fontItalicName, size: 14)!
        }

        if let fontBoldName = fontBoldName {
            sticky.textViewAppearance.boldFont = UIFont(name: fontBoldName, size: 13)!

            agentMessage.nameFont = UIFont(name: fontBoldName, size: 14)!
            agentMessage.titleFont = UIFont(name: fontBoldName, size: 14)!
            agentMessage.messageTextViewAppearance.boldFont = UIFont(name: fontBoldName, size: 14)!

            agentMessage.carousel?.nameFont = UIFont(name: fontBoldName, size: 14)!
            agentMessage.carousel?.titleFont = UIFont(name: fontBoldName, size: 14)!
            agentMessage.carousel?.messageTextViewAppearance.boldFont = UIFont(name: fontBoldName, size: 14)!

            userMessage.nameFont = UIFont(name: fontBoldName, size: 14)!
            userMessage.titleFont = UIFont(name: fontBoldName, size: 14)!
            userMessage.messageTextViewAppearance.boldFont = UIFont(name: fontBoldName, size: 14)!

            userMessage.carousel?.nameFont = UIFont(name: fontBoldName, size: 14)!
            userMessage.carousel?.titleFont = UIFont(name: fontBoldName, size: 14)!
            userMessage.carousel?.messageTextViewAppearance.boldFont = UIFont(name: fontBoldName, size: 14)!

            suggestions.suggestion.suggestionFont = UIFont(name: fontBoldName, size: 14)!

            date.textFont = UIFont(name: fontBoldName, size: 10)!
            info.textViewAppearance.boldFont = UIFont(name: fontBoldName, size: 14)!
        }
    }
}

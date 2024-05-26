import UIKit

public class MessageCollectionViewCellAppearance: ParleyMessageViewAppearance {
    
    public var width: CGFloat = 250
    
    static func agent() -> MessageCollectionViewCellAppearance {
        let appearance = MessageCollectionViewCellAppearance()
        
        let edgeInsets = UIEdgeInsets(top: 21, left: 23, bottom: 21, right: 21)
        
        appearance.balloonImage = UIImage(named: "agent_balloon_carrousel", in: .module, compatibleWith: nil)?.resizableImage(withCapInsets: edgeInsets)
        appearance.balloonTintColor = UIColor.white
        
        appearance.balloonContentInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 0)
        appearance.balloonContentTextInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        
        appearance.buttonsInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        appearance.buttonInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        
        return appearance
    }
    
    static func user() -> MessageCollectionViewCellAppearance {
        let appearance = MessageCollectionViewCellAppearance()
        
        let edgeInsets = UIEdgeInsets(top: 21, left: 21, bottom: 21, right: 23)
        
        appearance.balloonImage = UIImage(named: "user_balloon_carrousel", in: .module, compatibleWith: nil)?.resizableImage(withCapInsets: edgeInsets)
        appearance.balloonTintColor = UIColor(red:0.29, green:0.37, blue:0.51, alpha:1.0)
        
        appearance.balloonContentInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 2)
        appearance.balloonContentTextInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        
        appearance.messageTextViewAppearance.textColor = UIColor.white
        
        appearance.timeColor = UIColor(white: 1, alpha: 0.6)
        
        return appearance
    }
}

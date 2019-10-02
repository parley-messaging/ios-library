import UIKit

internal class MessageUserTableViewCell: UserTableViewCell {
    
    @IBOutlet weak var messageTextView: ParleyTextView!
    
    internal var appearance = MessageUserTableViewCellAppearance() {
        didSet {
            self.apply(appearance)
        }
    }
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        
        self.apply(appearance)
    }
    
    override func render(_ message: Message) {
        super.render(message)
        
        self.messageTextView.markdownText = message.message
    }
    
    func apply(_ appearance: MessageUserTableViewCellAppearance) {
        super.apply(appearance)
        
        self.messageTextView.textColor = appearance.messageColor
        self.messageTextView.tintColor = appearance.messageTintColor
        
        self.messageTextView.regularFont = appearance.messageRegularFont
        self.messageTextView.italicFont = appearance.messageItalicFont
        self.messageTextView.boldFont = appearance.messageBoldFont
    }
}

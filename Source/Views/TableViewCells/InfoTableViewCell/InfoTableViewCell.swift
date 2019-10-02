import UIKit

internal class InfoTableViewCell: UITableViewCell {
    
    @IBOutlet weak var infoTextView: ParleyTextView! {
        didSet {
            self.infoTextView.paragraphStyle.alignment = .center
        }
    }
    
    @IBOutlet weak var topLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightLayoutConstraint: NSLayoutConstraint!
    
    internal var appearance = InfoTableViewCellAppearance() {
        didSet {
            self.apply(appearance)
        }
    }
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        
        self.apply(appearance)
    }
    
    internal func render(_ message: Message) {
        self.infoTextView.textAlignment = .center
        
        self.infoTextView.markdownText = message.message
    }
    
    func apply(_ appearance: InfoTableViewCellAppearance) {
        self.infoTextView.textColor = appearance.textColor
        
        self.infoTextView.regularFont = appearance.regularFont
        self.infoTextView.italicFont = appearance.italicFont
        self.infoTextView.boldFont = appearance.boldFont
        
        self.topLayoutConstraint.constant = appearance.contentInset?.top ?? 0
        self.leftLayoutConstraint.constant = appearance.contentInset?.left ?? 0
        self.bottomLayoutConstraint.constant = appearance.contentInset?.bottom ?? 0
        self.rightLayoutConstraint.constant = appearance.contentInset?.right ?? 0
    }
}

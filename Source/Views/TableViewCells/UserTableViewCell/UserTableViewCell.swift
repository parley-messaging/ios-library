import UIKit

internal class UserTableViewCell: UITableViewCell {
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    @IBOutlet weak var contentTopLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentLeftLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentBottomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentRightLayoutConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var metaTopLayoutConstraint: NSLayoutConstraint?
    @IBOutlet weak var metaLeftLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var metaBottomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var metaRightLayoutConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var statusImageView: UIImageView!
    
    internal func render(_ message: Message) {
        self.timeLabel.text = message.time.asTime()
        
        switch message.status {
        case .failed:
            self.statusImageView.image = UIImage(named: "ic_close", in: Bundle(for: type(of: self)), compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
            
            break
        case .pending:
            self.statusImageView.image = UIImage(named: "ic_clock", in: Bundle(for: type(of: self)), compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
            
            break
        case .success:
            self.statusImageView.image = UIImage(named: "ic_tick", in: Bundle(for: type(of: self)), compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
            
            break
        }
    }
    
    internal func apply(_ appearance: UserTableViewCellAppearance) {
        if let backgroundTintColor = appearance.backgroundTintColor {
            self.backgroundImageView.image = appearance.backgroundImage?.withRenderingMode(.alwaysTemplate)
            self.backgroundImageView.tintColor = backgroundTintColor
        } else {
            self.backgroundImageView.image = appearance.backgroundImage?.withRenderingMode(.alwaysOriginal)
        }
        
        self.contentTopLayoutConstraint.constant = appearance.contentInset?.top ?? 0
        self.contentLeftLayoutConstraint.constant = appearance.contentInset?.left ?? 0
        self.contentBottomLayoutConstraint.constant = appearance.contentInset?.bottom ?? 0
        self.contentRightLayoutConstraint.constant = appearance.contentInset?.right ?? 0
        
        if let metaTopLayoutConstraint = self.metaTopLayoutConstraint {
            metaTopLayoutConstraint.constant = appearance.metaInset?.top ?? 0
        }
        self.metaLeftLayoutConstraint.constant = appearance.metaInset?.left ?? 0
        self.metaBottomLayoutConstraint.constant = appearance.metaInset?.bottom ?? 0
        self.metaRightLayoutConstraint.constant = appearance.metaInset?.right ?? 0
        
        self.timeLabel.textColor = appearance.timeColor
        self.timeLabel.font = appearance.timeFont
        
        self.statusImageView.tintColor = appearance.statusTintColor
    }
}

import UIKit

final class InfoTableViewCell: UITableViewCell {
    
    @IBOutlet weak var infoTextView: ParleyTextView! {
        didSet {
            self.infoTextView.appearance.paragraphStyle.alignment = .center
        }
    }
    
    @IBOutlet weak var topLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightLayoutConstraint: NSLayoutConstraint!
    
    var appearance = InfoTableViewCellAppearance() {
        didSet {
            self.apply(self.appearance)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.apply(self.appearance)
    }
    
    func render(_ message: Message) {
        self.infoTextView.textAlignment = .center
        
        self.infoTextView.markdownText = message.message
    }
    
    private func apply(_ appearance: InfoTableViewCellAppearance) {
        self.infoTextView.appearance = appearance.textViewAppearance
        
        self.topLayoutConstraint.constant = appearance.contentInset?.top ?? 0
        self.leftLayoutConstraint.constant = appearance.contentInset?.left ?? 0
        self.bottomLayoutConstraint.constant = appearance.contentInset?.bottom ?? 0
        self.rightLayoutConstraint.constant = appearance.contentInset?.right ?? 0
    }
}

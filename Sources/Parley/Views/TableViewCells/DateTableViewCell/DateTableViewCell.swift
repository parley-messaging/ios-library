import UIKit

final class DateTableViewCell: UITableViewCell {
    
    @IBOutlet weak var timeView: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var topLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightLayoutConstraint: NSLayoutConstraint!
    
    var appearance = DateTableViewCellAppearance() {
        didSet {
            self.apply(self.appearance)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.apply(self.appearance)
    }
    
    func render(_ message: Message) {
        self.timeLabel.text = message.time?.asDate()
    }
    
    private func apply(_ appearance: DateTableViewCellAppearance) {
        self.timeView.backgroundColor = appearance.backgroundColor
        self.timeView.layer.cornerRadius = CGFloat(appearance.cornerRadius)
        
        self.timeLabel.font = appearance.textFont
        self.timeLabel.textColor = appearance.textColor
        
        self.timeLabel.adjustsFontForContentSizeCategory = true
        
        self.topLayoutConstraint.constant = appearance.contentInset?.top ?? 0
        self.leftLayoutConstraint.constant = appearance.contentInset?.left ?? 0
        self.bottomLayoutConstraint.constant = appearance.contentInset?.bottom ?? 0
        self.rightLayoutConstraint.constant = appearance.contentInset?.right ?? 0
    }
}

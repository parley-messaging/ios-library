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
            apply(appearance)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        apply(appearance)
    }

    func render(_ message: Message) {
        timeLabel.text = message.time?.asDate()
    }

    private func apply(_ appearance: DateTableViewCellAppearance) {
        timeView.backgroundColor = appearance.backgroundColor
        timeView.layer.cornerRadius = CGFloat(appearance.cornerRadius)

        timeLabel.font = appearance.textFont
        timeLabel.textColor = appearance.textColor

        timeLabel.adjustsFontForContentSizeCategory = true

        topLayoutConstraint.constant = appearance.contentInset?.top ?? 0
        leftLayoutConstraint.constant = appearance.contentInset?.left ?? 0
        bottomLayoutConstraint.constant = appearance.contentInset?.bottom ?? 0
        rightLayoutConstraint.constant = appearance.contentInset?.right ?? 0
    }
}

import UIKit

final class DateTableViewCell: UITableViewCell {

    @IBOutlet private weak var timeView: UIView!
    @IBOutlet private weak var timeLabel: UILabel!

    @IBOutlet private weak var topLayoutConstraint: NSLayoutConstraint!
    @IBOutlet private weak var leftLayoutConstraint: NSLayoutConstraint!
    @IBOutlet private weak var bottomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet private weak var rightLayoutConstraint: NSLayoutConstraint!

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
        timeLabel.text = message.time?.asDate(style: appearance.style)
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

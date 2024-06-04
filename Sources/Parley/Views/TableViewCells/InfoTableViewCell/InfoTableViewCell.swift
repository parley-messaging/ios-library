import UIKit

final class InfoTableViewCell: UITableViewCell {

    @IBOutlet weak var infoTextView: ParleyTextView! {
        didSet {
            infoTextView.appearance.paragraphStyle.alignment = .center
        }
    }

    @IBOutlet weak var topLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightLayoutConstraint: NSLayoutConstraint!

    var appearance = InfoTableViewCellAppearance() {
        didSet {
            apply(appearance)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        apply(appearance)
    }

    func render(_ message: Message) {
        infoTextView.textAlignment = .center

        infoTextView.markdownText = message.message
    }

    private func apply(_ appearance: InfoTableViewCellAppearance) {
        infoTextView.appearance = appearance.textViewAppearance

        topLayoutConstraint.constant = appearance.contentInset?.top ?? 0
        leftLayoutConstraint.constant = appearance.contentInset?.left ?? 0
        bottomLayoutConstraint.constant = appearance.contentInset?.bottom ?? 0
        rightLayoutConstraint.constant = appearance.contentInset?.right ?? 0
    }
}

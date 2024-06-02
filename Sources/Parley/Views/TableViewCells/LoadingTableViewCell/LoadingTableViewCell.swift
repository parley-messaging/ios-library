import UIKit

final class LoadingTableViewCell: UITableViewCell {

    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!

    @IBOutlet weak var topLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightLayoutConstraint: NSLayoutConstraint!

    var appearance = LoadingTableViewCellAppearance() {
        didSet {
            apply(appearance)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        apply(appearance)
    }

    func startAnimating() {
        activityIndicatorView.startAnimating()
    }

    func stopAnimating() {
        activityIndicatorView.stopAnimating()
    }

    private func apply(_ appearance: LoadingTableViewCellAppearance) {
        activityIndicatorView.color = appearance.loaderTintColor

        topLayoutConstraint.constant = appearance.contentInset?.top ?? 0
        leftLayoutConstraint.constant = appearance.contentInset?.left ?? 0
        bottomLayoutConstraint.constant = appearance.contentInset?.bottom ?? 0
        rightLayoutConstraint.constant = appearance.contentInset?.right ?? 0
    }
}

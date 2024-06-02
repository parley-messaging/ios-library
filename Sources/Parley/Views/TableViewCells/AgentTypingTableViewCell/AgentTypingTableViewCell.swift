import UIKit

final class AgentTypingTableViewCell: UITableViewCell {

    @IBOutlet weak var backgroundImageView: UIImageView!

    @IBOutlet weak var contentTopLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentLeftLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentBottomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentRightLayoutConstraint: NSLayoutConstraint!

    @IBOutlet weak var dot1View: UIView!
    @IBOutlet weak var dot2View: UIView!
    @IBOutlet weak var dot3View: UIView!

    private var startTimer: Timer?

    var appearance = AgentTypingTableViewCellAppearance() {
        didSet {
            apply(appearance)
        }
    }

    private var animating = false

    override func awakeFromNib() {
        super.awakeFromNib()

        dot1View.layer.cornerRadius = dot1View.bounds.width / 2
        dot2View.layer.cornerRadius = dot2View.bounds.width / 2
        dot3View.layer.cornerRadius = dot3View.bounds.width / 2

        apply(appearance)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        dot1View.transform = CGAffineTransform(scaleX: 1, y: 1)
        dot2View.transform = CGAffineTransform(scaleX: 1, y: 1)
        dot3View.transform = CGAffineTransform(scaleX: 1, y: 1)
    }

    func startAnimating() {
        stopAnimating()

        startTimer?.invalidate()
        startTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { _ in
            self.animating = true

            self.animation1()
        })
    }

    func stopAnimating() {
        animating = false
    }

    private func animation1() {
        if !animating { return }

        UIView.animate(withDuration: 0.2, delay: 0.3, animations: {
            self.dot1View.alpha = 1
            self.dot1View.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }) { finished in
            if !finished { return }

            self.animation2()
        }
    }

    private func animation2() {
        if !animating { return }

        UIView.animate(withDuration: 0.2, animations: {
            self.dot1View.alpha = 0.5
            self.dot1View.transform = CGAffineTransform(scaleX: 1, y: 1)

            self.dot2View.alpha = 1
            self.dot2View.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }) { finished in
            if !finished { return }

            self.animation3()
        }
    }

    private func animation3() {
        if !animating { return }

        UIView.animate(withDuration: 0.2, animations: {
            self.dot2View.alpha = 0.5
            self.dot2View.transform = CGAffineTransform(scaleX: 1, y: 1)

            self.dot3View.alpha = 1
            self.dot3View.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }) { finished in
            if !finished { return }

            self.animation4()
        }
    }

    private func animation4() {
        if !animating { return }

        UIView.animate(withDuration: 0.2, animations: {
            self.dot3View.alpha = 0.5
            self.dot3View.transform = CGAffineTransform(scaleX: 1, y: 1)
        }) { finished in
            if !finished { return }

            self.animation1()
        }
    }

    private func apply(_ appearance: AgentTypingTableViewCellAppearance) {
        if let backgroundTintColor = appearance.backgroundTintColor {
            backgroundImageView.image = appearance.backgroundImage?.withRenderingMode(.alwaysTemplate)
            backgroundImageView.tintColor = backgroundTintColor
        } else {
            backgroundImageView.image = appearance.backgroundImage?.withRenderingMode(.alwaysOriginal)
        }

        contentTopLayoutConstraint.constant = appearance.contentInset?.top ?? 0
        contentLeftLayoutConstraint.constant = appearance.contentInset?.left ?? 0
        contentBottomLayoutConstraint.constant = appearance.contentInset?.bottom ?? 0
        contentRightLayoutConstraint.constant = appearance.contentInset?.right ?? 0

        dot1View.alpha = 0.5
        dot1View.backgroundColor = appearance.dotColor

        dot2View.alpha = 0.5
        dot2View.backgroundColor = appearance.dotColor

        dot3View.alpha = 0.5
        dot3View.backgroundColor = appearance.dotColor
    }
}

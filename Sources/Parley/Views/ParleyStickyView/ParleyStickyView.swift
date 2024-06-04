import UIKit

final class ParleyStickyView: UIView {

    @IBOutlet private weak var contentHeightConstraint: NSLayoutConstraint!

    @IBOutlet var contentView: UIView! {
        didSet {
            contentView.backgroundColor = UIColor.clear
        }
    }

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var textView: ParleyTextView!

    private var heightObserver: NSKeyValueObservation?
    private let totalVerticalContentInsets: CGFloat = 16

    var appearance = ParleyStickyViewAppearance() {
        didSet {
            apply(appearance)
        }
    }

    var text: String? {
        didSet {
            textView.markdownText = text
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setup()
    }

    private func setup() {
        loadXib()

        apply(appearance)
        watchContentHeight()
    }

    private func loadXib() {
        Bundle.module.loadNibNamed("ParleyStickyView", owner: self, options: nil)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)

        NSLayoutConstraint(
            item: self,
            attribute: .leading,
            relatedBy: .equal,
            toItem: contentView,
            attribute: .leading,
            multiplier: 1.0,
            constant: 0
        ).isActive = true
        NSLayoutConstraint(
            item: self,
            attribute: .trailing,
            relatedBy: .equal,
            toItem: contentView,
            attribute: .trailing,
            multiplier: 1.0,
            constant: 0
        ).isActive = true
        NSLayoutConstraint(
            item: self,
            attribute: .top,
            relatedBy: .equal,
            toItem: contentView,
            attribute: .top,
            multiplier: 1.0,
            constant: 0
        ).isActive = true
        NSLayoutConstraint(
            item: self,
            attribute: .bottom,
            relatedBy: .equal,
            toItem: contentView,
            attribute: .bottom,
            multiplier: 1.0,
            constant: 0
        ).isActive = true
    }

    private func apply(_ appearance: ParleyStickyViewAppearance) {
        backgroundColor = appearance.backgroundColor

        if let iconTintColor = appearance.iconTintColor {
            imageView.image = appearance.icon.withRenderingMode(.alwaysTemplate)
            imageView.tintColor = iconTintColor
        } else {
            imageView.image = appearance.icon.withRenderingMode(.alwaysOriginal)
        }

        textView.appearance = appearance.textViewAppearance

        textView.markdownText = text

        textView.contentInset = UIEdgeInsets(
            top: totalVerticalContentInsets / 2,
            left: 0,
            bottom: totalVerticalContentInsets / 2,
            right: 0
        )
        textView.isScrollEnabled = true
    }

    private func watchContentHeight() {
        heightObserver = observe(\.textView?.contentSize, options: [.initial, .new]) { [weak self] _, change in
            guard
                let newValue = change.newValue,
                let height = newValue?.height,
                let self else { return }

            let totalVerticalInsets: CGFloat = totalVerticalContentInsets
            contentHeightConstraint.constant = min(200, height + totalVerticalInsets)

            layoutIfNeeded()
        }
    }
}

import UIKit

final class SuggestionCollectionViewCell: UICollectionViewCell {

    // Balloon
    @IBOutlet weak var balloonImageView: UIImageView!

    // Balloon content
    @IBOutlet weak var balloonContentView: UIView!

    @IBOutlet weak var balloonContentTopLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var balloonContentLeftLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var balloonContentRightLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var balloonContentBottomLayoutConstraint: NSLayoutConstraint!

    // Suggestion
    @IBOutlet weak var suggestionLabel: UILabel!

    @IBOutlet weak var suggestionMaxWidthLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var suggestionTopLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var suggestionLeftLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var suggestionRightLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var suggestionBottomLayoutConstraint: NSLayoutConstraint!

    var appearance = SuggestionCollectionViewCellAppearance() {
        didSet {
            apply(appearance)
        }
    }

    func render(_ suggestion: String) {
        suggestionLabel.text = suggestion
        setupAccessibilityOptions(suggestion)
    }

    private func setupAccessibilityOptions(_ suggestion: String) {
        isAccessibilityElement = true
        accessibilityLabel = suggestion
        accessibilityTraits = [.button]
    }

    private func apply(_ appearance: SuggestionCollectionViewCellAppearance) {
        // Balloon
        if let backgroundTintColor = appearance.balloonTintColor {
            balloonImageView.image = appearance.balloonImage?.withRenderingMode(.alwaysTemplate)
            balloonImageView.tintColor = backgroundTintColor
        } else {
            balloonImageView.image = appearance.balloonImage?.withRenderingMode(.alwaysOriginal)
            balloonImageView.tintColor = nil
        }

        // Balloon content
        balloonContentTopLayoutConstraint.constant = appearance.balloonContentInsets?.top ?? 0
        balloonContentLeftLayoutConstraint.constant = appearance.balloonContentInsets?.left ?? 0
        balloonContentRightLayoutConstraint.constant = 0 - (appearance.balloonContentInsets?.right ?? 0)
        balloonContentBottomLayoutConstraint.constant = 0 - (appearance.balloonContentInsets?.bottom ?? 0)

        // Suggestion
        suggestionLabel.textColor = appearance.suggestionColor
        suggestionLabel.font = appearance.suggestionFont

        suggestionMaxWidthLayoutConstraint.constant = appearance.suggestionMaxWidth

        suggestionTopLayoutConstraint.constant = appearance.suggestionInsets?.top ?? 0
        suggestionLeftLayoutConstraint.constant = appearance.suggestionInsets?.left ?? 0
        suggestionRightLayoutConstraint.constant = appearance.suggestionInsets?.right ?? 0
        suggestionBottomLayoutConstraint.constant = appearance.suggestionInsets?.bottom ?? 0
    }

    // MARK: View
    override func awakeFromNib() {
        super.awakeFromNib()

        apply(appearance)
    }

    static func calculateHeight(_ appearance: SuggestionCollectionViewCellAppearance, _ suggestion: String) -> CGFloat {
        let labelWidth = appearance.suggestionMaxWidth

        var height: CGFloat = 0
        height += appearance.balloonContentInsets?.top ?? 0
        height += appearance.balloonContentInsets?.bottom ?? 0

        height += appearance.suggestionInsets?.top ?? 0
        height += appearance.suggestionInsets?.bottom ?? 0

        let labelHeight = suggestion.height(withConstrainedWidth: labelWidth, font: appearance.suggestionFont)
        height += labelHeight

        return height
    }
}

import UIKit

class SuggestionCollectionViewCell: UICollectionViewCell {
    
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
    
    internal var appearance: SuggestionCollectionViewCellAppearance = SuggestionCollectionViewCellAppearance() {
        didSet {
            self.apply(self.appearance)
        }
    }
    
    internal func render(_ suggestion: String) {
        self.suggestionLabel.text = suggestion
    }
    
    private func apply(_ appearance: SuggestionCollectionViewCellAppearance) {
        // Balloon
        if let backgroundTintColor = appearance.balloonTintColor {
            self.balloonImageView.image = appearance.balloonImage?.withRenderingMode(.alwaysTemplate)
            self.balloonImageView.tintColor = backgroundTintColor
        } else {
            self.balloonImageView.image = appearance.balloonImage?.withRenderingMode(.alwaysOriginal)
            self.balloonImageView.tintColor = nil
        }
        
        // Balloon content
        self.balloonContentTopLayoutConstraint.constant = appearance.balloonContentInsets?.top ?? 0
        self.balloonContentLeftLayoutConstraint.constant = appearance.balloonContentInsets?.left ?? 0
        self.balloonContentRightLayoutConstraint.constant = 0 - (appearance.balloonContentInsets?.right ?? 0)
        self.balloonContentBottomLayoutConstraint.constant = 0 - (appearance.balloonContentInsets?.bottom ?? 0)
        
        // Suggestion
        self.suggestionLabel.textColor = appearance.suggestionColor
        self.suggestionLabel.font = appearance.suggestionFont
        
        self.suggestionMaxWidthLayoutConstraint.constant = appearance.suggestionMaxWidth
        
        self.suggestionTopLayoutConstraint.constant = appearance.suggestionInsets?.top ?? 0
        self.suggestionLeftLayoutConstraint.constant = appearance.suggestionInsets?.left ?? 0
        self.suggestionRightLayoutConstraint.constant = appearance.suggestionInsets?.right ?? 0
        self.suggestionBottomLayoutConstraint.constant = appearance.suggestionInsets?.bottom ?? 0
    }
    
    // MARK: View
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.apply(self.appearance)
    }
    
    internal static func calculateHeight(_ appearance: SuggestionCollectionViewCellAppearance, _ suggestion: String) -> CGFloat {
        var width = appearance.suggestionMaxWidth
        
        width -= appearance.balloonContentInsets?.left ?? 0
        width -= appearance.balloonContentInsets?.right ?? 0
        
        width -= appearance.suggestionInsets?.left ?? 0
        width -= appearance.suggestionInsets?.right ?? 0
        
        var height: CGFloat = 0
        height += appearance.balloonContentInsets?.top ?? 0
        height += appearance.balloonContentInsets?.bottom ?? 0
        
        height += appearance.suggestionInsets?.top ?? 0
        height += appearance.suggestionInsets?.bottom ?? 0
        
        height += suggestion.height(withConstrainedWidth: width, font: appearance.suggestionFont, lines: 2)
        
        height += 1
        
        return height
    }
}

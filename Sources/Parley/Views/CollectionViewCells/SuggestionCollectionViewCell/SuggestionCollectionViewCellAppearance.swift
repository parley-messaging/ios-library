import UIKit

public class SuggestionCollectionViewCellAppearance {

    // Balloon
    public var balloonImage: UIImage?
    public var balloonTintColor: UIColor?

    public var balloonContentInsets: UIEdgeInsets? = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)

    // Suggestion
    public var suggestionColor = UIColor(red: 0.29, green: 0.37, blue: 0.51, alpha: 1.0)
    public var suggestionFont = UIFont.boldSystemFont(ofSize: 14)

    public var suggestionMaxWidth: CGFloat = 350
    public var suggestionInsets: UIEdgeInsets?

    init() {
        let edgeInsets = UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)

        balloonImage = UIImage(named: "suggestion", in: .module, compatibleWith: nil)?
            .resizableImage(withCapInsets: edgeInsets)
    }
}

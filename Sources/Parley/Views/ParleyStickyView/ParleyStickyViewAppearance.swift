import UIKit

public struct ParleyStickyViewAppearance {

    public var backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.9)

    public var icon: UIImage
    public var iconTintColor: UIColor? = UIColor(red: 0.29, green: 0.37, blue: 0.51, alpha: 1.0)

    public var textViewAppearance = ParleyTextViewAppearance(
        textColor: UIColor(red: 0.29, green: 0.37, blue: 0.51, alpha: 1.0),
        linkTintColor: UIColor(red: 0.08, green: 0.49, blue: 0.98, alpha: 1.0),
        regularFont: .systemFont(ofSize: 13),
        italicFont: .italicSystemFont(ofSize: 13),
        boldFont: .boldSystemFont(ofSize: 13),
        linkFont: .systemFont(ofSize: 13)
    )

    init() {
        icon = UIImage(named: "ic_error_outline", in: .module, compatibleWith: nil)!
    }
}

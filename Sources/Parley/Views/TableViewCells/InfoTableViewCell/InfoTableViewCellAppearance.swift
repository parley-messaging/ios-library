import UIKit

public class InfoTableViewCellAppearance {
    public var textViewAppearance: ParleyTextViewAppearance = {
        let appearance = ParleyTextViewAppearance()
        appearance.textColor = UIColor(red:0.29, green:0.37, blue:0.51, alpha:1.0)
        return appearance
    }()

    public var contentInset: UIEdgeInsets? = UIEdgeInsets(top: 16, left: 32, bottom: 16, right: 32)
}

import UIKit

public final class ParleyTextViewAppearance {
    public var paragraphStyle = NSMutableParagraphStyle()
    public var textColor: UIColor = .white
    public var linkTintColor: UIColor? = nil

    public var regularFont: UIFont = .systemFont(ofSize: 14)
    public var italicFont: UIFont = .italicSystemFont(ofSize: 14)
    public var boldFont: UIFont = .boldSystemFont(ofSize: 14)
    public var linkFont: UIFont = .systemFont(ofSize: 14)
}

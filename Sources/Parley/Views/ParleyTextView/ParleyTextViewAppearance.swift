import UIKit

public final class ParleyTextViewAppearance {
    public var paragraphStyle = NSMutableParagraphStyle()
    public var textColor: UIColor = .white
    public var linkTintColor: UIColor? = nil

    @ParleyScaledFont(textStyle: .body) public var regularFont: UIFont = .systemFont(ofSize: 14)
    @ParleyScaledFont(textStyle: .body) public var italicFont: UIFont = .italicSystemFont(ofSize: 14)
    @ParleyScaledFont(textStyle: .body) public var boldFont: UIFont = .boldSystemFont(ofSize: 14)
    @ParleyScaledFont(textStyle: .body) public var linkFont: UIFont = .systemFont(ofSize: 14)
}

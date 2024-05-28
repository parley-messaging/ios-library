import UIKit

public final class ParleyTextViewAppearance {
    public var paragraphStyle = NSMutableParagraphStyle()
    public var textColor: UIColor = .white
    public var linkTintColor: UIColor? = nil

    @ParleyScaledFont(textStyle: .body) public var regularFont = .systemFont(ofSize: 14)
    @ParleyScaledFont(textStyle: .body) public var italicFont = .italicSystemFont(ofSize: 14)
    @ParleyScaledFont(textStyle: .body) public var boldFont = .boldSystemFont(ofSize: 14)
    @ParleyScaledFont(textStyle: .body) public var linkFont = .systemFont(ofSize: 14)
}

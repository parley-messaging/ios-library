import UIKit

public final class ParleyTextViewAppearance {
    var paragraphStyle = NSMutableParagraphStyle()
    var textColor: UIColor = .white
    var linkTintColor: UIColor? = nil

    @ParleyScaledFont(textStyle: .body) var regularFont = .systemFont(ofSize: 14)
    @ParleyScaledFont(textStyle: .body) var italicFont = .italicSystemFont(ofSize: 14)
    @ParleyScaledFont(textStyle: .body) var boldFont = .boldSystemFont(ofSize: 14)
    @ParleyScaledFont(textStyle: .body) var linkFont = .systemFont(ofSize: 14)
}

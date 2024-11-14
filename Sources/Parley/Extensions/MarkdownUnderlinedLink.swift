import MarkdownKit
import UIKit

final class MarkdownUnderlinedLink: MarkdownLink {
    
    init(color: UIColor, font: UIFont) {
        super.init(font: font, color: color)
    }
    
    override func match(_ match: NSTextCheckingResult, attributedString: NSMutableAttributedString) {
        attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: match.range)
        super.match(match, attributedString: attributedString)
    }
}

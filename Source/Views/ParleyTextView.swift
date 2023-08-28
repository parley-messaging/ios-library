import MarkdownKit
import UIKit

class ParleyTextView: UITextView {
    
    var markdownText: String? {
        didSet {
            if let text = self.markdownText {
                let markdownParser = MarkdownParser(
                    font: self.regularFont,
                    color: self.textColor ?? UIColor.white
                )
                markdownParser.link.color = self.tintColor ?? UIColor.white
                markdownParser.italic.font = self.italicFont
                markdownParser.bold.font = self.boldFont
                markdownParser.enabledElements = [.bold, .italic, .link]
                
                let attributedText = NSMutableAttributedString(attributedString: markdownParser.parse(text))
                attributedText.addAttribute(.paragraphStyle, value: self.paragraphStyle, range: NSRange(location: 0, length: attributedText.length))
                
                self.attributedText = attributedText
            } else {
                self.attributedText = nil
            }
        }
    }
    
    var paragraphStyle = NSMutableParagraphStyle()
    
    @ParleyScaledFont(textStyle: .body) var regularFont = .systemFont(ofSize: 14)
    @ParleyScaledFont(textStyle: .body) var italicFont = .italicSystemFont(ofSize: 14)
    @ParleyScaledFont(textStyle: .body) var boldFont = .boldSystemFont(ofSize: 14)
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setup()
    }
    
    private func setup() {
        isSelectable = true
        isEditable = false
        alwaysBounceVertical = false
        
        textContainerInset = .zero
        textContainer.lineFragmentPadding = 0
        
        adjustsFontForContentSizeCategory = true
    }
}

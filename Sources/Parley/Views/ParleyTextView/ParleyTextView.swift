import MarkdownKit
import UIKit

final class ParleyTextView: UITextView {

    var appearance = ParleyTextViewAppearance() {
        didSet {
            updateAttributedText()
        }
    }

    var markdownText: String? {
        didSet {
            updateAttributedText()
        }
    }

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)

        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setup()
    }

    private func setup() {
        isSelectable = true
        isEditable = false
        isScrollEnabled = false
        alwaysBounceVertical = false

        textContainerInset = .zero
        textContainer.lineFragmentPadding = 0

        adjustsFontForContentSizeCategory = true

        linkTextAttributes = [:]
    }

    private func updateAttributedText() {
        if let text = markdownText {
            attributedText = parse(markdownText: text)
        } else {
            attributedText = nil
        }
    }

    private func makeParser(with appearance: ParleyTextViewAppearance) -> MarkdownParser {
        let parser = MarkdownParser(
            font: appearance.regularFont,
            color: appearance.textColor
        )

        parser.link.color = appearance.linkTintColor ?? tintColor
        parser.link.font = appearance.linkFont
        parser.italic.font = appearance.italicFont
        parser.bold.font = appearance.boldFont
        parser.enabledElements = [.bold, .italic, .link]

        return parser
    }

    private func parse(markdownText: String) -> NSAttributedString {
        let parser = makeParser(with: appearance)

        let attributedText = NSMutableAttributedString(attributedString: parser.parse(markdownText))
        attributedText.addAttribute(
            .paragraphStyle,
            value: appearance.paragraphStyle,
            range: NSRange(location: 0, length: attributedText.length)
        )

        return attributedText
    }
}

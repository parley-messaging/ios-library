import MarkdownKit
import UIKit

final class ParleyTextView: UITextView {
    
    protocol SizeDelegate: AnyObject {
        func sizeDidChange(for textView: ParleyTextView, change: NSKeyValueObservedChange<CGSize>)
    }
    
    private var heightObserver: NSKeyValueObservation?
    
    deinit {
        heightObserver?.invalidate()
        heightObserver = nil
    }

    var appearance = ParleyTextViewAppearance() {
        didSet {
            linkFont = appearance.linkFont
            regularFont = appearance.regularFont
            italicFont = appearance.italicFont
            boldFont = appearance.boldFont

            updateAttributedText()
        }
    }

    @ParleyScaledFont(textStyle: .body) var linkFont = .systemFont(ofSize: 14)
    @ParleyScaledFont(textStyle: .body) var regularFont = .systemFont(ofSize: 14)
    @ParleyScaledFont(textStyle: .body) var italicFont = .italicSystemFont(ofSize: 14)
    @ParleyScaledFont(textStyle: .body) var boldFont = .boldSystemFont(ofSize: 14)

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

    private func makeParser(with appearance: ParleyTextViewAppearance) -> MarkdownParser {
        let parser = MarkdownParser(
            font: regularFont,
            color: appearance.textColor,
            customElements: [MarkdownUnderlinedLink(color: appearance.linkTintColor ?? tintColor, font: linkFont)]
        )

        parser.italic.font = italicFont
        parser.bold.font = boldFont
        parser.enabledElements = [.bold, .italic]

        return parser
    }
    
    func observeContentHeight(delegate: any SizeDelegate) {
        heightObserver = observe(\.self.contentSize, options: [
            .initial,
            .new,
        ], changeHandler: { [weak delegate] textView, change in
            delegate?.sizeDidChange(for: textView, change: change)
        })
    }
}

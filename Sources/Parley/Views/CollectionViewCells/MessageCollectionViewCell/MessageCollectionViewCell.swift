import UIKit

final class MessageCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var parleyMessageView: ParleyMessageView!

    @IBOutlet weak var widthLayoutConstraint: NSLayoutConstraint!

    weak var delegate: MessageTableViewCellDelegate? {
        didSet {
            parleyMessageView.delegate = delegate
        }
    }

    var appearance: MessageCollectionViewCellAppearance? {
        didSet {
            guard let appearance else { return }

            apply(appearance)
        }
    }

    func render(_ message: Message, time: Date?, mediaLoader: MediaLoaderProtocol?, shareManager: ShareManager?) {
        parleyMessageView.set(message: message, forcedTime: time, mediaLoader: mediaLoader, shareManager: shareManager)
        setupAccessibilityOptions(for: message)
    }

    private func setupAccessibilityOptions(for message: Message) {
        isAccessibilityElement = true
        watchForVoiceOverDidChangeNotification(observer: self)
        accessibilityLabel = Message.Accessibility.getAccessibilityLabelDescription(for: message)

        accessibilityCustomActions = Message.Accessibility.getAccessibilityCustomActions(
            for: message,
            actionHandler: { [weak parleyMessageView] _, button in
                parleyMessageView?.delegate?.didSelect(button)
            }
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(UIAccessibility.voiceOverStatusDidChangeNotification)
    }

    override func voiceOverDidChange(isVoiceOverRunning: Bool) {
        // Disable drag interaction for VoiceOver.
        isUserInteractionEnabled = !isVoiceOverRunning
    }

    private func apply(_ appearance: MessageCollectionViewCellAppearance) {
        parleyMessageView.apply(appearance)

        widthLayoutConstraint.constant = CGFloat(appearance.width)
    }

    static func calculateSize(_ appearance: MessageCollectionViewCellAppearance, _ message: Message) -> CGSize {
        let balloonWidth: CGFloat = appearance.width
        var contentWidth = balloonWidth
        contentWidth -= appearance.balloonContentInsets?.left ?? 0
        contentWidth -= appearance.balloonContentInsets?.right ?? 0
        contentWidth -= appearance.balloonContentTextInsets?.left ?? 0
        contentWidth -= appearance.balloonContentTextInsets?.right ?? 0

        var totalHeight: CGFloat = 0
        totalHeight += appearance.balloonContentInsets?.top ?? 0
        totalHeight += appearance.balloonContentInsets?.bottom ?? 0

        var showTopSeparator = true
        if message.hasImage {
            totalHeight += 160

            totalHeight += appearance.imageInsets?.top ?? 0
            totalHeight += appearance.imageInsets?.bottom ?? 0
            showTopSeparator = false
        } else if let name = message.agent?.name, appearance.name {
            totalHeight += appearance.nameInsets?.top ?? 0
            totalHeight += appearance.nameInsets?.bottom ?? 0
            totalHeight += name.height(withConstrainedWidth: contentWidth, font: appearance.nameFont)
        }

        if let title = message.title {
            totalHeight += appearance.titleInsets?.top ?? 0
            totalHeight += appearance.titleInsets?.bottom ?? 0

            totalHeight += title.height(withConstrainedWidth: contentWidth, font: appearance.titleFont)
        }

        if let message = message.message {
            totalHeight += appearance.messageInsets?.top ?? 0
            totalHeight += appearance.messageInsets?.bottom ?? 0

            totalHeight += message.height(
                withConstrainedWidth: contentWidth,
                font: appearance.messageTextViewAppearance.regularFont
            )
        }

        if message.hasFile {
            if showTopSeparator {
                // Top separator
                totalHeight += appearance.separatorInset?.top ?? 0
                totalHeight += appearance.separatorInset?.bottom ?? 0
                totalHeight += 1
            }

            totalHeight += appearance.fileContentInsets?.top ?? 0
            totalHeight += appearance.fileContentInsets?.bottom ?? 0
            totalHeight += max(
                ParleyLocalizationKey.messageFileOpen.localized().height(
                    withConstrainedWidth: contentWidth,
                    font: appearance.buttonFont
                ),
                message.media?.displayFileName.height(
                    withConstrainedWidth: contentWidth,
                    font: appearance.fileNameFont
                ) ?? 0
            )

            // Bottom separator
            totalHeight += appearance.separatorInset?.top ?? 0
            totalHeight += appearance.separatorInset?.bottom ?? 0
            totalHeight += 1

            showTopSeparator = false
        }

        if message.hasButtons {
            totalHeight += appearance.buttonsInsets?.top ?? 0
            totalHeight += appearance.buttonsInsets?.bottom ?? 0

            var buttonWidth = balloonWidth
            buttonWidth -= appearance.buttonsInsets?.left ?? 0
            buttonWidth -= appearance.buttonsInsets?.right ?? 0
            buttonWidth -= appearance.buttonInsets?.left ?? 0
            buttonWidth -= appearance.buttonInsets?.right ?? 0

            if showTopSeparator {
                totalHeight += 1 // Initial separator
                totalHeight += appearance.separatorInset?.top ?? 0
                totalHeight += appearance.separatorInset?.bottom ?? 0
            }
            message.buttons?.forEach({ (button: MessageButton) in
                totalHeight += appearance.buttonInsets?.top ?? 0
                totalHeight += appearance.buttonInsets?.bottom ?? 0
                totalHeight += button.title.height(withConstrainedWidth: buttonWidth, font: appearance.buttonFont)
                totalHeight += 1 // Button separator
                totalHeight += appearance.separatorInset?.top ?? 0
                totalHeight += appearance.separatorInset?.bottom ?? 0
            })

            if message.message == nil && message.title == nil && !message.hasImage {
                totalHeight += appearance.balloonContentTextInsets?.top ?? 0
            }
        }

        if message.message != nil || message.title != nil || message.hasButtons || !message.hasImage {
            totalHeight += appearance.metaInsets?.top ?? 0
            totalHeight += appearance.metaInsets?.bottom ?? 0

            totalHeight += (message.time?.asTime() ?? "")
                .height(withConstrainedWidth: contentWidth, font: appearance.timeFont)
        }

        if message.message != nil || message.title != nil || message.hasImage {
            totalHeight += appearance.balloonContentTextInsets?.top ?? 0
            totalHeight += appearance.balloonContentTextInsets?.bottom ?? 0
        }

        totalHeight += 4
        return CGSize(width: balloonWidth, height: totalHeight)
    }
}

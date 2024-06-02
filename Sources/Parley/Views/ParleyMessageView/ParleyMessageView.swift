import Foundation
import UIKit

final class ParleyMessageView: UIView {

    enum Display {
        case hidden
        case image
        case message
    }

    // MARK: - IBOutlets

    @IBOutlet private weak var contentView: UIView!

    // Balloon
    @IBOutlet private weak var balloonImageView: UIImageView! {
        didSet {
            balloonImageView.isAccessibilityElement = false
            balloonImageView.accessibilityTraits = .none
        }
    }

    // Balloon content
    @IBOutlet private weak var balloonContentView: UIView!

    @IBOutlet private weak var balloonContentTopLayoutConstraint: NSLayoutConstraint!
    @IBOutlet private weak var balloonContentLeftLayoutConstraint: NSLayoutConstraint!
    @IBOutlet private weak var balloonContentRightLayoutConstraint: NSLayoutConstraint!
    @IBOutlet private weak var balloonContentBottomLayoutConstraint: NSLayoutConstraint!

    // Image
    @IBOutlet private weak var imageHolderView: UIView!

    @IBOutlet private weak var imageImageView: ParleyImageView!

    @IBOutlet private weak var imageTopLayoutConstraint: NSLayoutConstraint!
    @IBOutlet private weak var imageLeftLayoutConstraint: NSLayoutConstraint!
    @IBOutlet private weak var imageRightLayoutConstraint: NSLayoutConstraint!
    @IBOutlet private weak var imageBottomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet private weak var imageMinimumWidthConstraint: NSLayoutConstraint!

    @IBOutlet private weak var imageActivityIndicatorView: UIActivityIndicatorView!

    @IBOutlet private weak var imageNameLabel: UILabel!

    @IBOutlet private weak var imageNameTopLayoutConstraint: NSLayoutConstraint!
    @IBOutlet private weak var imageNameLeftLayoutConstraint: NSLayoutConstraint!
    @IBOutlet private weak var imageNameRightLayoutConstraint: NSLayoutConstraint!

    @IBOutlet private weak var imageMetaLeftLayoutConstraint: NSLayoutConstraint!
    @IBOutlet private weak var imageMetaRightLayoutConstraint: NSLayoutConstraint!
    @IBOutlet private weak var imageMetaBottomLayoutConstraint: NSLayoutConstraint!

    @IBOutlet private weak var imageMetaTimeLabel: UILabel!
    @IBOutlet private weak var imageMetaStatusImageView: UIImageView!
    @IBOutlet private weak var imageMetaStatusImageViewWidth: NSLayoutConstraint!

    @IBOutlet private weak var imageFailureMessageLabel: UILabel!

    // Name
    @IBOutlet private weak var nameView: UIView!
    @IBOutlet private weak var nameLabel: UILabel!

    @IBOutlet private weak var nameTopLayoutConstraint: NSLayoutConstraint!
    @IBOutlet private weak var nameLeftLayoutConstraint: NSLayoutConstraint!
    @IBOutlet private weak var nameRightLayoutConstraint: NSLayoutConstraint!
    @IBOutlet private weak var nameBottomLayoutConstraint: NSLayoutConstraint!

    // Title
    @IBOutlet private weak var titleView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!

    @IBOutlet private weak var titleTopLayoutConstraint: NSLayoutConstraint!
    @IBOutlet private weak var titleLeftLayoutConstraint: NSLayoutConstraint!
    @IBOutlet private weak var titleRightLayoutConstraint: NSLayoutConstraint!
    @IBOutlet private weak var titleBottomLayoutConstraint: NSLayoutConstraint!

    // Message
    @IBOutlet private weak var messageView: UIView!
    @IBOutlet private weak var messageTextView: ParleyTextView!

    @IBOutlet private weak var messageTopLayoutConstraint: NSLayoutConstraint!
    @IBOutlet private weak var messageLeftLayoutConstraint: NSLayoutConstraint!
    @IBOutlet private weak var messageRightLayoutConstraint: NSLayoutConstraint!
    @IBOutlet private weak var messageBottomLayoutConstraint: NSLayoutConstraint!

    // Meta
    @IBOutlet private weak var metaView: UIView!

    @IBOutlet private weak var metaTopLayoutConstraint: NSLayoutConstraint!
    @IBOutlet private weak var metaLeftLayoutConstraint: NSLayoutConstraint!
    @IBOutlet private weak var metaRightLayoutConstraint: NSLayoutConstraint!
    @IBOutlet private weak var metaBottomLayoutConstraint: NSLayoutConstraint!

    @IBOutlet private weak var timeLabel: UILabel!
    @IBOutlet private weak var statusImageView: UIImageView!
    @IBOutlet private weak var statusImageViewWidth: NSLayoutConstraint!

    // Buttons
    @IBOutlet private weak var buttonsView: UIView!
    @IBOutlet private weak var buttonsStackView: UIStackView!

    @IBOutlet private weak var buttonsTopLayoutConstraint: NSLayoutConstraint!
    @IBOutlet private weak var buttonsLeftLayoutConstraint: NSLayoutConstraint!
    @IBOutlet private weak var buttonsRightLayoutConstraint: NSLayoutConstraint!
    @IBOutlet private weak var buttonsBottomLayoutConstraint: NSLayoutConstraint!

    // Image
    private let imageLoader: ImageLoaderProtocol

    // Helpers
    private var displayName: Display = .message
    private var displayMeta: Display = .message
    private var displayTitle: Display = .hidden

    // Delegate
    weak var delegate: ParleyMessageViewDelegate?

    // MARK: - Appearance
    private var appearance: ParleyMessageViewAppearance?
    private var message: Message!
    private var time: Date?
    private static let minimumImageWidth: CGFloat = 5
    private static let maximumImageWidth: CGFloat = 500

    // MARK: - View
    init(frame: CGRect, imageLoader: ImageLoaderProtocol = Parley.shared.imageLoader) {
        self.imageLoader = imageLoader

        super.init(frame: frame)

        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        imageLoader = Parley.shared.imageLoader

        super.init(coder: aDecoder)

        setup()
    }

    private func setup() {
        loadXib()
        imageActivityIndicatorView.hidesWhenStopped = true
    }

    private func loadXib() {
        Bundle.module.loadNibNamed("ParleyMessageView", owner: self, options: nil)

        addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    func set(message: Message, forcedTime: Date?) {
        self.message = message
        time = forcedTime
        render()
    }

    private func render() {
        renderName()
        renderMeta()
        renderMetaStatus()

        renderTitle()
        renderMessage()

        renderImage()

        renderButtons()
    }

    // MARK: - Render
    private func renderName() {
        if message.agent?.name == nil || !(appearance?.name == true) {
            displayName = .hidden
        } else if message.hasMedium {
            displayName = .image
        } else {
            displayName = .message
        }

        imageNameLabel.text = message.agent?.name
        nameLabel.text = message.agent?.name
        nameLabel.adjustsFontForContentSizeCategory = true

        imageNameLabel.isHidden = displayName != .image
        nameView.isHidden = displayName != .message
    }

    private func renderMeta() {
        if message.message != nil || message.title != nil || message.hasButtons || !message.hasMedium {
            displayMeta = .message
            imageFailureMessageLabel.isHidden = true
        } else {
            displayMeta = .image
            renderImageFailure()
        }

        imageMetaTimeLabel.isHidden = displayMeta != .image
        imageMetaStatusImageView.isHidden = displayMeta != .image

        metaView.isHidden = displayMeta != .message
        renderMetaTime()
    }

    private func renderImageFailure() {
        imageFailureMessageLabel.textColor = appearance?.imageInnerColor
        imageFailureMessageLabel.font = appearance?.timeFont
        imageFailureMessageLabel.adjustsFontForContentSizeCategory = true

        if let failureMessage = formattedFailureMessage() {
            imageFailureMessageLabel.text = failureMessage
            imageFailureMessageLabel.isHidden = false
        } else {
            imageFailureMessageLabel.isHidden = true
        }
    }

    private func formattedFailureMessage() -> String? {
        guard let type = message.responseInfoType else { return nil }
        return MediaUploadNotificationErrorKind(rawValue: type)?.formattedMessage
    }

    private func renderMetaTime() {
        let time = (time ?? message.time)?.asTime() ?? ""

        imageMetaTimeLabel.text = time
        timeLabel.text = time

        imageMetaTimeLabel.isAccessibilityElement = false
        timeLabel.isAccessibilityElement = false

        timeLabel.adjustsFontForContentSizeCategory = true
        imageMetaTimeLabel.adjustsFontForContentSizeCategory = true
    }

    private func renderMetaStatus() {
        if message.type == .user {
            imageMetaStatusImageView.isHidden = displayMeta != .image
            statusImageView.isHidden = displayMeta != .message

            switch message.status {
            case .failed:
                let closeIcon = UIImage.template(named: "ic_close")
                imageMetaStatusImageView.image = closeIcon
                statusImageView.image = closeIcon
            case .pending:
                let clockIcon = UIImage.template(named: "ic_clock")
                imageMetaStatusImageView.image = clockIcon
                statusImageView.image = clockIcon
            case .success:
                let tickIcon = UIImage.template(named: "ic_tick")
                imageMetaStatusImageView.image = tickIcon
                statusImageView.image = tickIcon
            }
        } else {
            imageMetaStatusImageView.isHidden = true
            statusImageView.isHidden = true
        }

        statusImageViewWidth.constant = timeLabel.intrinsicContentSize.height
        imageMetaStatusImageViewWidth.constant = imageMetaTimeLabel.intrinsicContentSize.height
    }

    private func renderTitle() {
        displayTitle = message.title == nil ? .hidden : .message
        titleView.isHidden = displayTitle == .hidden
        titleLabel.text = message.title
        titleLabel.adjustsFontForContentSizeCategory = true

        if displayName == .message {
            titleTopLayoutConstraint.constant = appearance?.titleInsets?.top ?? 0
        } else {
            titleTopLayoutConstraint
                .constant = (appearance?.balloonContentTextInsets?.top ?? 0) + (appearance?.titleInsets?.top ?? 0)
        }
    }

    private func renderMessage() {
        if let message = message.getFormattedMessage() {
            switch (displayName, displayTitle) {
            case (_, .message), (.message, _):
                messageTopLayoutConstraint.constant = appearance?.messageInsets?.top ?? 0
            default:
                messageTopLayoutConstraint
                    .constant = (appearance?.balloonContentTextInsets?.top ?? 0) + (appearance?.messageInsets?.top ?? 0)
            }

            messageView.isHidden = false

            messageTextView.markdownText = message
        } else {
            messageView.isHidden = true

            messageTextView.markdownText = nil
        }
    }

    private func renderImage() {
        renderImageCorners()
        setImageWidth()

        if let mediaId = message.media?.id {
            displayImageLoading()
            loadImage(id: mediaId)
        } else {
            hideImage()
        }
    }

    private func renderImageCorners() {
        if displayTitle == .message || message.message != nil || message.hasButtons {
            imageImageView.corners = filterOutCornersIfNecessary(neededCorners: appearance?.imageCorners)
        } else {
            imageImageView.corners = appearance?.imageCorners ?? [.allCorners]
        }
    }

    private func filterOutCornersIfNecessary(neededCorners: UIRectCorner?) -> UIRectCorner {
        guard let neededCorners else {
            return [.topLeft, .topRight]
        }
        var filteredCorners: UIRectCorner = []
        if neededCorners.contains(.topLeft) || neededCorners.contains(.allCorners) {
            filteredCorners.insert(.topLeft)
        }
        if neededCorners.contains(.topRight) || neededCorners.contains(.allCorners) {
            filteredCorners.insert(.topRight)
        }
        return filteredCorners
    }

    private func setImageWidth() {
        imageMinimumWidthConstraint.constant = Self.minimumImageWidth
    }

    private func hideImage() {
        imageHolderView.isHidden = true
        imageImageView.image = nil
        imageActivityIndicatorView.stopAnimating()
    }

    @MainActor
    private func displayImageLoading() {
        imageHolderView.isHidden = false
        imageActivityIndicatorView.startAnimating()
        imageImageView.image = appearance?.imagePlaceholder
    }

    private func loadImage(id: String) {
        let imageRequestForMessageId = message.id
        Task {
            do {
                let image = try await imageLoader.load(id: id)
                // Check if the Message ID of the requested image is the same as the message of the current cell.
                // During cell reuse, the ongoing request could callback on another cell.
                // This check prevents it from applying that image (or display it's failure).
                guard imageRequestForMessageId == message.id else { return }
                display(image: image.image)
            } catch {
                displayFailedLoadingImage()
            }
        }
    }

    @MainActor
    private func display(image: UIImage) {
        imageHolderView.isHidden = false
        imageActivityIndicatorView.stopAnimating()
        imageImageView.image = image
        renderGradients()
    }

    @MainActor
    private func displayFailedLoadingImage() {
        imageActivityIndicatorView.stopAnimating()
        renderGradients()
    }

    // Gradient
    private func renderGradients() {
        // Async to render gradients on next frame, else scrolling images that are loading might not get the correct gradient applied.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            imageImageView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
            if displayName == .image {
                addImageNameGradient()
            }

            if displayMeta == .image {
                addImageMetaGradient()
            }
        }
    }

    private func addImageNameGradient() {
        let gradient = CAGradientLayer()
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 0.55)
        gradient.type = .radial
        gradient.colors = [
            appearance?.imageInnerShadowStartColor.cgColor ?? UIColor(white: 0, alpha: 0.3).cgColor,
            appearance?.imageInnerShadowEndColor.cgColor ?? UIColor.black.cgColor,
        ]
        gradient.frame = CGRect(
            x: 0, y: 0,
            width: imageNameLabel.frame.width + (appearance?.nameInsets?.left ?? 0) + 50,
            height: imageNameLabel.frame.height + (appearance?.nameInsets?.top ?? 0) + 40
        )

        imageImageView.layer.insertSublayer(gradient, at: 0)
    }

    private func addImageMetaGradient() {
        if formattedFailureMessage() != nil {
            imageImageView.layer.insertSublayer(generateImageFullWidthGradient(), at: .zero)
        } else {
            imageImageView.layer.insertSublayer(generateImageTimeGradient(), at: .zero)
        }
    }

    private func generateImageTimeGradient() -> CAGradientLayer {
        let gradient = CAGradientLayer()
        gradient.startPoint = CGPoint(x: 1, y: 1)
        gradient.endPoint = CGPoint(x: 0, y: 0.45)
        gradient.type = .radial
        gradient.colors = [
            appearance?.imageInnerShadowStartColor.cgColor ?? UIColor(white: 0, alpha: 0.3).cgColor,
            appearance?.imageInnerShadowEndColor.cgColor ?? UIColor.black.cgColor,
        ]

        let width = (imageMetaTimeLabel.bounds.width * 3) + metaRightLayoutConstraint.constant
        let height = (imageMetaTimeLabel.bounds.height * 4) + metaBottomLayoutConstraint.constant
        gradient.frame = CGRect(
            x: imageImageView.frame.width - width,
            y: imageImageView.frame.height - height,
            width: width,
            height: height
        )

        return gradient
    }

    private func generateImageFullWidthGradient() -> CAGradientLayer {
        let gradient = CAGradientLayer()
        gradient.startPoint = CGPoint(x: 0.5, y: .zero)
        gradient.endPoint = CGPoint(x: 0.5, y: 1)
        gradient.type = .axial
        gradient.colors = [
            appearance?.imageInnerShadowEndColor.cgColor ?? UIColor.black.cgColor,
            appearance?.imageInnerShadowStartColor.cgColor ?? UIColor(white: 0, alpha: 0.3).cgColor,
        ]
        let width = imageImageView.bounds.width
        let height = imageMetaTimeLabel.bounds.height + metaBottomLayoutConstraint.constant + 20
        gradient.frame = CGRect(
            x: imageImageView.frame.width - width,
            y: imageImageView.frame.height - height,
            width: width,
            height: height
        )
        return gradient
    }

    private func renderButtons() {
        for arrangedSubview in buttonsStackView.arrangedSubviews {
            buttonsStackView.removeArrangedSubview(arrangedSubview)
            arrangedSubview.removeFromSuperview()
        }

        if
            message.hasButtons,
            let messageButtons = message.buttons
        {
            buttonsView.isHidden = false
            if message.title != nil || displayName == .message || message.message != nil || message.hasMedium {
                let sep = createButtonSeparator()
                buttonsStackView.addArrangedSubview(sep)
            }
            for (tag, messageButton) in messageButtons.enumerated() {
                let button = createButton(from: messageButton, tag: tag)
                buttonsStackView.addArrangedSubview(button)
                let sep = createButtonSeparator()
                buttonsStackView.addArrangedSubview(sep)
            }
        } else {
            buttonsView.isHidden = true
        }
    }

    private func createButtonSeparator() -> UIView {
        let separator = UIView(frame: CGRect(x: 0, y: 0, width: 250, height: 1))
        separator.backgroundColor = appearance?.buttonSeperatorColor ?? UIColor(white: 0.91, alpha: 1.0)
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return separator
    }

    private func createButton(from messageButton: MessageButton, tag: Int) -> UIButton {
        let button = UIButton()
        button.tag = tag
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        button.setTitle(messageButton.title, for: .normal)
        button.setTitleColor(appearance?.buttonColor ?? UIColor.black, for: .normal)
        button.titleLabel?.font = appearance?.buttonFont
        let insets = appearance?.buttonInsets ?? .zero
        button.contentEdgeInsets = insets
        if #available(iOS 15, *) {
            var configuration = UIButton.Configuration.plain()
            configuration.contentInsets = NSDirectionalEdgeInsets(
                top: insets.top,
                leading: insets.left,
                bottom: insets.bottom,
                trailing: insets.right
            )
            button.configuration = configuration
        }
        return button
    }

    // MARK: - Appearance
    func apply(_ appearance: ParleyMessageViewAppearance) {
        self.appearance = appearance

        // Balloon
        if let backgroundTintColor = appearance.balloonTintColor {
            balloonImageView.image = appearance.balloonImage?.withRenderingMode(.alwaysTemplate)
            balloonImageView.tintColor = backgroundTintColor
        } else {
            balloonImageView.image = appearance.balloonImage?.withRenderingMode(.alwaysOriginal)
            balloonImageView.tintColor = nil
        }

        // Balloon content
        balloonContentTopLayoutConstraint.constant = appearance.balloonContentInsets?.top ?? 0
        balloonContentLeftLayoutConstraint.constant = appearance.balloonContentInsets?.left ?? 0
        balloonContentRightLayoutConstraint.constant = 0 - (appearance.balloonContentInsets?.right ?? 0)
        balloonContentBottomLayoutConstraint.constant = 0 - (appearance.balloonContentInsets?.bottom ?? 0)

        // Image
        imageTopLayoutConstraint.constant = appearance.imageInsets?.top ?? 0
        imageLeftLayoutConstraint.constant = appearance.imageInsets?.left ?? 0
        imageRightLayoutConstraint.constant = appearance.imageInsets?.right ?? 0
        imageBottomLayoutConstraint.constant = appearance.imageInsets?.bottom ?? 0

        imageImageView.cornerRadius = CGFloat(appearance.imageCornerRadius)
        imageImageView.corners = appearance.imageCorners

        imageActivityIndicatorView.color = appearance.imageLoaderTintColor

        imageNameLabel.textColor = appearance.imageInnerColor
        imageNameLabel.font = appearance.nameFont
        imageNameLabel.adjustsFontForContentSizeCategory = true

        imageNameTopLayoutConstraint
            .constant = (appearance.balloonContentTextInsets?.top ?? 0) + (appearance.nameInsets?.top ?? 0)
        imageNameRightLayoutConstraint
            .constant = (appearance.balloonContentTextInsets?.right ?? 0) + (appearance.nameInsets?.right ?? 0)
        imageNameLeftLayoutConstraint
            .constant = (appearance.balloonContentTextInsets?.left ?? 0) + (appearance.nameInsets?.left ?? 0)

        imageMetaTimeLabel.textColor = appearance.imageInnerColor
        imageMetaTimeLabel.font = appearance.timeFont

        imageMetaStatusImageView.tintColor = appearance.imageInnerColor

        imageMetaRightLayoutConstraint
            .constant = (appearance.balloonContentTextInsets?.right ?? 0) + (appearance.metaInsets?.right ?? 0)
        imageMetaLeftLayoutConstraint
            .constant = (appearance.balloonContentTextInsets?.left ?? 0) + (appearance.metaInsets?.left ?? 0)
        imageMetaBottomLayoutConstraint
            .constant = (appearance.balloonContentTextInsets?.bottom ?? 0) + (appearance.metaInsets?.bottom ?? 0)

        // Name
        nameLabel.textColor = appearance.nameColor
        nameLabel.font = appearance.nameFont

        nameTopLayoutConstraint
            .constant = (appearance.balloonContentTextInsets?.top ?? 0) + (appearance.nameInsets?.top ?? 0)
        nameLeftLayoutConstraint
            .constant = (appearance.balloonContentTextInsets?.left ?? 0) + (appearance.nameInsets?.left ?? 0)
        nameRightLayoutConstraint
            .constant = (appearance.balloonContentTextInsets?.right ?? 0) + (appearance.nameInsets?.right ?? 0)
        nameBottomLayoutConstraint.constant = appearance.nameInsets?.bottom ?? 0

        // Title
        titleLabel.textColor = appearance.titleColor
        titleLabel.font = appearance.titleFont

        titleLeftLayoutConstraint
            .constant = (appearance.balloonContentTextInsets?.left ?? 0) + (appearance.titleInsets?.left ?? 0)
        titleRightLayoutConstraint
            .constant = (appearance.balloonContentTextInsets?.right ?? 0) + (appearance.titleInsets?.right ?? 0)
        titleBottomLayoutConstraint.constant = appearance.titleInsets?.bottom ?? 0

        // Message
        messageTextView.appearance = appearance.messageTextViewAppearance

        messageTopLayoutConstraint.constant = appearance.messageInsets?.top ?? 0
        messageLeftLayoutConstraint
            .constant = (appearance.balloonContentTextInsets?.left ?? 0) + (appearance.messageInsets?.left ?? 0)
        messageBottomLayoutConstraint.constant = appearance.messageInsets?.bottom ?? 0
        messageRightLayoutConstraint
            .constant = (appearance.balloonContentTextInsets?.right ?? 0) + (appearance.messageInsets?.right ?? 0)

        // Meta
        timeLabel.textColor = appearance.timeColor
        timeLabel.font = appearance.timeFont

        statusImageView.tintColor = appearance.statusTintColor

        metaTopLayoutConstraint.constant = appearance.metaInsets?.top ?? 0
        metaLeftLayoutConstraint
            .constant = (appearance.balloonContentTextInsets?.left ?? 0) + (appearance.metaInsets?.left ?? 0)
        metaRightLayoutConstraint
            .constant = (appearance.balloonContentTextInsets?.right ?? 0) + (appearance.metaInsets?.right ?? 0)
        metaBottomLayoutConstraint
            .constant = (appearance.balloonContentTextInsets?.bottom ?? 0) + (appearance.metaInsets?.bottom ?? 0)

        // Buttons
        buttonsTopLayoutConstraint.constant = appearance.buttonsInsets?.top ?? 0
        buttonsLeftLayoutConstraint.constant = appearance.buttonsInsets?.left ?? 0
        buttonsRightLayoutConstraint.constant = appearance.buttonsInsets?.right ?? 0
        buttonsBottomLayoutConstraint.constant = appearance.buttonsInsets?.bottom ?? 0

        renderGradients()
    }

    // MARK: - Actions
    @IBAction
    func imageAction(sender: AnyObject) {
        guard let messageMediaIdentifier = message.media?.id else {
            return
        }

        delegate?.didSelectImage(messageMediaIdentifier: messageMediaIdentifier)
    }

    @objc
    private func buttonAction(sender: UIButton) {
        guard let messageButton = message.buttons?[sender.tag] else { return }
        delegate?.didSelect(messageButton)
    }
}

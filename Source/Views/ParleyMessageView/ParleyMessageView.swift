import UIKit
import Alamofire

class ParleyMessageView: UIView {
    
    enum Display {
        case hidden
        case image
        case message
    }

    // MARK: - IBOutlets
    
    @IBOutlet weak var contentView: UIView!
    
    // Balloon
    @IBOutlet weak var balloonImageView: UIImageView!

    // Balloon content
    @IBOutlet weak var balloonContentView: UIView!
    
    @IBOutlet weak var balloonContentTopLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var balloonContentLeftLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var balloonContentRightLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var balloonContentBottomLayoutConstraint: NSLayoutConstraint!
    
    // Image
    @IBOutlet weak var imageHolderView: UIView!
    
    @IBOutlet weak var imageImageView: ParleyImageView!
    
    @IBOutlet weak var imageTopLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageLeftLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageRightLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageBottomLayoutConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var imageActivityIndicatorView: UIActivityIndicatorView!
    
    @IBOutlet weak var imageNameLabel: UILabel!
    
    @IBOutlet weak var imageNameTopLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageNameLeftLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageNameRightLayoutConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var imageMetaStackView: UIStackView!
    
    @IBOutlet weak var imageMetaLeftLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageMetaRightLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageMetaBottomLayoutConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var imageMetaTimeLabel: UILabel!
    @IBOutlet weak var imageMetaStatusImageView: UIImageView!
    
    // Name
    @IBOutlet weak var nameView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var nameTopLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var nameLeftLayoutCostraint: NSLayoutConstraint!
    @IBOutlet weak var nameRightLayoutCostraint: NSLayoutConstraint!
    @IBOutlet weak var nameBottomLayoutCostraint: NSLayoutConstraint!
    
    // Title
    @IBOutlet weak var titleView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var titleTopLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLeftLayoutCostraint: NSLayoutConstraint!
    @IBOutlet weak var titleRightLayoutCostraint: NSLayoutConstraint!
    @IBOutlet weak var titleBottomLayoutCostraint: NSLayoutConstraint!
    
    // Message
    @IBOutlet weak var messageView: UIView!
    @IBOutlet weak var messageTextView: ParleyTextView!
    
    @IBOutlet weak var messageTopLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageLeftLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageRightLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageBottomLayoutConstraint: NSLayoutConstraint!
    
    // Meta
    @IBOutlet weak var metaView: UIView!
    @IBOutlet weak var metaStackView: UIStackView!
    
    @IBOutlet weak var metaTopLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var metaLeftLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var metaRightLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var metaBottomLayoutConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var statusImageView: UIImageView!
    
    // Buttons
    @IBOutlet weak var buttonsView: UIView!
    @IBOutlet weak var buttonsStackView: UIStackView!
    
    @IBOutlet weak var buttonsTopLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonsLeftLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonsRightLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonsBottomLayoutConstraint: NSLayoutConstraint!
    
    // Button time label
    @IBOutlet weak var buttonsTimeView: UIView!
    @IBOutlet weak var buttonsTimeLabel: UILabel!
    
    @IBOutlet weak var buttonTimeTopLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonTimeLeftLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonTimeRightLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonTimeBottomLayoutConstraint: NSLayoutConstraint!
    
    // Image
    private var findImageRequest: DataRequest?
    
    // Helpers
    private var displayName: Display = .message
    private var displayMeta: Display = .message
    private var displayTitle: Display = .hidden
    
    // Delegate
    internal var delegate: ParleyMessageViewDelegate?
    
    // MARK: - Appearance
    internal var appearance: ParleyMessageViewAppearance? {
        didSet {
            guard let appearance = appearance else { return }
            apply(appearance)
        }
    }
    
    private var message: Message!
    
    internal func set(message: Message, time: Date? = nil) {
        self.message = message
        render(forcedTime: time)
    }
    
    func render(forcedTime: Date?) {
        renderName()
        renderMeta(forcedTime: forcedTime)
        renderMetaStatus()
        
        renderTitle()
        renderMessage()
        
        renderImage()
        
        renderButtons()
    }
    
    // MARK: - Render
    private func renderImage() {
        if displayTitle == .message || message.message != nil {
            imageImageView.corners = [.topLeft, .topRight]
        } else {
            imageImageView.corners = [.allCorners]
        }
        
        if let image = message.image {
            imageHolderView.isHidden = false
            
            imageImageView.image = image
            
            imageActivityIndicatorView.isHidden = true
            imageActivityIndicatorView.stopAnimating()
            

            renderGradients()
        } else if let id = self.message.id, message.hasMedium {
            imageHolderView.isHidden = false
            
            findImageRequest?.cancel()
            
            imageActivityIndicatorView.isHidden = false
            imageActivityIndicatorView.startAnimating()
            
            imageImageView.image = appearance?.imagePlaceholder

            func onFindSuccess(image: UIImage) {
                imageActivityIndicatorView.isHidden = true
                imageActivityIndicatorView.stopAnimating()
                
                imageImageView.image = image
                
                renderGradients()
            }
            
            func onFindError(error: Error) {
                imageActivityIndicatorView.isHidden = true
                imageActivityIndicatorView.stopAnimating()
                
                renderGradients()
            }
            
            if let media = message.media, let mediaIdUrl = URL(string: media.id) {
                let url = mediaIdUrl.pathComponents.dropFirst().dropFirst().joined(separator: "/")
                findImageRequest = MessageRepository().find(media: url, onSuccess: onFindSuccess(image:), onFailure: onFindError(error:))
            } else {
                findImageRequest = MessageRepository().findImage(id, onSuccess: onFindSuccess(image:), onFailure: onFindError(error:))
            }
           
        } else {
            imageHolderView.isHidden = true
            
            imageImageView.image = nil
            
            imageActivityIndicatorView.isHidden = true
            imageActivityIndicatorView.stopAnimating()
        }
    }
    
    private func renderName() {
        if self.message.agent?.name == nil || !(self.appearance?.name == true) {
            self.displayName = .hidden
        } else if message.hasMedium {
            self.displayName = .image
        } else {
            displayName = .message
        }
        
        imageNameLabel.text = message.agent?.name
        nameLabel.text = message.agent?.name
        
        imageNameLabel.isHidden = displayName != .image
        nameView.isHidden = displayName != .message
    }
    
    private func renderMeta(forcedTime: Date? = nil) {
        if message.message != nil || message.title != nil || (!message.hasMedium) {
            displayMeta = .message
        } else {
            displayMeta = .image
        }
        
        imageMetaStackView.isHidden = displayMeta != .image
        metaView.isHidden = displayMeta != .message
        
        renderMetaTime(forcedTime: forcedTime)
    }
    
    private func renderMetaTime(forcedTime: Date?) {
        let time = (forcedTime ?? message.time)?.asTime() ?? ""
        
        imageMetaTimeLabel.text = time
        timeLabel.text = time
        buttonsTimeLabel.text = time
    }
    
    private func renderMetaStatus() {
        if message.type == .user {
            imageMetaStatusImageView.isHidden = false
            statusImageView.isHidden = false
            
            switch message.status {
            case .failed:
                imageMetaStatusImageView.image = UIImage(named: "ic_close", in: Bundle.current, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
                statusImageView.image = UIImage(named: "ic_close", in: Bundle.current, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
            case .pending:
                imageMetaStatusImageView.image = UIImage(named: "ic_clock", in: Bundle.current, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
                statusImageView.image = UIImage(named: "ic_clock", in: Bundle.current, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
            case .success:
                imageMetaStatusImageView.image = UIImage(named: "ic_tick", in: Bundle.current, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
                statusImageView.image = UIImage(named: "ic_tick", in: Bundle.current, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
            }
        } else {
            imageMetaStatusImageView.isHidden = true
            statusImageView.isHidden = true
        }
    }
    
    private func renderTitle() {
        if message.title == nil {
            displayTitle = .hidden
            titleView.isHidden = true
        }
        titleLabel.text = message.title
        
        if displayName == .message {
            titleTopLayoutConstraint.constant = appearance?.titleInsets?.top ?? 0
        } else {
            titleTopLayoutConstraint.constant = (appearance?.balloonContentTextInsets?.top ?? 0) + (appearance?.titleInsets?.top ?? 0)
        }
    }
    
    private func renderMessage() {
        if let message = message.getFormattedMessage() {
            switch (displayName, displayTitle) {
            case (.message, .message):
                messageTopLayoutConstraint.constant = appearance?.messageInsets?.top ?? 0
            default:
                messageTopLayoutConstraint.constant = (appearance?.balloonContentTextInsets?.top ?? 0) + (appearance?.messageInsets?.top ?? 0)
            }
            
            messageView.isHidden = false
            
            messageTextView.markdownText = message
        } else {
            messageView.isHidden = true
            
            
            messageTextView.markdownText = nil
        }
    }
    
    // Gradient
    private func renderGradients() {
        DispatchQueue.main.async { [weak self] in
            self?.imageImageView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
            if self?.displayName == .image {
                self?.addImageNameGradient()
            }
            
            if self?.displayMeta == .image {
                self?.addImageMetaGradient()
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
            appearance?.imageInnerShadowEndColor.cgColor ?? UIColor.black.cgColor
        ]
        gradient.frame = CGRect(
            x: 0, y: 0,
            width: imageNameLabel.frame.width + (appearance?.nameInsets?.left ?? 0) + 50,
            height: imageNameLabel.frame.height + (appearance?.nameInsets?.top ?? 0) + 40
        )
        
        imageImageView.layer.insertSublayer(gradient, at: 0)
    }
    
    private func addImageMetaGradient() {
        let gradient = CAGradientLayer()
        gradient.startPoint = CGPoint(x: 1, y: 1)
        gradient.endPoint = CGPoint(x: 0, y: 0.45)
        gradient.type = .radial
        gradient.colors = [
            appearance?.imageInnerShadowStartColor.cgColor ?? UIColor(white: 0, alpha: 0.3).cgColor,
            appearance?.imageInnerShadowEndColor.cgColor ?? UIColor.black.cgColor
        ]
        
        let width = imageMetaStackView.frame.width + metaRightLayoutConstraint.constant + 50
        let height = imageMetaStackView.frame.height + metaBottomLayoutConstraint.constant + 40
        gradient.frame = CGRect(
            x: imageImageView.frame.width - width,
            y: imageImageView.frame.height - height,
            width: width,
            height: height
        )
        
        imageImageView.layer.insertSublayer(gradient, at: 0)
    }
    
    private func renderButtons() {
        buttonsStackView.arrangedSubviews.forEach {
            buttonsStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        
        if let messageButtons = message.buttons, messageButtons.count > 0 {
            buttonsView.isHidden = false
            if message.message != nil || message.title != nil {
                buttonsStackView.addArrangedSubview(createButtonSeparator())
                buttonsTimeView.isHidden = true
            } else if message.message == nil && message.title == nil {
                metaView.isHidden = true
                buttonsTimeView.isHidden = false
            }
            for (tag, messageButton) in messageButtons.enumerated() {
                let button = createButton(from: messageButton, tag: tag)
                buttonsStackView.addArrangedSubview(button)
                NSLayoutConstraint.activate([
                    button.leftAnchor.constraint(equalTo: buttonsStackView.leftAnchor, constant: 10),
                    button.rightAnchor.constraint(equalTo: buttonsStackView.rightAnchor, constant: -10)
                ])
                buttonsStackView.addArrangedSubview(createButtonSeparator())
            }
        } else {
            buttonsTimeView.isHidden = true
            buttonsView.isHidden = true
        }
    }
    
    private func createButtonSeparator() -> UIView {
        let seperator = UIView(frame: CGRect(x: 0, y: 0, width: 250, height: 1))
        seperator.backgroundColor = appearance?.buttonSeperatorColor ?? UIColor(white: 0.91, alpha: 1.0)
        seperator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return seperator
    }
    
    private func createButton(from messageButton: MessageButton, tag: Int) -> UIButton {
        let button = UIButton()
        button.tag = tag
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        button.setTitle(messageButton.title, for: .normal)
        button.setTitleColor(appearance?.buttonColor ?? UIColor.black, for: .normal)
        button.titleLabel?.font = appearance?.buttonFont
        button.heightAnchor.constraint(equalToConstant: appearance?.buttonHeight ?? 40).isActive = true
        return button
    }
    
    // MARK: - Appearance
    private func apply(_ appearance: ParleyMessageViewAppearance) {
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
        imageImageView.corners = [.allCorners]
        
        imageActivityIndicatorView.color = appearance.imageLoaderTintColor
        
        imageNameLabel.textColor = appearance.imageInnerColor
        imageNameLabel.font = appearance.nameFont
        
        imageNameTopLayoutConstraint.constant = (appearance.balloonContentTextInsets?.top ?? 0) + (appearance.nameInsets?.top ?? 0)
        imageNameRightLayoutConstraint.constant = (appearance.balloonContentTextInsets?.right ?? 0) + (appearance.nameInsets?.right ?? 0)
        imageNameLeftLayoutConstraint.constant = (appearance.balloonContentTextInsets?.left ?? 0) + (appearance.nameInsets?.left ?? 0)
        
        imageMetaTimeLabel.textColor = appearance.imageInnerColor
        imageMetaTimeLabel.font = appearance.timeFont
        
        imageMetaStatusImageView.tintColor = appearance.imageInnerColor
        
        imageMetaRightLayoutConstraint.constant = (appearance.balloonContentTextInsets?.right ?? 0) + (appearance.metaInsets?.right ?? 0)
        imageMetaLeftLayoutConstraint.constant = (appearance.balloonContentTextInsets?.left ?? 0) + (appearance.metaInsets?.left ?? 0)
        imageMetaBottomLayoutConstraint.constant = (appearance.balloonContentTextInsets?.bottom ?? 0) + (appearance.metaInsets?.bottom ?? 0)
        
        // Name
        nameLabel.textColor = appearance.nameColor
        nameLabel.font = appearance.nameFont
        
        nameTopLayoutConstraint.constant = (appearance.balloonContentTextInsets?.top ?? 0) + (appearance.nameInsets?.top ?? 0)
        nameLeftLayoutCostraint.constant = (appearance.balloonContentTextInsets?.left ?? 0) + (appearance.nameInsets?.left ?? 0)
        nameRightLayoutCostraint.constant = (appearance.balloonContentTextInsets?.right ?? 0) + (appearance.nameInsets?.right ?? 0)
        nameBottomLayoutCostraint.constant = appearance.nameInsets?.bottom ?? 0
        
        // Title
        titleLabel.textColor = appearance.titleColor
        titleLabel.font = appearance.titleFont
        
        titleLeftLayoutCostraint.constant = (appearance.balloonContentTextInsets?.left ?? 0) + (appearance.titleInsets?.left ?? 0)
        titleRightLayoutCostraint.constant = (appearance.balloonContentTextInsets?.right ?? 0) + (appearance.titleInsets?.right ?? 0)
        titleBottomLayoutCostraint.constant = appearance.titleInsets?.bottom ?? 0
        
        // Message
        messageTextView.textColor = appearance.messageColor
        messageTextView.tintColor = appearance.messageTintColor
        
        messageTextView.regularFont = appearance.messageRegularFont
        messageTextView.italicFont = appearance.messageItalicFont
        messageTextView.boldFont = appearance.messageBoldFont
        
        messageTopLayoutConstraint.constant = appearance.messageInsets?.top ?? 0
        messageLeftLayoutConstraint.constant = (appearance.balloonContentTextInsets?.left ?? 0) + (appearance.messageInsets?.left ?? 0)
        messageBottomLayoutConstraint.constant = appearance.messageInsets?.bottom ?? 0
        messageRightLayoutConstraint.constant = (appearance.balloonContentTextInsets?.right ?? 0) + (appearance.messageInsets?.right ?? 0)
        
        // Meta
        timeLabel.textColor = appearance.timeColor
        timeLabel.font = appearance.timeFont
        
        statusImageView.tintColor = appearance.statusTintColor
        
        metaTopLayoutConstraint.constant = appearance.metaInsets?.top ?? 0
        metaLeftLayoutConstraint.constant = (appearance.balloonContentTextInsets?.left ?? 0) + (appearance.metaInsets?.left ?? 0)
        metaRightLayoutConstraint.constant = (appearance.balloonContentTextInsets?.right ?? 0) + (appearance.metaInsets?.right ?? 0)
        metaBottomLayoutConstraint.constant = (appearance.balloonContentTextInsets?.bottom ?? 0) + (appearance.metaInsets?.bottom ?? 0)
        
        // Buttons
        buttonsTopLayoutConstraint.constant = appearance.buttonInsets?.top ?? 0
        buttonsLeftLayoutConstraint.constant = appearance.buttonInsets?.left ?? 0
        buttonsRightLayoutConstraint.constant = appearance.buttonInsets?.right ?? 0
        buttonsBottomLayoutConstraint.constant = appearance.buttonInsets?.bottom ?? 0
        
        // Buttons's time label
        buttonsTimeLabel.textColor = appearance.timeColor
        buttonsTimeLabel.font = appearance.timeFont
        
        buttonTimeTopLayoutConstraint.constant = appearance.balloonContentTextInsets?.top ?? 0
        buttonTimeLeftLayoutConstraint.constant = (appearance.balloonContentTextInsets?.left ?? 0) + (appearance.metaInsets?.left ?? 0)
        buttonTimeRightLayoutConstraint.constant = (appearance.balloonContentTextInsets?.right ?? 0) + (appearance.metaInsets?.right ?? 0)
        buttonTimeBottomLayoutConstraint.constant = (appearance.balloonContentTextInsets?.bottom ?? 0) + (appearance.metaInsets?.bottom ?? 0)
    }
    
    // MARK: - Actions
    @IBAction func imageAction(sender: AnyObject) {
        delegate?.didSelectImage(from: message)
    }
    
    @objc private func buttonAction(sender: UIButton) {
        guard let messageButton = message.buttons?[sender.tag] else { return }
        delegate?.didSelect(messageButton)
    }
    
    // MARK: - View
    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setup()
    }
    
    private func setup() {
        loadXib()
    }
    
    private func loadXib() {
        Bundle.current.loadNibNamed("ParleyMessageView", owner: self, options: nil)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)

        NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: contentView, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: contentView, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
    }
}

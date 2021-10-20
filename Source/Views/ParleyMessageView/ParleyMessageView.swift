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
            guard let appearance = self.appearance else { return }
            
            self.apply(appearance)
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
        if self.displayTitle == .message || self.message.message != nil {
            self.imageImageView.corners = [.topLeft, .topRight]
        } else {
            self.imageImageView.corners = [.allCorners]
        }
        
        if let image = message.image {
            self.imageHolderView.isHidden = false
            
            self.imageImageView.image = image
            
            self.imageActivityIndicatorView.isHidden = true
            self.imageActivityIndicatorView.stopAnimating()
            
            self.renderGradients()
        } else if let id = self.message.id, message.imageURL != nil {
            self.imageHolderView.isHidden = false
            
            self.findImageRequest?.cancel()
            
            self.imageActivityIndicatorView.isHidden = false
            self.imageActivityIndicatorView.startAnimating()
            
            self.imageImageView.image = appearance?.imagePlaceholder
            
            func onFindSuccess(image: UIImage) {
                imageActivityIndicatorView.isHidden = true
                imageActivityIndicatorView.stopAnimating()
                
                imageImageView.image = image
                
                renderGradients()
            }
            
            
            let result: Result<UIImage, Error> = .success(UIImage())
            
            switch result {
            case .success(let image):
                print(image)
            case .failure(let error):
                print(error)
            }
            
            func onFindError(error: Error) {
                
            }
            
            switch Parley.shared.network.apiVersion {
            case .v1_6:
                guard let url = message?.imageURL?.pathComponents.dropFirst().dropFirst().joined(separator: "/") else { return }
                MessageRepository().find(media: url) { image in
                    self.imageActivityIndicatorView.isHidden = true
                    self.imageActivityIndicatorView.stopAnimating()
                    
                    self.imageImageView.image = image
                    
                    self.renderGradients()
                } onFailure: { error in
                    self.imageActivityIndicatorView.isHidden = true
                    self.imageActivityIndicatorView.stopAnimating()
                    
                    self.renderGradients()
                }
            default:
                self.findImageRequest = MessageRepository().findImage(id, onSuccess: { (image) in
                    self.imageActivityIndicatorView.isHidden = true
                    self.imageActivityIndicatorView.stopAnimating()
                    
                    self.imageImageView.image = image
                    
                    self.renderGradients()
                }) { (error) in
                    self.imageActivityIndicatorView.isHidden = true
                    self.imageActivityIndicatorView.stopAnimating()
                    
                    self.renderGradients()
                }
                
            }
        } else {
            self.imageHolderView.isHidden = true
            
            self.imageImageView.image = nil
            
            self.imageActivityIndicatorView.isHidden = true
            self.imageActivityIndicatorView.stopAnimating()
        }
    }
    
    private func renderName() {
        if self.message.agent?.name == nil || !(self.appearance?.name == true) {
            self.displayName = .hidden
        } else if self.message.image != nil || self.message.imageURL != nil {
            self.displayName = .image
        } else {
            self.displayName = .message
        }
        
        self.imageNameLabel.text = self.message.agent?.name
        self.nameLabel.text = self.message.agent?.name
        
        self.imageNameLabel.isHidden = self.displayName != .image
        self.nameView.isHidden = self.displayName != .message
    }
    
    private func renderMeta(forcedTime: Date? = nil) {
        if self.message.message != nil || self.message.title != nil || (self.message.image == nil && self.message.imageURL == nil) {
            self.displayMeta = .message
        } else {
            self.displayMeta = .image
        }
        
        self.imageMetaStackView.isHidden = self.displayMeta != .image
        self.metaView.isHidden = self.displayMeta != .message
        
        self.renderMetaTime(forcedTime: forcedTime)
    }
    
    private func renderMetaTime(forcedTime: Date?) {
        let time = (forcedTime ?? message.time)?.asTime() ?? ""
        
        imageMetaTimeLabel.text = time
        timeLabel.text = time
    }
    
    private func renderMetaStatus() {
        if self.message.type == .user {
            self.imageMetaStatusImageView.isHidden = false
            self.statusImageView.isHidden = false
            
            switch self.message.status {
            case .failed:
                self.imageMetaStatusImageView.image = UIImage(named: "ic_close", in: Bundle.current, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
                self.statusImageView.image = UIImage(named: "ic_close", in: Bundle.current, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
            case .pending:
                self.imageMetaStatusImageView.image = UIImage(named: "ic_clock", in: Bundle.current, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
                self.statusImageView.image = UIImage(named: "ic_clock", in: Bundle.current, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
            case .success:
                self.imageMetaStatusImageView.image = UIImage(named: "ic_tick", in: Bundle.current, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
                self.statusImageView.image = UIImage(named: "ic_tick", in: Bundle.current, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
            }
        } else {
            imageMetaStatusImageView.isHidden = true
            statusImageView.isHidden = true
        }
    }
    
    private func renderTitle() {
        self.displayTitle = self.message.title == nil ? .hidden : .message
        
        self.titleView.isHidden = self.message.title == nil
        
        self.titleLabel.text = self.message.title
        
        if self.displayName == .message {
            self.titleTopLayoutConstraint.constant = self.appearance?.titleInsets?.top ?? 0
        } else {
            self.titleTopLayoutConstraint.constant = (self.appearance?.balloonContentTextInsets?.top ?? 0) + (self.appearance?.titleInsets?.top ?? 0)
        }
    }
    
    private func renderMessage() {
        if let message = self.message.getFormattedMessage() {
            if self.displayName == .message || self.displayTitle == .message {
                self.messageTopLayoutConstraint.constant = self.appearance?.messageInsets?.top ?? 0
            } else {
                self.messageTopLayoutConstraint.constant = (self.appearance?.balloonContentTextInsets?.top ?? 0) + (self.appearance?.messageInsets?.top ?? 0)
            }
            
            self.messageView.isHidden = false
            
            self.messageTextView.markdownText = message
        } else {
            self.messageView.isHidden = true
            
            self.messageTextView.markdownText = nil
        }
    }
    
    // Gradient
    private func renderGradients() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.imageImageView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
            if self.displayName == .image {
                self.addImageNameGradient()
            }
            
            if self.displayMeta == .image {
                 self.addImageMetaGradient()
            }
        }
    }
    
    private func addImageNameGradient() {
        let gradient = CAGradientLayer()
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 0.55)
        gradient.type = .radial
        gradient.colors = [
            self.appearance?.imageInnerShadowStartColor.cgColor ?? UIColor(white: 0, alpha: 0.3).cgColor,
            self.appearance?.imageInnerShadowEndColor.cgColor ?? UIColor.black.cgColor
        ]
        gradient.frame = CGRect(
            x: 0, y: 0,
            width: self.imageNameLabel.frame.width + (self.appearance?.nameInsets?.left ?? 0) + 50,
            height: self.imageNameLabel.frame.height + (self.appearance?.nameInsets?.top ?? 0) + 40
        )
        
        self.imageImageView.layer.insertSublayer(gradient, at: 0)
    }
    
    private func addImageMetaGradient() {
        let gradient = CAGradientLayer()
        gradient.startPoint = CGPoint(x: 1, y: 1)
        gradient.endPoint = CGPoint(x: 0, y: 0.45)
        gradient.type = .radial
        gradient.colors = [
            self.appearance?.imageInnerShadowStartColor.cgColor ?? UIColor(white: 0, alpha: 0.3).cgColor,
            self.appearance?.imageInnerShadowEndColor.cgColor ?? UIColor.black.cgColor
        ]
        
        let width = self.imageMetaStackView.frame.width + self.metaRightLayoutConstraint.constant + 50
        let height = self.imageMetaStackView.frame.height + self.metaBottomLayoutConstraint.constant + 40
        gradient.frame = CGRect(
            x: self.imageImageView.frame.width - width,
            y: self.imageImageView.frame.height - height,
            width: width,
            height: height
        )
        
        self.imageImageView.layer.insertSublayer(gradient, at: 0)
    }
    
    private func renderButtons() {
        self.buttonsStackView.arrangedSubviews.forEach {
            self.buttonsStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        
        if let messageButtons = self.message.buttons, messageButtons.count > 0 {
            self.buttonsView.isHidden = false
            
            for (tag, messageButton) in messageButtons.enumerated() {
                let seperator = UIView(frame: CGRect(x: 0, y: 0, width: 250, height: 1))
                seperator.backgroundColor = self.appearance?.buttonSeperatorColor ?? UIColor(white:0.91, alpha:1.0)
                seperator.heightAnchor.constraint(equalToConstant: 1).isActive = true
                
                self.buttonsStackView.addArrangedSubview(seperator)
                
                let button = UIButton()
                button.tag = tag
                button.addTarget(self, action: #selector(self.buttonAction), for: .touchUpInside)
                button.setTitle(messageButton.title, for: .normal)
                button.setTitleColor(self.appearance?.buttonColor ?? UIColor.black, for: .normal)
                button.titleLabel?.font = self.appearance?.buttonFont
                button.heightAnchor.constraint(equalToConstant: self.appearance?.buttonHeight ?? 40).isActive = true
                
                self.buttonsStackView.addArrangedSubview(button)
            }
        } else {
            self.buttonsView.isHidden = true
        }
    }
    
    // MARK: - Appearance
    private func apply(_ appearance: ParleyMessageViewAppearance) {
        // Balloon
        if let backgroundTintColor = appearance.balloonTintColor {
            self.balloonImageView.image = appearance.balloonImage?.withRenderingMode(.alwaysTemplate)
            self.balloonImageView.tintColor = backgroundTintColor
        } else {
            self.balloonImageView.image = appearance.balloonImage?.withRenderingMode(.alwaysOriginal)
            self.balloonImageView.tintColor = nil
        }
        
        // Balloon content
        self.balloonContentTopLayoutConstraint.constant = appearance.balloonContentInsets?.top ?? 0
        self.balloonContentLeftLayoutConstraint.constant = appearance.balloonContentInsets?.left ?? 0
        self.balloonContentRightLayoutConstraint.constant = 0 - (appearance.balloonContentInsets?.right ?? 0)
        self.balloonContentBottomLayoutConstraint.constant = 0 - (appearance.balloonContentInsets?.bottom ?? 0)
        
        // Image
        self.imageTopLayoutConstraint.constant = appearance.imageInsets?.top ?? 0
        self.imageLeftLayoutConstraint.constant = appearance.imageInsets?.left ?? 0
        self.imageRightLayoutConstraint.constant = appearance.imageInsets?.right ?? 0
        self.imageBottomLayoutConstraint.constant = appearance.imageInsets?.bottom ?? 0
        
        self.imageImageView.cornerRadius = CGFloat(appearance.imageCornerRadius)
        self.imageImageView.corners = [.allCorners]
        
        self.imageActivityIndicatorView.color = appearance.imageLoaderTintColor
        
        self.imageNameLabel.textColor = appearance.imageInnerColor
        self.imageNameLabel.font = appearance.nameFont
        
        self.imageNameTopLayoutConstraint.constant = (appearance.balloonContentTextInsets?.top ?? 0) + (appearance.nameInsets?.top ?? 0)
        self.imageNameRightLayoutConstraint.constant = (appearance.balloonContentTextInsets?.right ?? 0) + (appearance.nameInsets?.right ?? 0)
        self.imageNameLeftLayoutConstraint.constant = (appearance.balloonContentTextInsets?.left ?? 0) + (appearance.nameInsets?.left ?? 0)
        
        self.imageMetaTimeLabel.textColor = appearance.imageInnerColor
        self.imageMetaTimeLabel.font = appearance.timeFont
        
        self.imageMetaStatusImageView.tintColor = appearance.imageInnerColor
        
        self.imageMetaRightLayoutConstraint.constant = (appearance.balloonContentTextInsets?.right ?? 0) + (appearance.metaInsets?.right ?? 0)
        self.imageMetaLeftLayoutConstraint.constant = (appearance.balloonContentTextInsets?.left ?? 0) + (appearance.metaInsets?.left ?? 0)
        self.imageMetaBottomLayoutConstraint.constant = (appearance.balloonContentTextInsets?.bottom ?? 0) + (appearance.metaInsets?.bottom ?? 0)
        
        // Name
        self.nameLabel.textColor = appearance.nameColor
        self.nameLabel.font = appearance.nameFont
        
        self.nameTopLayoutConstraint.constant = (appearance.balloonContentTextInsets?.top ?? 0) + (appearance.nameInsets?.top ?? 0)
        self.nameLeftLayoutCostraint.constant = (appearance.balloonContentTextInsets?.left ?? 0) + (appearance.nameInsets?.left ?? 0)
        self.nameRightLayoutCostraint.constant = (appearance.balloonContentTextInsets?.right ?? 0) + (appearance.nameInsets?.right ?? 0)
        self.nameBottomLayoutCostraint.constant = appearance.nameInsets?.bottom ?? 0
        
        // Title
        self.titleLabel.textColor = appearance.titleColor
        self.titleLabel.font = appearance.titleFont
        
        self.titleLeftLayoutCostraint.constant = (appearance.balloonContentTextInsets?.left ?? 0) + (appearance.titleInsets?.left ?? 0)
        self.titleRightLayoutCostraint.constant = (appearance.balloonContentTextInsets?.right ?? 0) + (appearance.titleInsets?.right ?? 0)
        self.titleBottomLayoutCostraint.constant = appearance.titleInsets?.bottom ?? 0
        
        // Message
        self.messageTextView.textColor = appearance.messageColor
        self.messageTextView.tintColor = appearance.messageTintColor
        
        self.messageTextView.regularFont = appearance.messageRegularFont
        self.messageTextView.italicFont = appearance.messageItalicFont
        self.messageTextView.boldFont = appearance.messageBoldFont
        
        self.messageTopLayoutConstraint.constant = appearance.messageInsets?.top ?? 0
        self.messageLeftLayoutConstraint.constant = (appearance.balloonContentTextInsets?.left ?? 0) + (appearance.messageInsets?.left ?? 0)
        self.messageBottomLayoutConstraint.constant = appearance.messageInsets?.bottom ?? 0
        self.messageRightLayoutConstraint.constant = (appearance.balloonContentTextInsets?.right ?? 0) + (appearance.messageInsets?.right ?? 0)
        
        // Meta
        self.timeLabel.textColor = appearance.timeColor
        self.timeLabel.font = appearance.timeFont
        
        self.statusImageView.tintColor = appearance.statusTintColor
        
        self.metaTopLayoutConstraint.constant = appearance.metaInsets?.top ?? 0
        self.metaLeftLayoutConstraint.constant = (appearance.balloonContentTextInsets?.left ?? 0) + (appearance.metaInsets?.left ?? 0)
        self.metaRightLayoutConstraint.constant = (appearance.balloonContentTextInsets?.right ?? 0) + (appearance.metaInsets?.right ?? 0)
        self.metaBottomLayoutConstraint.constant = (appearance.balloonContentTextInsets?.bottom ?? 0) + (appearance.metaInsets?.bottom ?? 0)
        
        // Buttons
        self.buttonsTopLayoutConstraint.constant = appearance.buttonInsets?.top ?? 0
        self.buttonsLeftLayoutConstraint.constant = appearance.buttonInsets?.left ?? 0
        self.buttonsRightLayoutConstraint.constant = appearance.buttonInsets?.right ?? 0
        self.buttonsBottomLayoutConstraint.constant = appearance.buttonInsets?.bottom ?? 0
    }
    
    // MARK: - Actions
    @IBAction func imageAction(sender: AnyObject) {
        self.delegate?.didSelectImage(from: self.message)
    }
    
    @objc private func buttonAction(sender: UIButton) {
        guard let messageButton = self.message.buttons?[sender.tag] else { return }
        delegate?.didSelect(messageButton)
    }
    
    // MARK: - View
    override init(frame: CGRect) {
        super.init(frame: frame)

        self.setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.setup()
    }
    
    private func setup() {
        self.loadXib()
    }
    
    private func loadXib() {
        Bundle.current.loadNibNamed("ParleyMessageView", owner: self, options: nil)

        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.contentView)

        NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: self.contentView, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: self.contentView, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: self.contentView, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: self.contentView, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
    }
}

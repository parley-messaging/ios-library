import Foundation
import UIKit

class MessageTableViewCell: UITableViewCell {
    
    @IBOutlet weak var messageView: UIView!
    @IBOutlet weak var parleyMessageView: ParleyMessageView!
    
    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            let messageCollectionViewCell = UINib(nibName: "MessageCollectionViewCell", bundle: Bundle.current)
            self.collectionView.register(messageCollectionViewCell, forCellWithReuseIdentifier: "MessageCollectionViewCell")
            
            self.collectionView.dataSource = self
        }
    }
    
    @IBOutlet weak var leftLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftAlignLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightAlignLayoutConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var collectionViewHeightLayoutConstraint: NSLayoutConstraint!
    
    weak var delegate: MessageTableViewCellDelegate? {
        didSet {
            self.parleyMessageView.delegate = self.delegate
        }
    }
    
    var appearance: MessageTableViewCellAppearance? {
        didSet {
            guard let appearance = self.appearance else { return }
            
            self.apply(appearance)
        }
    }
    
    private var messages: (messages: [Message], time: Date?)?
    
    func render(_ message: Message) {
        if message.hasMedium || message.title != nil || message.message != nil || message.buttons?.count ?? 0 > 0 {
            self.messageView.isHidden = false

            self.parleyMessageView.set(message: message)
        } else {
            self.messageView.isHidden = true
        }

        if let messages = message.carousel, messages.count > 0 {
            self.messages = (messages, message.time)
            
            collectionView.isHidden = false
            
            let maxSize = messages.map { message -> CGSize in
                MessageCollectionViewCell.calculateSize(appearance!.carousel!, message)
            }
            .sorted(by: {$0.height > $1.height})
            .first ?? .zero

            if let flowLayout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
                flowLayout.estimatedItemSize = maxSize
            }

            collectionViewHeightLayoutConstraint.constant = maxSize.height + 4
        } else {
            self.messages = nil
            
            self.collectionView.isHidden = true
        }

        self.collectionView.reloadData()
        
        setupAccessibilityFeatures(for: message)
    }
    
    private func setupAccessibilityFeatures(for message: Message) {
        isAccessibilityElement = false
        watchForVoiceOverDidChangeNotification(observer: self)
        messageView.isAccessibilityElement = true
        messageView.accessibilityLabel = Message.Accessibility.getAccessibilityLabelDescription(for: message)
        
        if #available(iOS 13, *) {
            messageView.accessibilityCustomActions = Message.Accessibility.getAccessibilityCustomActions(
                for: message,
                actionHandler: { [weak self] message, button in
                    self?.delegate?.didSelect(button)
                })
        } else {
            messageView.accessibilityCustomActions = message.getAccessibilityCustomActions(
                target: self,
                selector: #selector(messageCustomActionTriggered)
            )
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(UIAccessibility.voiceOverStatusDidChangeNotification)
    }
    
    override func voiceOverDidChange(isVoiceOverRunning: Bool) {
        // Disable drag interaction for VoiceOver.
        isUserInteractionEnabled = !isVoiceOverRunning
    }
    
    @objc private func messageCustomActionTriggered(_ messageId: Int, buttonTitle: String) {
        guard
            let message = messages?.messages.first(where: {$0.id == messageId}),
            let button = message.buttons?.first(where: {$0.title == buttonTitle })
        else { return }
        parleyMessageView.delegate?.didSelect(button)
    }
    
    private func apply(_ appearance: MessageTableViewCellAppearance) {
        self.parleyMessageView.appearance = appearance
        
        self.contentView.removeConstraints([
            self.leftLayoutConstraint,
            self.leftAlignLayoutConstraint,
            self.rightLayoutConstraint,
            self.rightAlignLayoutConstraint
        ])
        
        switch appearance.align {
        case .left:
            self.contentView.addConstraints([
                self.leftLayoutConstraint,
                self.rightAlignLayoutConstraint
            ])
        case .right:
            self.contentView.addConstraints([
                self.leftAlignLayoutConstraint,
                self.rightLayoutConstraint
            ])
        default:
            self.contentView.addConstraints([
                self.leftLayoutConstraint,
                self.rightLayoutConstraint
            ])
        }
    }
}

extension MessageTableViewCell: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        messages?.messages.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let messageCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "MessageCollectionViewCell", for: indexPath) as? MessageCollectionViewCell else { return UICollectionViewCell() }

        messageCollectionViewCell.delegate = self.delegate
        messageCollectionViewCell.appearance = self.appearance?.carousel
        if let messages = self.messages {
            messageCollectionViewCell.render(messages.messages[indexPath.row], time: messages.time)
        }
        
        return messageCollectionViewCell
    }
}

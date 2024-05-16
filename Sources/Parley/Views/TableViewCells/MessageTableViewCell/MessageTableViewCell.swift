import Foundation
import UIKit

final class MessageTableViewCell: UITableViewCell {
    
    @IBOutlet private weak var messageView: UIView!
    @IBOutlet private weak var parleyMessageView: ParleyMessageView!
    
    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            let messageCollectionViewCell = UINib(nibName: "MessageCollectionViewCell", bundle: .module)
            self.collectionView.register(messageCollectionViewCell, forCellWithReuseIdentifier: "MessageCollectionViewCell")
            
            self.collectionView.dataSource = self
        }
    }
    
    @IBOutlet private weak var leftLayoutConstraint: NSLayoutConstraint!
    @IBOutlet private weak var leftAlignLayoutConstraint: NSLayoutConstraint!
    @IBOutlet private weak var rightLayoutConstraint: NSLayoutConstraint!
    @IBOutlet private weak var rightAlignLayoutConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var collectionViewHeightLayoutConstraint: NSLayoutConstraint!
    
    private var messageWidthConstraint: NSLayoutConstraint?
    
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
        if message.hasMedium || message.title != nil || message.message != nil || message.hasButtons {
            self.messageView.isHidden = false

            self.parleyMessageView.set(message: message, forcedTime: nil)
        } else {
            self.messageView.isHidden = true
        }

        if let messages = message.carousel, !messages.isEmpty {
            self.messages = (messages, message.time)
            
            collectionView.isHidden = false
            
            let maxSize = messages.map { message -> CGSize in
                MessageCollectionViewCell.calculateSize(appearance!.carousel!, message)
            }.max(by: { $0.height > $1.height }) ?? .zero

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
        
        messageView.accessibilityCustomActions = Message.Accessibility.getAccessibilityCustomActions(
            for: message,
            actionHandler: { [weak self] message, button in
                self?.delegate?.didSelect(button)
            })
    }
    
    deinit {
        NotificationCenter.default.removeObserver(UIAccessibility.voiceOverStatusDidChangeNotification)
    }
    
    override func voiceOverDidChange(isVoiceOverRunning: Bool) {
        // Disable drag interaction for VoiceOver.
        isUserInteractionEnabled = !isVoiceOverRunning
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
        guard let messageCollectionViewCell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MessageCollectionViewCell.reuseIdentifier,
                for: indexPath
        ) as? MessageCollectionViewCell else {
            return UICollectionViewCell()
        }

        messageCollectionViewCell.delegate = self.delegate
        messageCollectionViewCell.appearance = self.appearance?.carousel

        if let messages {
            messageCollectionViewCell.render(messages.messages[indexPath.row], time: messages.time)
        }

        return messageCollectionViewCell
    }
}

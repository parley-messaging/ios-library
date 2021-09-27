import Alamofire
import UIKit

internal class MessageTableViewCell: UITableViewCell {
    
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
    
    internal weak var delegate: MessageTableViewCellDelegate? {
        didSet {
            self.parleyMessageView.delegate = self.delegate
        }
    }
    
    internal var appearance: MessageTableViewCellAppearance? {
        didSet {
            guard let appearance = self.appearance else { return }
            
            self.apply(appearance)
        }
    }
    
    private var messages: (messages: [Message], time: Date?)?
    
    internal func render(_ message: Message) {
        if message.image != nil || message.imageURL != nil || message.title != nil || message.message != nil || message.buttons?.count ?? 0 > 0 {
            self.messageView.isHidden = false

            self.parleyMessageView.set(message: message)
        } else {
            self.messageView.isHidden = true
        }

        if let messages = message.carousel, messages.count > 0 {
            self.messages = (messages, message.time)
            
            self.collectionView.isHidden = false

            let maxSize: CGSize = messages.reduce(.zero) { result, message in
                let size = MessageCollectionViewCell.calculateSize(self.appearance!.carousel!, message)
                guard size.height > .zero else { return .zero }
                return size
            }

            if let flowLayout = self.collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
                flowLayout.estimatedItemSize = maxSize
            }

            self.collectionViewHeightLayoutConstraint.constant = maxSize.height + 4
        } else {
            self.messages = nil
            
            self.collectionView.isHidden = true
        }

        self.collectionView.reloadData()
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
//        let message = messages[indexPath.row]
        messageCollectionViewCell.render(messages!.messages[indexPath.row], time: messages!.time)
        
        return messageCollectionViewCell
    }
}

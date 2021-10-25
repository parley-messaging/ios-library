import UIKit

class MessageCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var parleyMessageView: ParleyMessageView!
    
    @IBOutlet weak var widthLayoutConstraint: NSLayoutConstraint!
    
    internal var delegate: MessageTableViewCellDelegate? {
        didSet {
            self.parleyMessageView.delegate = self.delegate
        }
    }
    
    internal var appearance: MessageCollectionViewCellAppearance? {
        didSet {
            guard let appearance = self.appearance else { return }
            
            self.apply(appearance)
        }
    }
    
    internal func render(_ message: Message, time: Date?) {
        parleyMessageView.set(message: message, time: time)
    }
    
    private func apply(_ appearance: MessageCollectionViewCellAppearance) {
        self.parleyMessageView.appearance = appearance
        
        self.widthLayoutConstraint.constant = CGFloat(appearance.width)
    }
    
    internal static func calculateSize(_ appearance: MessageCollectionViewCellAppearance, _ message: Message) -> CGSize {
        var width: CGFloat = appearance.width
        width -= appearance.balloonContentInsets?.left ?? 0
        width -= appearance.balloonContentInsets?.right ?? 0
        width -= appearance.balloonContentTextInsets?.left ?? 0
        width -= appearance.balloonContentTextInsets?.right ?? 0
        width += 16
        
        var height: CGFloat = 0
        height += appearance.balloonContentInsets?.top ?? 0
        height += appearance.balloonContentInsets?.bottom ?? 0

        if message.hasMedium {
            height += 140

            height += appearance.imageInsets?.top ?? 0
            height += appearance.imageInsets?.bottom ?? 0
        } else {
            // No image
            if let name = message.agent?.name, appearance.name {
                height += appearance.nameInsets?.top ?? 0
                height += appearance.nameInsets?.bottom ?? 0

                height += name.height(withConstrainedWidth: width, font: appearance.nameFont)
            }
        }

        if let title = message.title {
            height += appearance.titleInsets?.left ?? 0
            height += appearance.titleInsets?.bottom ?? 0

            height += title.height(withConstrainedWidth: width, font: appearance.titleFont)
        }

        if let message = message.message {
            height += appearance.messageInsets?.left ?? 0
            height += appearance.messageInsets?.bottom ?? 0

            height += message.height(withConstrainedWidth: width, font: appearance.messageRegularFont)
        }

        if message.message != nil || message.title != nil || (!message.hasMedium) {
            height += appearance.metaInsets?.left ?? 0
            height += appearance.metaInsets?.bottom ?? 0

            height += (message.time?.asTime() ?? "").height(withConstrainedWidth: width, font: appearance.nameFont)
        }

        if let messageButtons = message.buttons, messageButtons.count > 0 {
            height += appearance.buttonInsets?.left ?? 0
            height += appearance.buttonInsets?.bottom ?? 0

            height += CGFloat((40 + 1) * messageButtons.count)
        }

        if message.message != nil || message.title != nil || message.hasMedium {
            height += appearance.balloonContentTextInsets?.top ?? 0
            height += appearance.balloonContentTextInsets?.bottom ?? 0
        }
        
        return CGSize(width: appearance.width, height: height)
    }
}

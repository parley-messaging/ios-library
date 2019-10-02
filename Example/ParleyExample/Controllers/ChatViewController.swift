import UIKit
import Parley

class ChatViewController: UIViewController {
    
    @IBOutlet weak var parleyView: ParleyView! {
        didSet {
            self.parleyView.appearance = ParleyViewAppearance(fontRegularName: "Montserrat-Regular", fontItalicName: "Montserrat-Italic", fontBoldName: "Montserrat-Bold")
            self.parleyView.imagesEnabled = true
            
            self.parleyView.delegate = self
        }
    }
    
    var secret: String!
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("chat_title", comment: "")
        
//        self.applyModernStyling()
    }
    
    // MARK: Actions
    @IBAction func dismiss(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    private func applyModernStyling() {
        let appearance = ParleyViewAppearance(fontRegularName: "PTSans-Regular", fontItalicName: "PTSans-Italic", fontBoldName: "PTSans-Bold")
        
        let primaryColor = UIColor(red:0.29, green:0.56, blue:0.89, alpha:1.0)

        let userInsets = UIEdgeInsets(top: 20, left: 21, bottom: 22, right: 21)
        let userBackground = UIImage(named: "ModernUserBalloon")?.resizableImage(withCapInsets: userInsets)

        appearance.messageUserBalloon.backgroundImage = userBackground
        appearance.messageUserBalloon.backgroundTintColor = primaryColor
        appearance.messageUserBalloon.messageColor = UIColor.white
        appearance.messageUserBalloon.messageTintColor = UIColor.red
        appearance.messageUserBalloon.timeColor = UIColor(white:1, alpha:0.5)
        appearance.messageUserBalloon.statusTintColor = UIColor(white:1, alpha:0.5)
        appearance.messageUserBalloon.contentInset = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)

        appearance.imageUserBalloon.backgroundImage = userBackground
        appearance.imageUserBalloon.backgroundTintColor = primaryColor
        appearance.imageUserBalloon.contentInset = UIEdgeInsets(top: 2, left: 3, bottom: 4, right: 3)
        appearance.imageUserBalloon.imageCornerRadius = 19

        let agentInsets = UIEdgeInsets(top: 20, left: 21, bottom: 22, right: 21)
        let agentBackground = UIImage(named: "ModernAgentBalloon")?.resizableImage(withCapInsets: agentInsets)

        appearance.messageAgentBalloon.backgroundImage = agentBackground
        appearance.messageAgentBalloon.backgroundTintColor = UIColor.white
        appearance.messageAgentBalloon.messageColor = UIColor.black
        appearance.messageAgentBalloon.timeColor = UIColor(white:0, alpha:0.5)
        appearance.messageAgentBalloon.contentInset = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)

        appearance.imageAgentBalloon.backgroundImage = agentBackground
        appearance.imageAgentBalloon.backgroundTintColor = UIColor.white
        appearance.imageAgentBalloon.timeColor = UIColor(white:0, alpha:0.5)
        appearance.imageAgentBalloon.contentInset = UIEdgeInsets(top: 2, left: 3, bottom: 4, right: 3)
        appearance.imageAgentBalloon.imageCornerRadius = 19

        appearance.typingBalloon.backgroundImage = agentBackground
        appearance.typingBalloon.backgroundTintColor = UIColor.white
        appearance.typingBalloon.contentInset = UIEdgeInsets(top: 11, left: 12, bottom: 17, right: 11)

        appearance.loading.loaderTintColor = primaryColor

        appearance.date.backgroundColor = primaryColor

        appearance.compose.backgroundColor = UIColor(white:0.87, alpha:1.0)
        appearance.compose.cameraTintColor = primaryColor
        appearance.compose.sendBackgroundColor = primaryColor
        
        appearance.info.textColor = UIColor(white: 0, alpha: 1.0)
        
        self.parleyView.appearance = appearance
    }
}

// MARK: ParleyViewDelegate
extension ChatViewController: ParleyViewDelegate {
    
    func didSentMessage() {
        debugPrint("ChatViewController.didSentMessage")
    }
}

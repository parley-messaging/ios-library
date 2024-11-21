import Parley
import UIKit

class ChatViewController: BaseViewController {

    @IBOutlet weak var parleyView: ParleyView! {
        didSet {
            var appearance = ParleyViewAppearance(
                fontRegularName: "Montserrat-Regular",
                fontItalicName: "Montserrat-Italic",
                fontBoldName: "Montserrat-Bold"
            )
            appearance.offlineNotification.show = true
            appearance.pushDisabledNotification.show = true
            
            appearance.typingBalloon.dots = AgentTypingTableViewCellAppearance.DotsAppearance(
                color: UIColor(named: "primaryColor")!
            )
            parleyView.appearance = appearance

            parleyView.mediaEnabled = true

            parleyView.delegate = self
        }
    }

    var secret: String!

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("chat_title", comment: "")
    }

    // MARK: Actions
    @IBAction func dismiss(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: ParleyViewDelegate
extension ChatViewController: ParleyViewDelegate {

    func didSentMessage() {
        debugPrint("ChatViewController.didSentMessage")
    }
}

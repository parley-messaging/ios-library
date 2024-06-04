import Parley
import UIKit

class ChatViewController: BaseViewController {

    @IBOutlet weak var parleyView: ParleyView! {
        didSet {
            let appearance = ParleyViewAppearance(
                fontRegularName: "Montserrat-Regular",
                fontItalicName: "Montserrat-Italic",
                fontBoldName: "Montserrat-Bold"
            )
            appearance.offlineNotification.show = true
            appearance.pushDisabledNotification.show = true
            parleyView.appearance = appearance

            parleyView.imagesEnabled = true

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
    @IBAction
    func dismiss(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: ParleyViewDelegate
extension ChatViewController: ParleyViewDelegate {

    func didSentMessage() {
        debugPrint("ChatViewController.didSentMessage")
    }
}

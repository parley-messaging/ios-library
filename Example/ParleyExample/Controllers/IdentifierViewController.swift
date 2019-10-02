import UIKit
import Parley
import Firebase

class IdentifierViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            self.titleLabel.text = NSLocalizedString("identifier_title", comment: "").uppercased()
        }
    }
    
    @IBOutlet weak var bodyLabel: UILabel! {
        didSet {
            self.bodyLabel.text = NSLocalizedString("identifier_body", comment: "")
        }
    }
    
    @IBOutlet weak var identifierBackgroundView: UIView! {
        didSet {
            self.identifierBackgroundView.layer.cornerRadius = 5
            self.identifierBackgroundView.layer.borderWidth = 1
            self.identifierBackgroundView.layer.borderColor = UIColor(named: "primaryColor")?.cgColor
        }
    }
    
    @IBOutlet weak var identifierTextView: UITextField! {
        didSet {
            self.identifierTextView.placeholder = NSLocalizedString("identifier_placeholder", comment: "")
            self.identifierTextView.text = UserDefaults.standard.string(forKey: kUserDefaultIdentificationCode) ?? kUserDefaultIdentificationCodeDefault
        }
    }
    
    @IBOutlet weak var startButton: UIButton! {
        didSet {
            self.startButton.layer.cornerRadius = 5
            
            self.startButton.setTitle(NSLocalizedString("identifier_start", comment: "").uppercased(), for: .normal)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setParleyNetworkConfiguration()
        self.setUserInformation()
        self.setOfflineMessagingEnabled()
        
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    // MARK: Parley
    private func setParleyNetworkConfiguration() {
        let headers: [String: String] = [
            "Custom-Header": "Custom header value"
        ]

        let network = ParleyNetwork(
            url: "https://api.parley.nu/",
            path: "clientApi/v1.2/",
            pin1: "mFb9BCOL58AEAe10PkhCGldOhjSY+M0l0sziLWar13c=",
            pin2: "S0mHTmqv2QhJEfy5vyPVERSnyMEliJzdC8RXduOjhAs=",
            headers: headers
        )

        Parley.setNetwork(network)
    }
    
    private func setUserInformation() {
        let authorization = "ZGFhbnw5ZTA5ZjQ2NWMyMGNjYThiYjMxNzZiYjBhOTZmZDNhNWY0YzVlZjYzMGVhNGZmMWUwMjFjZmE0NTEyYjlmMDQwYTJkMTJmNTQwYTE1YmUwYWU2YTZjNTc4NjNjN2IxMmRjODNhNmU1ODNhODhkMmQwNzY2MGYxZTEzZDVhNDk1Mnw1ZDcwZjM5ZTFlZWE5MTM2YmM3MmIwMzk4ZDcyZjEwNDJkNzUwOTBmZmJjNDM3OTg5ZWU1MzE5MzdlZDlkYmFmNTU1YTcyNTUyZWEyNjllYmI5Yzg5ZDgyZGQ3MDYwYTRjZGYxMzE3NWJkNTUwOGRhZDRmMDA1MTEzNjlkYjkxNQ"

        let additionalInformation = [
            kParleyAdditionalValueName: "John Doe",
            kParleyAdditionalValueEmail: "j.doe@parley.nu",
            kParleyAdditionalValueAddress: "Randstad 21 30, 1314, Nederland"
        ]

        Parley.setUserInformation(authorization, additionalInformation: additionalInformation)
    }
    
    private func setOfflineMessagingEnabled() {
        if let key = "1234567890123456".data(using: .utf8), let dataSource = try? ParleyEncryptedDataSource(key: key) {
            Parley.enableOfflineMessaging(dataSource)
        }
    }
    
    // MARK: Actions
    @IBAction func hideKeyboard(_ sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    @IBAction func startChat(_ sender: Any) {
        if let secret = self.identifierTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines), !secret.isEmpty, secret.count == 20 {
            self.startButton.setLoading(true)
            
            Parley.configure(secret, onSuccess: {
                self.startButton.setLoading(false)
                
                UserDefaults.standard.set(secret, forKey: kUserDefaultIdentificationCode)
                
                self.performSegue(withIdentifier: "showTabBarViewController", sender: nil)
            }) { _, _ in
                self.startButton.setLoading(false)
                
                self.performSegue(withIdentifier: "showTabBarViewController", sender: nil)
            }
        } else {
            let alertController = UIAlertController(
                title: NSLocalizedString("identifier_error_title", comment: ""),
                message: NSLocalizedString("identifier_error_body", comment: ""),
                preferredStyle: .alert
            )
            alertController.addAction(UIAlertAction(
                title: NSLocalizedString("general_ok", comment: ""),
                style: .cancel,
                handler: nil
            ))
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
}

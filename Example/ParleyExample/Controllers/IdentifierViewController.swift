import Firebase
import Parley
import ParleyNetwork
import UIKit

class IdentifierViewController: UIViewController {

    /// Disable offline messaging in the demo app to show error messages as an alert before opening the chat
    private static let kOfflineMessagingEnabled = true

    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.text = NSLocalizedString("identifier_title", comment: "").uppercased()
        }
    }

    @IBOutlet weak var bodyLabel: UILabel! {
        didSet {
            bodyLabel.text = NSLocalizedString("identifier_body", comment: "")
        }
    }

    @IBOutlet weak var identifierBackgroundView: UIView! {
        didSet {
            identifierBackgroundView.layer.cornerRadius = 5
            identifierBackgroundView.layer.borderWidth = 1
            identifierBackgroundView.layer.borderColor = UIColor(named: "primaryColor")?.cgColor
        }
    }

    @IBOutlet weak var identifierTextView: UITextField! {
        didSet {
            identifierTextView.placeholder = NSLocalizedString("identifier_placeholder", comment: "")
            identifierTextView.text = UserDefaults.standard
                .string(forKey: kUserDefaultIdentificationCode) ?? kUserDefaultIdentificationCodeDefault
        }
    }

    @IBOutlet weak var customerIdentificationBackgroundView: UIView! {
        didSet {
            customerIdentificationBackgroundView.layer.cornerRadius = 5
            customerIdentificationBackgroundView.layer.borderWidth = 1
            customerIdentificationBackgroundView.layer.borderColor = UIColor(named: "primaryColor")?.cgColor
        }
    }

    @IBOutlet weak var customerIdentificationTextView: UITextField! {
        didSet {
            customerIdentificationTextView.placeholder = NSLocalizedString(
                "identifier_customer_identification_placeholder",
                comment: ""
            )
            customerIdentificationTextView.text = UserDefaults.standard
                .string(forKey: kUserDefaultIdentifierCustomerIdentification)
        }
    }

    @IBOutlet weak var startButton: UIButton! {
        didSet {
            startButton.layer.cornerRadius = 5

            startButton.setTitle(NSLocalizedString("identifier_start", comment: "").uppercased(), for: .normal)
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    /// > Note: Parley expects that `Parley.configure()` is only called once. Resetting is only needed when the `secret`
    /// can change, which is the case for this demo app. Single app implementations don't need to reset Parley before
    /// configuring.
    private var alreadyConfiguredParley = false

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        if Self.kOfflineMessagingEnabled {
            setOfflineMessagingEnabled()
        }

        setNeedsStatusBarAppearanceUpdate()
    }

    // MARK: UI

    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(
            title: NSLocalizedString("general_ok", comment: ""),
            style: .cancel,
            handler: nil
        ))

        present(alertController, animated: true, completion: nil)
    }

    // MARK: Parley
    private func createNetworkConfig() -> ParleyNetworkConfig {
        let headers = [
            "Custom-Header": "Custom header value",
        ]

        return ParleyNetworkConfig(
            url: "https://api.parley.nu/",
            path: "clientApi/v1.7",
            apiVersion: .v1_7,
            headers: headers
        )
    }

    private func setUserInformation() {
        let authorization =
            "ZGFhbnw5ZTA5ZjQ2NWMyMGNjYThiYjMxNzZiYjBhOTZmZDNhNWY0YzVlZjYzMGVhNGZmMWUwMjFjZmE0NTEyYjlmMDQwYTJkMTJmNTQwYTE1YmUwYWU2YTZjNTc4NjNjN2IxMmRjODNhNmU1ODNhODhkMmQwNzY2MGYxZTEzZDVhNDk1Mnw1ZDcwZjM5ZTFlZWE5MTM2YmM3MmIwMzk4ZDcyZjEwNDJkNzUwOTBmZmJjNDM3OTg5ZWU1MzE5MzdlZDlkYmFmNTU1YTcyNTUyZWEyNjllYmI5Yzg5ZDgyZGQ3MDYwYTRjZGYxMzE3NWJkNTUwOGRhZDRmMDA1MTEzNjlkYjkxNQ"

        let additionalInformation = [
            kParleyAdditionalValueName: "John Doe",
            kParleyAdditionalValueEmail: "j.doe@parley.nu",
            kParleyAdditionalValueAddress: "Randstad 21 30, 1314, Nederland",
        ]

        Parley.setUserInformation(authorization, additionalInformation: additionalInformation)
    }

    private func setOfflineMessagingEnabled() {
        do {
            let key = "1234567890123456"
            let crypter = try ParleyCrypter(key: key, size: .bits128)
            let parleyMessageDataSource = try ParleyEncryptedMessageDataSource(
                crypter: crypter,
                directory: .default,
                fileManager: .default
            )
            let parleyKeyValueDataSource = try ParleyEncryptedKeyValueDataSource(
                crypter: crypter,
                directory: .default,
                fileManager: .default
            )
            let imageDataSource = try ParleyEncryptedImageDataSource(
                crypter: crypter,
                directory: .default,
                fileManager: .default
            )

            Parley.enableOfflineMessaging(
                messageDataSource: parleyMessageDataSource,
                keyValueDataSource: parleyKeyValueDataSource,
                imageDataSource: imageDataSource
            )
        } catch {
            print(error)
        }
    }

    // MARK: Actions
    @IBAction
    func hideKeyboard(_ sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }

    @IBAction
    func startChatClicked(_ sender: Any) {
        if alreadyConfiguredParley {
            // Only in the demo we'll need to reset Parley when we've already configured it once
            Parley.reset(onSuccess: { [weak self] in
                self?.startChatDemo()
            }, onFailure: { _, _ in
                print("Failed to reset Parley")
            })
        } else {
            startChatDemo()
        }
    }

    // Start a chat based on the input
    private func startChatDemo() {
        if
            let customerIdentification = customerIdentificationTextView.text?
                .trimmingCharacters(in: .whitespacesAndNewlines),
            !customerIdentification.isEmpty
        {
            startChat(customerIdentification: customerIdentification)
        } else if
            let secret = identifierTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            !secret.isEmpty,
            secret.count == 20
        {
            startChat(secret: secret)
        } else {
            showAlert(
                title: NSLocalizedString("identifier_error_invalid_title", comment: ""),
                message: NSLocalizedString("identifier_error_invalid_body", comment: "")
            )
        }
    }

    // Start chat with user authorization
    private func startChat(customerIdentification: String) {
        startButton.setLoading(true)

        let authorization = ParleyCustomerAuthorization.generate(
            identification: customerIdentification,
            secret: kParleyUserAuthorizationSecret,
            sharedSecret: kParleyUserAuthorizationSharedSecret
        )
        Parley.setUserInformation(authorization)

        Parley.configure(
            kParleySecret,
            networkConfig: createNetworkConfig(),
            onSuccess: { [weak self] in
                guard let self else { return }
                alreadyConfiguredParley = true
                startButton.setLoading(false)

                identifierTextView.text = kParleySecret

                UserDefaults.standard.removeObject(forKey: kUserDefaultIdentificationCode)
                UserDefaults.standard.set(customerIdentification, forKey: kUserDefaultIdentifierCustomerIdentification)

                performSegue(withIdentifier: "showTabBarViewController", sender: nil)
            }
        ) { [weak self] code, message in
            self?.startButton.setLoading(false)
            if Self.kOfflineMessagingEnabled {
                self?.performSegue(withIdentifier: "showTabBarViewController", sender: nil)
            } else {
                self?.showAlert(
                    title: NSLocalizedString("identifier_error_start_title", comment: ""),
                    message: String(
                        format: NSLocalizedString("identifier_error_start_body", comment: ""),
                        message,
                        "\(code)"
                    )
                )
            }
        }
    }

    // Start anonymous chat
    private func startChat(secret: String) {
        startButton.setLoading(true)

        if UserDefaults.standard.string(forKey: kUserDefaultIdentifierCustomerIdentification) != nil {
            Parley.clearUserInformation()
        }

        Parley.configure(
            secret,
            networkConfig: createNetworkConfig(),
            onSuccess: { [weak self] in
                self?.alreadyConfiguredParley = true
                self?.startButton.setLoading(false)

                UserDefaults.standard.set(secret, forKey: kUserDefaultIdentificationCode)
                UserDefaults.standard.removeObject(forKey: kUserDefaultIdentifierCustomerIdentification)

                self?.performSegue(withIdentifier: "showTabBarViewController", sender: nil)
            }
        ) { [weak self] code, message in
            self?.startButton.setLoading(false)
            if Self.kOfflineMessagingEnabled {
                self?.performSegue(withIdentifier: "showTabBarViewController", sender: nil)
            } else {
                self?.showAlert(
                    title: NSLocalizedString("identifier_error_start_title", comment: ""),
                    message: String(
                        format: NSLocalizedString("identifier_error_start_body", comment: ""),
                        message,
                        "\(code)"
                    )
                )
            }
        }
    }
}

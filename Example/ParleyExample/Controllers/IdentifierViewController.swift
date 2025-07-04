import Firebase
import Parley
import ParleyNetwork
import UIKit

final class IdentifierViewController: UIViewController {
    
    private let hapticFeedbackService = HapticFeedbackService()
    
    /// > Note: Parley expects that `Parley.configure()` is only called once. Resetting is only needed when the `secret`
    /// can change, which is the case for this demo app. Single app implementations don't need to reset Parley before
    /// configuring.
    private var alreadyConfiguredParley = false
    
    // MARK: IBOutlets
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    
    @IBOutlet weak var identifierBackgroundView: UIView!
    @IBOutlet weak var identifierTextView: UITextField!
    
    @IBOutlet weak var customerIdentificationBackgroundView: UIView!
    @IBOutlet weak var customerIdentificationTextView: UITextField!
    
    @IBOutlet weak var actionsStackView: UIStackView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var lightweightSetupButton: UIButton!
    @IBOutlet weak var lightweightOpenButton: UIButton!
    @IBOutlet weak var lightweightRegisterDeviceButton: UIButton!
    @IBOutlet weak var lightweightGetUnseenButton: UIButton!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    private var secretInput: String? {
        let input = identifierTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let input, input.isEmpty == false {
            return input
        } else {
            return nil
        }
    }
    
    private var customerIdentificationInput: String? {
        let input = customerIdentificationTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let input, input.isEmpty == false {
            return input
        } else {
            return nil
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setup()
    }

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        if Settings.offlineMessagingEnabled {
            setOfflineMessagingEnabled()
        }
        
        Task {
            let id = UserDefaults.standard.string(forKey: kUserDefaultIdentifierCustomerIdentification)
            try? await Parley.registerDevice()
            await Parley.setup(secret: kParleyUserAuthorizationSecret, uniqueDeviceIdentifier: id)
        }
    }

    // MARK: UI
    @MainActor
    private func showAlert(title: String, message: String? = nil) {
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(
            title: NSLocalizedString("general_ok"),
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
                directory: .default
            )
            let parleyKeyValueDataSource = try ParleyEncryptedKeyValueDataSource(
                crypter: crypter,
                directory: .default,
                fileManager: .default
            )
            let mediaDataSource = try ParleyEncryptedMediaDataSource(
                crypter: crypter,
                directory: .default,
                fileManager: .default
            )

            Parley.enableOfflineMessaging(
                messageDataSource: parleyMessageDataSource,
                keyValueDataSource: parleyKeyValueDataSource,
                mediaDataSource: mediaDataSource
            )
        } catch {
            print(String(reflecting: error))
        }
    }

    // MARK: - Actions
    @IBAction
    func hideKeyboard(_ sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }

    @IBAction
    func startChatClicked(_ sender: Any) {
        startButton.setLoading(true)
        Task {
            if alreadyConfiguredParley {
                // Only in the demo we'll need to reset Parley when we've already configured it once
                do {
                    try await Parley.reset()
                    await startChatDemo()
                } catch {
                    print("Failed to reset Parley: \(String(reflecting: error))")
                    startButton.setLoading(false)
                }
            } else {
                await startChatDemo()
            }
        }
    }
    
    @IBAction
    func lightweightSetupClicked(_ sender: Any) {
        lightweightSetupButton.setLoading(true)
        guard let secret = secretInput else {
            hapticFeedbackService.notification(type: .error)
            lightweightSetupButton.setLoading(false)
            return showAlert(title: NSLocalizedString("identifier_lightweight_setup_alert_set_secret_title"))
        }
        let feedbackGenerator = hapticFeedbackService.prepareNotification()
        Task {
            await Parley.setup(secret: secret)
            feedbackGenerator.notificationOccurred(.success)
            showAlert(
                title: NSLocalizedString("identifier_lightweight_setup_alert_setup_complete_title"),
                message: NSLocalizedString("identifier_lightweight_setup_alert_setup_complete_body")
            )
            lightweightSetupButton.setLoading(false)
        }
    }
    
    @IBAction
    func lightweightOpenClicked(_ sender: Any) {
        lightweightOpenButton.setLoading(true)
        let feedbackGenerator = hapticFeedbackService.prepareNotification()
        Task {
            if alreadyConfiguredParley {
                // Only in the demo we'll need to reset Parley when we've already configured it once
                do {
                    try await Parley.reset()
                    await startChatDemo()
                } catch {
                    print("Failed to reset Parley")
                    feedbackGenerator.notificationOccurred(.error)
                }
                lightweightOpenButton.setLoading(false)
            } else {
                await startChatDemo()
            }
        }
    }
    
    @IBAction
    func lightweightRegisterDeviceClicked(_ sender: Any) {
        lightweightRegisterDeviceButton.setLoading(true)
        let feedbackGenerator = hapticFeedbackService.prepareNotification()
        Task {
            do {
                try await Parley.registerDevice()
                feedbackGenerator.notificationOccurred(.success)
                showAlert(
                    title: NSLocalizedString("identifier_lightweight_message_device_registered_title"),
                    message: NSLocalizedString("identifier_lightweight_message_device_registered_body")
                )
            } catch {
                print("Failed to register device: \(String(reflecting: error))")
                feedbackGenerator.notificationOccurred(.error)
                showAlert(
                    title: NSLocalizedString("identifier_lightweight_message_device_registration_failed_title"),
                    message: String(reflecting: error)
                )
            }
            lightweightRegisterDeviceButton.setLoading(false)
        }
    }
    
    @IBAction
    func lightweightGetUnseenCountClicked(_ sender: Any) {
        lightweightGetUnseenButton.setLoading(true)
        let feedbackGenerator = hapticFeedbackService.prepareNotification()
        Task {
            do {
                let unseenMessages = try await Parley.getUnseenCount()
                showAlert(title: String(
                    format: NSLocalizedString("identifier_lightweight_message_x_unseen_messages"),
                    unseenMessages,
                ))
                feedbackGenerator.notificationOccurred(.success)
            } catch {
                print("Failed to register device: \(String(reflecting: error))")
                feedbackGenerator.notificationOccurred(.error)
                showAlert(
                    title: NSLocalizedString("identifier_lightweight_unseen_failed_title"),
                    message: NSLocalizedString("identifier_lightweight_unseen_failed_body")
                )
            }
            lightweightGetUnseenButton.setLoading(false)
        }
    }

    // Start a chat based on the input
    private func startChatDemo() async {
        if let customerIdentificationInput {
            await startChat(customerIdentification: customerIdentificationInput)
        } else if let secret = secretInput, secret.count == 20 {
            await startChat(secret: secret)
        } else {
            showAlert(
                title: NSLocalizedString("identifier_error_invalid_title"),
                message: NSLocalizedString("identifier_error_invalid_body")
            )
        }
    }

    // Start chat with user authorization
    private func startChat(customerIdentification: String) async {
        if Settings.flow.openChatDirectly == true {
            displayChat()
        }
        
        let authorization = ParleyCustomerAuthorization.generate(
            identification: customerIdentification,
            secret: kParleyUserAuthorizationSecret,
            sharedSecret: kParleyUserAuthorizationSharedSecret
        )
        try? await Parley.setUserInformation(authorization)
        do {
            try await Parley.configure(kParleySecret, networkConfig: createNetworkConfig())
            alreadyConfiguredParley = true
            startButton.setLoading(false)
            lightweightOpenButton.setLoading(false)

            identifierTextView.text = kParleySecret

            UserDefaults.standard.removeObject(forKey: kUserDefaultIdentificationCode)
            UserDefaults.standard.set(customerIdentification, forKey: kUserDefaultIdentifierCustomerIdentification)
            if Settings.flow.openChatDirectly != true {
                displayChat()
            }
        } catch (let configurationError) {
            startButton.setLoading(false)
            lightweightOpenButton.setLoading(false)
            if Settings.offlineMessagingEnabled {
                if Settings.flow.openChatDirectly != true {
                    displayChat()
                }
            } else {
                showAlert(
                    title: NSLocalizedString("identifier_error_start_title"),
                    message: String(
                        format: NSLocalizedString("identifier_error_start_body"),
                        configurationError.message,
                        "\(configurationError.code)"
                    )
                )
            }
        }
    }

    // Start anonymous chat
    @MainActor
    private func startChat(secret: String) async {
        if Settings.flow.openChatDirectly == true {
            displayChat()
        }
        
        if UserDefaults.standard.string(forKey: kUserDefaultIdentifierCustomerIdentification) != nil {
            try? await Parley.clearUserInformation()
        }

        do {
            try await Parley.configure(secret, networkConfig: createNetworkConfig())
            alreadyConfiguredParley = true
            startButton.setLoading(false)
            lightweightOpenButton.setLoading(false)

            UserDefaults.standard.set(secret, forKey: kUserDefaultIdentificationCode)
            UserDefaults.standard.removeObject(forKey: kUserDefaultIdentifierCustomerIdentification)
            
            if Settings.flow.openChatDirectly != true {
                displayChat()
            }
        } catch (let configurationError) {
            startButton.setLoading(false)
            lightweightOpenButton.setLoading(false)
            if Settings.offlineMessagingEnabled {
                if Settings.flow.openChatDirectly != true {
                    displayChat()
                }
            } else {
                showAlert(
                    title: NSLocalizedString("identifier_error_start_title"),
                    message: String(
                        format: NSLocalizedString("identifier_error_start_body"),
                        configurationError.message,
                        "\(configurationError.code)"
                    )
                )
            }
        }
    }
    
    private func displayChat() {
        performSegue(withIdentifier: "showTabBarViewController", sender: nil)
    }
}

// MARK: View setup
private extension IdentifierViewController {

    func setup() {
        setNeedsStatusBarAppearanceUpdate()
        setupScrollView()
        setupTitleLabel()
        setupBodyLabel()
        setupIdentifierInput()
        setupCustomIdentificationInput()
        setupButtons()
    }
    
    func setupScrollView() {
        scrollView.contentInsetAdjustmentBehavior = .never
    }
    
    func setupTitleLabel() {
        titleLabel.text = NSLocalizedString("identifier_title").uppercased()
    }
    
    func setupBodyLabel() {
        bodyLabel.text = NSLocalizedString("identifier_body")
    }
    
    func setupIdentifierInput() {
        identifierBackgroundView.layer.cornerRadius = 5
        identifierBackgroundView.layer.borderWidth = 1
        identifierBackgroundView.layer.borderColor = UIColor.primary.cgColor
        
        identifierTextView.placeholder = NSLocalizedString("identifier_placeholder")
        identifierTextView.text = UserDefaults.standard
            .string(forKey: kUserDefaultIdentificationCode) ?? kUserDefaultIdentificationCodeDefault
    }
    
    func setupCustomIdentificationInput() {
        customerIdentificationBackgroundView.layer.cornerRadius = 5
        customerIdentificationBackgroundView.layer.borderWidth = 1
        customerIdentificationBackgroundView.layer.borderColor = UIColor.primary.cgColor
        
        customerIdentificationTextView.text = UserDefaults.standard.string(forKey: kUserDefaultIdentifierCustomerIdentification)
        customerIdentificationTextView.placeholder = NSLocalizedString(
            "identifier_customer_identification_placeholder"
        )
    }
    
    func setupButtons() {
        let allButtons = actionsStackView.subviews.compactMap { $0 as? UIButton }
        allButtons.forEach { $0.isHidden = true }
        
        switch Settings.flow {
        case .default:
            setupStartButton()
        case .specialLightweight:
            setupLightweightSetupButton()
            setupLightweightOpenButton()
            setupLightweightRegisterDeviceButton()
            setupLightweightGetUnseenButton()
        }
        
        for button in allButtons where !button.isHidden {
            button.layer.cornerRadius = 5
        }
    }
    
    func setupStartButton() {
        startButton.isHidden = false
        if case let .default(openChatDirectly) = Settings.flow {
            let title = if openChatDirectly {
                NSLocalizedString("identifier_open_then_start").uppercased()
            } else {
                NSLocalizedString("identifier_start_then_open").uppercased()
            }
            startButton.setTitle(title.uppercased(), for: .normal)
        }
    }
    
    func setupLightweightSetupButton() {
        lightweightSetupButton.isHidden = false
        lightweightSetupButton.setTitle(
            NSLocalizedString("identifier_lightweight_setup").uppercased(),
            for: .normal
        )
    }
    
    func setupLightweightOpenButton() {
        lightweightOpenButton.isHidden = false
        lightweightOpenButton.setTitle(
            NSLocalizedString("identifier_lightweight_open").uppercased(),
            for: .normal
        )
    }
    
    func setupLightweightRegisterDeviceButton() {
        lightweightRegisterDeviceButton.isHidden = false
        lightweightRegisterDeviceButton.setTitle(
            NSLocalizedString("identifier_lightweight_register_device").uppercased(),
            for: .normal
        )
    }
    
    func setupLightweightGetUnseenButton() {
        lightweightGetUnseenButton.isHidden = false
        lightweightGetUnseenButton.setTitle(
            NSLocalizedString("identifier_lightweight_get_unseen").uppercased(),
            for: .normal
        )
    }
}

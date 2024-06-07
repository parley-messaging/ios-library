import Photos
import PhotosUI
import UIKit

public class ParleyComposeView: UIView {

    @IBOutlet var contentView: UIView! {
        didSet {
            contentView.backgroundColor = UIColor.clear
        }
    }

    @IBOutlet weak var cameraButton: UIButton! {
        didSet {
            cameraButton.accessibilityLabel = ParleyLocalizationKey.voiceOverCameraButtonLabel.localized
        }
    }

    @IBOutlet weak var textViewBackgroundView: UIView! {
        didSet {
            textViewBackgroundView.layer.cornerRadius = 18
            textViewBackgroundView.layer.borderWidth = 1
        }
    }

    @IBOutlet weak var textView: UITextView! {
        didSet {
            textView.textContainerInset = .zero
            textView.textContainer.lineFragmentPadding = 0
            textView.autocorrectionType = .default

            textView.delegate = self

            let keyboardAccessoryView = KeyboardAccessoryView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            keyboardAccessoryView.delegate = self

            textView.inputAccessoryView = keyboardAccessoryView

            textView.accessibilityCustomActions = [
                UIAccessibilityCustomAction(
                    name: ParleyLocalizationKey.voiceOverDismissKeyboardAction.localized,
                    target: self,
                    selector: #selector(dismissKeyboard)
                ),
            ]

            textView.adjustsFontForContentSizeCategory = true
        }
    }

    @objc
    private func dismissKeyboard() {
        textView.resignFirstResponder()
    }

    @IBOutlet private weak var placeholderTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var placeholderLabel: UILabel! {
        didSet {
            placeholderLabel.isAccessibilityElement = false
            placeholderLabel.adjustsFontForContentSizeCategory = true
            placeholderLabel.numberOfLines = 2
        }
    }

    private var sendButtonEnabledObservation: NSKeyValueObservation?
    @IBOutlet weak var sendButton: UIButton! {
        didSet {
            sendButton.layer.cornerRadius = sendButton.bounds.height / 2
            sendButton.accessibilityLabel = ParleyLocalizationKey.voiceOverSendButtonLabel.localized

            sendButtonEnabledObservation = observe(\.sendButton?.isEnabled, options: [.new]) { [weak self] _, change in
                let isEnabled = change.newValue

                if isEnabled == true {
                    self?.sendButton.accessibilityHint = nil
                } else {
                    self?.sendButton.accessibilityHint = ParleyLocalizationKey.voiceOverSendButtonDisabledHint.localized
                }
            }
        }
    }

    @IBOutlet weak var textViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var textViewBackgroundViewTrailingConstraint: NSLayoutConstraint!

    private var bottomLayoutConstraint: NSLayoutConstraint!

    var appearance = ParleyComposeViewAppearance() {
        didSet {
            apply(appearance)
        }
    }

    weak var delegate: ParleyComposeViewDelegate?

    var placeholder: String? {
        didSet {
            placeholderLabel.text = placeholder
            textView.accessibilityLabel = placeholder
            setPlaceHolderHeight()
        }
    }

    var isEnabled = true {
        didSet {
            cameraButton.isEnabled = isEnabled
            textView.isEditable = isEnabled
            sendButton.isEnabled = isEnabled && !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    var maxCount = 2000

    var allowPhotos = true {
        didSet {
            cameraButton.isHidden = !allowPhotos
            textViewBackgroundViewTrailingConstraint.constant = allowPhotos ? 56 : 16
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setup()
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIContentSizeCategory.didChangeNotification, object: nil)
    }

    private func setup() {
        loadXib()
        apply(appearance)
        watchForContentSizeCategoryChanges()
    }

    private func loadXib() {
        Bundle.module.loadNibNamed("ParleyComposeView", owner: self, options: nil)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)

        bottomLayoutConstraint = NSLayoutConstraint(
            item: self,
            attribute: .bottom,
            relatedBy: .equal,
            toItem: contentView,
            attribute: .bottom,
            multiplier: 1.0,
            constant: 0
        )
        NSLayoutConstraint.activate([
            NSLayoutConstraint(
                item: self,
                attribute: .leading,
                relatedBy: .equal,
                toItem: contentView,
                attribute: .leading,
                multiplier: 1.0,
                constant: 0
            ),
            NSLayoutConstraint(
                item: self,
                attribute: .trailing,
                relatedBy: .equal,
                toItem: contentView,
                attribute: .trailing,
                multiplier: 1.0,
                constant: 0
            ),
            NSLayoutConstraint(
                item: self,
                attribute: .top,
                relatedBy: .equal,
                toItem: contentView,
                attribute: .top,
                multiplier: 1.0,
                constant: 0
            ),
            bottomLayoutConstraint,
        ])
    }

    private func apply(_ appearance: ParleyComposeViewAppearance) {
        backgroundColor = appearance.backgroundColor

        textViewBackgroundView.backgroundColor = appearance.inputBackgroundColor
        textViewBackgroundView.layer.borderColor = appearance.inputBorderColor.cgColor

        sendButton.backgroundColor = appearance.sendBackgroundColor
        if let iconTintColor = appearance.sendTintColor {
            let sendIcon = appearance.sendIcon.withRenderingMode(.alwaysTemplate)
            sendIcon.isAccessibilityElement = false
            sendIcon.accessibilityLabel = nil

            sendButton.setImage(sendIcon, for: .normal)

            sendButton.tintColor = iconTintColor
        } else {
            sendButton.setImage(appearance.sendIcon, for: .normal)
        }

        let cameraIcon = appearance.cameraIcon.withRenderingMode(.alwaysTemplate)
        cameraIcon.isAccessibilityElement = false
        cameraIcon.accessibilityLabel = nil
        cameraButton.setImage(cameraIcon, for: .normal)
        cameraButton.tintColor = appearance.cameraTintColor

        placeholderLabel.textColor = appearance.placeholderColor
        placeholderLabel.font = appearance.font

        textView.textColor = appearance.textColor
        textView.tintColor = appearance.tintColor
        textView.font = appearance.font
    }

    private func watchForContentSizeCategoryChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleContentSizeCategoryDidChange),
            name: UIContentSizeCategory.didChangeNotification,
            object: nil
        )
    }

    @objc
    private func handleContentSizeCategoryDidChange() {
        setPlaceHolderHeight()
    }

    func setPlaceHolderHeight() {
        // Needs extra time to render label in new font size.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            placeholderLabel.sizeToFit()

            if textView.text?.isEmpty == true {
                textViewHeightConstraint.constant = max(23, placeholderLabel.bounds.height)
            }

            let messageLineHeight = textView.font?.lineHeight ?? .zero
            let placeholderLineHeight = placeholderLabel.font?.lineHeight ?? .zero

            placeholderTopConstraint.constant = messageLineHeight - placeholderLineHeight

            layoutIfNeeded()
        }
    }

    @IBAction
    private func send(_ sender: UIButton) {
        if let message = textView.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
            delegate?.send(message)
        }

        textView.text = ""
        textViewDidChange(textView)
    }

    // MARK: Image picker
    @IBAction
    private func presentImageActionSheet(_ sender: UIButton) {
        guard isCameraAvailable() else { selectPhoto() ; return }

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = sender.bounds
            popoverController.permittedArrowDirections = [.left, .down]
        }

        alertController.title = ParleyLocalizationKey.photo.localized
        alertController.addAction(UIAlertAction(
            title: ParleyLocalizationKey.selectPhoto.localized,
            style: .default,
            handler: { [weak self] _ in
                self?.selectPhoto()
            }
        ))

        alertController.addAction(UIAlertAction(
            title: ParleyLocalizationKey.takePhoto.localized,
            style: .default,
            handler: { [weak self] _ in
                self?.takePhoto()
            }
        ))

        alertController.addAction(UIAlertAction(title: ParleyLocalizationKey.cancel.localized, style: .cancel))

        present(alertController, animated: true, completion: nil)
    }

    private func isCameraAvailable() -> Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    private func selectPhoto() {
        if #available(iOS 14.0, *) {
            showImagePickerController()
        } else {
            Task {
                var status = PHPhotoLibrary.authorizationStatus()

                if case .notDetermined = status {
                    status = await requestPhotoLibraryAuthorization()
                }

                await MainActor.run { [status] in
                    if isPhotoLibraryAuthorized(status) {
                        showImagePickerController()
                    } else {
                        showPhotoAccessDeniedAlertController()
                    }
                }
            }
        }
    }

    @MainActor
    private func requestPhotoLibraryAuthorization() async -> PHAuthorizationStatus {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    private func isPhotoLibraryAuthorized(_ status: PHAuthorizationStatus) -> Bool {
        switch status {
        case .notDetermined, .denied, .restricted:
            return false
        case .authorized, .limited:
            return true
        @unknown default:
            return false
        }
    }

    private func takePhoto() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .camera
        present(imagePickerController, animated: true, completion: nil)
    }

    private func showImagePickerController() {
        if #available(iOS 14.0, *) {
            var configuration = PHPickerConfiguration(photoLibrary: .shared())
            configuration.selectionLimit = 1
            configuration.filter = .images
            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            present(picker, animated: true)
        } else {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.sourceType = .photoLibrary
            present(imagePickerController, animated: true, completion: nil)
        }
    }

    private func showPhotoAccessDeniedAlertController() {
        let alertController = UIAlertController(
            title: ParleyLocalizationKey.photoAccessDeniedTitle.localized,
            message: ParleyLocalizationKey.photoAccessDeniedBody.localized,
            preferredStyle: .alert
        )

        alertController.addAction(UIAlertAction(
            title: ParleyLocalizationKey.ok.localized,
            style: .cancel
        ))

        present(alertController, animated: true, completion: nil)
    }
}

// MARK: UITextViewDelegate
extension ParleyComposeView: UITextViewDelegate {

    public func textViewDidChange(_ textView: UITextView) {
        delegate?.didChange()

        sendButton.isEnabled = !self.textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        placeholderLabel.isHidden = !self.textView.text.isEmpty

        let cgSize = CGSize(width: self.textView.frame.width, height: .greatestFiniteMagnitude)
        let sizeThatFits = self.textView.sizeThatFits(cgSize)

        let minHeight: CGFloat = 23
        let maxHeight: CGFloat = 82

        var height = sizeThatFits.height
        if height < minHeight {
            height = minHeight
        } else if height > maxHeight {
            height = maxHeight
        }

        textView.isScrollEnabled = height >= maxHeight

        if textViewHeightConstraint.constant != height {
            UIView.animate(withDuration: 0.1) { [weak self] in
                guard let self else { return }
                textViewHeightConstraint.constant = height
                layoutIfNeeded()
            }
        }
    }

    public func textView(
        _ textView: UITextView,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool {
        textView.text.count + (text.count - range.length) <= maxCount
    }
}

// MARK: KeyboardAccessoryViewDelegate
extension ParleyComposeView: KeyboardAccessoryViewDelegate {

    func keyboardFrameChanged(_ frame: CGRect) {
        if let keyWindow = UIApplication.shared.windows.first(where: \.isKeyWindow) {
            let yFromBottom = keyWindow.bounds.height - convert(keyWindow.frame, to: nil).origin.y - self.frame.size
                .height

            let bottom = keyWindow.bounds.height - frame.origin.y - yFromBottom

            bottomLayoutConstraint.constant = bottom > 0 ? bottom : 0

            layoutIfNeeded()
        }
    }

    func keyboardDidHide(_ frame: CGRect) {
        bottomLayoutConstraint.constant = 0

        layoutIfNeeded()
        superview?.layoutIfNeeded()
    }
}

// MARK: UIImagePickerControllerDelegate
extension ParleyComposeView: UIImagePickerControllerDelegate {

    public func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {

        func dismissFailedToSelect() {
            picker.dismiss(animated: true, completion: { [weak self] in
                self?.delegate?.failedToSelectImage()
            })
        }

        guard let imageURL = info[.imageURL] as? URL, let asset = info[.phAsset] as? PHAsset else {
            // Image has been taken on device, therefore we can convert it to JPEG since you cannot take a GIF image directly.
            guard
                let fakeURL = URL(string: "tmp://fake/image/path/image.jpg"),
                let image = info[.originalImage] as? UIImage,
                let jpegData = MediaModel.convertToJpegData(image) else { dismissFailedToSelect() ; return }

            picker.dismiss(animated: true, completion: { [weak self] in
                self?.delegate?.send(image: image, with: jpegData, url: fakeURL)
            })

            return
        }

        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true

        PHImageManager.default().requestImageData(for: asset, options: options) { [weak self] data, _, _, _ in
            guard let data, let image = UIImage(data: data) else { dismissFailedToSelect() ; return }
            picker.dismiss(animated: true, completion: {
                self?.delegate?.send(image: image, with: data, url: imageURL)
            })
        }
    }

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: UINavigationControllerDelegate
extension ParleyComposeView: UINavigationControllerDelegate { }

@available(iOS 14.0, *)
extension ParleyComposeView: PHPickerViewControllerDelegate {

    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true) { [weak self] in
            self?.handleDidPickImage(results: results)
        }
    }

    private func handleDidPickImage(results: [PHPickerResult]) {
        guard !results.isEmpty else { return }
        Task {
            guard let itemProvider = results.first?.itemProvider else { await handleUnableToLoadImage() ; return }
            let fileName = itemProvider.suggestedName ?? UUID().uuidString

            do {
                let loadedImage = try await itemProvider.loadImage()
                delegate?.send(
                    image: loadedImage.image,
                    data: loadedImage.data,
                    fileName: fileName,
                    type: loadedImage.type
                )
            } catch {
                await handleUnableToLoadImage(error)
            }
        }
    }

    private func handleUnableToLoadImage(_ error: Error? = nil) async {
        await MainActor.run {
            let alertController = UIAlertController(
                title: ParleyLocalizationKey.sendFailedTitle.localized,
                message: ParleyLocalizationKey.sendFailedBodyMediaInvalid.localized,
                preferredStyle: .alert
            )

            alertController.addAction(UIAlertAction(
                title: ParleyLocalizationKey.ok.localized,
                style: .cancel
            ))

            present(alertController, animated: true, completion: nil)
        }
    }
}

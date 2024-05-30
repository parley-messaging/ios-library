import Photos
import UIKit

public class ParleyComposeView: UIView {
    
    @IBOutlet var contentView: UIView! {
        didSet {
            self.contentView.backgroundColor = UIColor.clear
        }
    }
    
    @IBOutlet weak var cameraButton: UIButton! {
        didSet {
            cameraButton.accessibilityLabel = ParleyLocalizationKey.voiceOverCameraButtonLabel.localized
        }
    }
    @IBOutlet weak var textViewBackgroundView: UIView! {
        didSet {
            self.textViewBackgroundView.layer.cornerRadius = 18
            self.textViewBackgroundView.layer.borderWidth = 1
        }
    }
    @IBOutlet weak var textView: UITextView! {
        didSet {
            self.textView.textContainerInset = .zero
            self.textView.textContainer.lineFragmentPadding = 0
            self.textView.autocorrectionType = .default
            
            self.textView.delegate = self
            
            let keyboardAccessoryView = KeyboardAccessoryView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            keyboardAccessoryView.delegate = self
            
            self.textView.inputAccessoryView = keyboardAccessoryView
            
            textView.accessibilityCustomActions = [
                UIAccessibilityCustomAction(
                    name: ParleyLocalizationKey.voiceOverDismissKeyboardAction.localized,
                    target: self,
                    selector: #selector(dismissKeyboard)
                )
            ]
            
            textView.adjustsFontForContentSizeCategory = true
        }
    }
    
    @objc private func dismissKeyboard() {
        textView.resignFirstResponder()
    }
    
    @IBOutlet weak var placeholderLabel: UILabel! {
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
    
    var appearance: ParleyComposeViewAppearance = ParleyComposeViewAppearance() {
        didSet {
            self.apply(self.appearance)
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
    
    var isEnabled: Bool = true {
        didSet {
            cameraButton.isEnabled = isEnabled
            textView.isEditable = isEnabled
            sendButton.isEnabled = isEnabled && !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    var maxCount: Int = 2000
    
    var allowPhotos = true {
        didSet {
            self.cameraButton.isHidden = !self.allowPhotos
            self.textViewBackgroundViewTrailingConstraint.constant = self.allowPhotos ? 56 : 16
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
        
        bottomLayoutConstraint = NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1.0, constant: 0)
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: contentView, attribute: .leading, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: contentView, attribute: .trailing, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1.0, constant: 0),
            bottomLayoutConstraint
        ])
    }
    
    private func apply(_ appearance: ParleyComposeViewAppearance) {
        self.backgroundColor = appearance.backgroundColor
        
        self.textViewBackgroundView.backgroundColor = appearance.inputBackgroundColor
        self.textViewBackgroundView.layer.borderColor = appearance.inputBorderColor.cgColor
        
        self.sendButton.backgroundColor = appearance.sendBackgroundColor
        if let iconTintColor = appearance.sendTintColor {
            let sendIcon = appearance.sendIcon.withRenderingMode(.alwaysTemplate)
            sendIcon.isAccessibilityElement = false
            sendIcon.accessibilityLabel = nil
            
            self.sendButton.setImage(sendIcon, for: .normal)
            
            self.sendButton.tintColor = iconTintColor
        } else {
            self.sendButton.setImage(appearance.sendIcon, for: .normal)
        }
        
        let cameraIcon = appearance.cameraIcon.withRenderingMode(.alwaysTemplate)
        cameraIcon.isAccessibilityElement = false
        cameraIcon.accessibilityLabel = nil
        self.cameraButton.setImage(cameraIcon, for: .normal)
        self.cameraButton.tintColor = appearance.cameraTintColor
        
        self.placeholderLabel.textColor = appearance.placeholderColor
        self.placeholderLabel.font = appearance.font
        
        self.textView.textColor = appearance.textColor
        self.textView.tintColor = appearance.tintColor
        self.textView.font = appearance.font
    }
    
    private func watchForContentSizeCategoryChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleContentSizeCategoryDidChange),
            name: UIContentSizeCategory.didChangeNotification,
            object: nil
        )
    }
    
    @objc private func handleContentSizeCategoryDidChange() {
        setPlaceHolderHeight()
    }
    
    func setPlaceHolderHeight() {
        // Needs extra time to render label in new font size.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.placeholderLabel.sizeToFit()
            
            if textView.text?.isEmpty == true {
                self.textViewHeightConstraint.constant = max(23, self.placeholderLabel.bounds.height)
            }
            
            self.layoutIfNeeded()
        }
    }
    
    @IBAction func send(_ sender: UIButton) {
        if let message = self.textView.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
            self.delegate?.send(message)
        }
        
        self.textView.text = ""
        self.textViewDidChange(self.textView)
    }
    
    // MARK: Image picker
    @IBAction func presentImageActionSheet(_ sender: UIButton) {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            break
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { _ in
                DispatchQueue.main.async { [weak self] in
                    self?.presentImageActionSheet(sender)
                }
            }
            
            return
        default:
            self.showPhotoAccessDeniedAlertController()
            
            return
        }
        
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            self.showImagePickerController(.photoLibrary)

            return
        }
        
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
            handler: { [weak self] action in
                self?.showImagePickerController(.photoLibrary)
        }))
        
        alertController.addAction(UIAlertAction(
            title: ParleyLocalizationKey.takePhoto.localized,
            style: .default,
            handler: { [weak self] action in
                self?.showImagePickerController(.camera)
        }))
        
        alertController.addAction(UIAlertAction(
            title: ParleyLocalizationKey.cancel.localized,
            style: .cancel
        ))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func showImagePickerController(_ sourceType: UIImagePickerController.SourceType) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = sourceType
        
        self.present(imagePickerController, animated: true, completion: nil)
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
        
        self.present(alertController, animated: true, completion: nil)
    }
}

// MARK: UITextViewDelegate
extension ParleyComposeView: UITextViewDelegate {
    
    public func textViewDidChange(_ textView: UITextView) {
        self.delegate?.didChange()
        
        self.sendButton.isEnabled = !self.textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        self.placeholderLabel.isHidden = !self.textView.text.isEmpty
        
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

        if self.textViewHeightConstraint.constant != height {
            UIView.animate(withDuration: 0.1) {
                self.textViewHeightConstraint.constant = height
                
                self.layoutIfNeeded()
            }
        }
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return textView.text.count + (text.count - range.length) <= self.maxCount
    }
}

// MARK: KeyboardAccessoryViewDelegate
extension ParleyComposeView: KeyboardAccessoryViewDelegate {
    
    func keyboardFrameChanged(_ frame: CGRect) {
        if let keyWindow = UIApplication.shared.windows.first(where: \.isKeyWindow) {
            let yFromBottom = keyWindow.bounds.height - self.convert(keyWindow.frame, to: nil).origin.y - self.frame.size.height
            
            let bottom = keyWindow.bounds.height - frame.origin.y - yFromBottom
            
            self.bottomLayoutConstraint.constant = bottom > 0 ? bottom : 0
            
            self.layoutIfNeeded()
        }
    }
    
    func keyboardDidHide(_ frame: CGRect) {
        self.bottomLayoutConstraint.constant = 0
        
        self.layoutIfNeeded()
        self.superview?.layoutIfNeeded()
    }
}

// MARK: UIImagePickerControllerDelegate
extension ParleyComposeView: UIImagePickerControllerDelegate {
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        
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
                let jpegData = MediaModel.convertToJpegData(image)
            else { dismissFailedToSelect() ; return }
            
            picker.dismiss(animated: true, completion: { [weak self] in
                self?.delegate?.send(image: image, with: jpegData, url: fakeURL)
            })
            
            return
        }
        
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
            
        PHImageManager.default().requestImageData(for: asset, options: options) { [weak self] (data, _, _, _) in
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
extension ParleyComposeView: UINavigationControllerDelegate {
    
    //
}

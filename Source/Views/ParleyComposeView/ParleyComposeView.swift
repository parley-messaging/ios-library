import Photos

public class ParleyComposeView: UIView {
    
    @IBOutlet var contentView: UIView! {
        didSet {
            self.contentView.backgroundColor = UIColor.clear
        }
    }
    
    @IBOutlet weak var cameraButton: UIButton!
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
            
            self.textView.delegate = self
            
            let keyboardAccessoryView = KeyboardAccessoryView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            keyboardAccessoryView.delegate = self
            
            self.textView.inputAccessoryView = keyboardAccessoryView
        }
    }
    @IBOutlet weak var placeholderLabel: UILabel!
    @IBOutlet weak var sendButton: UIButton! {
        didSet {
            self.sendButton.layer.cornerRadius = 13
        }
    }
    
    @IBOutlet weak var textViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var textViewBackgroundViewTrailingConstraint: NSLayoutConstraint!
    
    var bottomLayoutConstraint: NSLayoutConstraint!
    
    var appearance: ParleyComposeViewAppearance = ParleyComposeViewAppearance() {
        didSet {
            self.apply(appearance)
        }
    }
    var delegate: ParleyComposeViewDelegate?
    
    var placeholder: String? {
        didSet {
            self.placeholderLabel.text = self.placeholder
        }
    }
    var isEnabled: Bool = true {
        didSet {
            self.cameraButton.isEnabled = self.isEnabled
            self.textView.isEditable = self.isEnabled
            self.sendButton.isEnabled = self.isEnabled && !self.textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    var maxCount: Int = Int(INT_MAX)
    
    var allowPhotos = true {
        didSet {
            self.cameraButton.isHidden = !self.allowPhotos
            self.textViewBackgroundViewTrailingConstraint.constant = self.allowPhotos ? 56 : 16
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setup()
    }
    
    private func setup() {
        self.loadXib()
        
        self.apply(appearance)
    }
    
    private func loadXib() {
        Bundle(for: type(of: self)).loadNibNamed("ParleyComposeView", owner: self, options: nil)
        
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.contentView)
        
        NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: self.contentView, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: self.contentView, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: self.contentView, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        self.bottomLayoutConstraint = NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: self.contentView, attribute: .bottom, multiplier: 1.0, constant: 0)
        self.bottomLayoutConstraint.isActive = true
    }
    
    private func apply(_ appearance: ParleyComposeViewAppearance) {
        self.backgroundColor = appearance.backgroundColor
        
        self.textViewBackgroundView.backgroundColor = appearance.inputBackgroundColor
        self.textViewBackgroundView.layer.borderColor = appearance.inputBorderColor.cgColor
        
        self.sendButton.backgroundColor = appearance.sendBackgroundColor
        if let iconTintColor = appearance.sendTintColor {
            self.sendButton.setImage(appearance.sendIcon.withRenderingMode(.alwaysTemplate), for: .normal)
            self.sendButton.tintColor = iconTintColor
        } else {
            self.sendButton.setImage(appearance.sendIcon, for: .normal)
        }
        
        self.cameraButton.setImage(appearance.cameraIcon.withRenderingMode(.alwaysTemplate), for: .normal)
        self.cameraButton.tintColor = appearance.cameraTintColor
        
        self.placeholderLabel.textColor = appearance.placeholderColor
        self.placeholderLabel.font = appearance.font
        
        self.textView.textColor = appearance.textColor
        self.textView.tintColor = appearance.tintColor
        self.textView.font = appearance.font
    }
    
    @IBAction func send(_ sender: UIButton) {
        if let message = self.textView.text {
            self.delegate?.send(message)
        }
        
        self.textView.text = ""
        self.textViewDidChange(self.textView)
    }
    
    // MARK: Image picker
    @IBAction func presentImageActionSheet(_ sender: Any) {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            break
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { _ in
                DispatchQueue.main.async {
                    self.presentImageActionSheet(sender)
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
        alertController.title = NSLocalizedString("parley_photo", bundle: Bundle(for: type(of: self)), comment: "")
        alertController.addAction(UIAlertAction(
            title: NSLocalizedString("parley_select_photo", bundle: Bundle(for: type(of: self)), comment: ""),
            style: .default,
            handler: { (action) in
                self.showImagePickerController(.photoLibrary)
        }))
        
        alertController.addAction(UIAlertAction(
            title: NSLocalizedString("parley_take_photo", bundle: Bundle(for: type(of: self)), comment: ""),
            style: .default,
            handler: { (action) in
                self.showImagePickerController(.camera)
        }))
        
        alertController.addAction(UIAlertAction(
            title: NSLocalizedString("parley_cancel", bundle: Bundle(for: type(of: self)), comment: ""),
            style: .cancel,
            handler: nil
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
            title: NSLocalizedString("parley_photo_access_denied_title", bundle: Bundle(for: type(of: self)), comment: ""),
            message: NSLocalizedString("parley_photo_access_denied_body", bundle: Bundle(for: type(of: self)), comment: ""),
            preferredStyle: .alert
        )
        
        alertController.addAction(UIAlertAction(
            title: NSLocalizedString("parley_ok", bundle: Bundle(for: type(of: self)), comment: ""),
            style: .cancel,
            handler: nil
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
                self.superview?.layoutIfNeeded()
            }
        }
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return textView.text.count + (text.count - range.length) <= self.maxCount
    }
}

// MARK: KeyboardAccessoryViewDelegate
extension ParleyComposeView: KeyboardAccessoryViewDelegate {
    
    func keyboardDidShow(_ frame: CGRect) {
        //
    }
    
    func keyboardFrameChanged(_ frame: CGRect) {
        if let keyWindow = UIApplication.shared.keyWindow {
            let yFromBottom = keyWindow.bounds.height - self.convert(keyWindow.frame, to: nil).origin.y - self.frame.size.height
            
            let bottom = keyWindow.bounds.height - frame.origin.y - yFromBottom
            
            self.bottomLayoutConstraint.constant = bottom > 0 ? bottom : 0
            
            self.layoutIfNeeded()
            self.superview?.layoutIfNeeded()
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
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//        if let imageURL = info[.imageURL] as? URL, let phAsset = info[.phAsset] as? PHAsset {
//            PHImageManager.default().requestImageData(for: phAsset, options: nil) { (data, uti, _, _) in
//                if uti?.contains(".gif") == true, let data = data, let image = UIImage.gif(data: data) {
//                    self.delegate?.send(imageURL, image, data)
//                    
//                    picker.dismiss(animated: true, completion: nil)
//                } else if let data = data, let image = UIImage(data: data) {
//                    self.delegate?.send(imageURL, image, data)
//                    
//                    picker.dismiss(animated: true, completion: nil)
//                } else {
//                    self.imagePickerController(picker, didFinishPickingMediaLegacyWithInfo: info)
//                }
//            }
//        } else  {
            self.imagePickerController(picker, didFinishPickingMediaLegacyWithInfo: info)
//        }
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaLegacyWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let imageURL = URL(string: "tmp://fake/image/path/tmp.jpg")!
        let image = info[.originalImage] as! UIImage
        let data = image.jpegData(compressionQuality: 1.0)
        
        self.delegate?.send(imageURL, image, data)
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: UINavigationControllerDelegate
extension ParleyComposeView: UINavigationControllerDelegate {
    
    //
}

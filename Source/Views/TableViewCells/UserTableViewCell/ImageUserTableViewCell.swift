import Alamofire

internal class ImageUserTableViewCell: UserTableViewCell {
    
    @IBOutlet weak var loadingActivityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var imageImageView: UIImageView!
    
    internal var appearance = ImageUserTableViewCellAppearance() {
        didSet {
            self.apply(appearance)
        }
    }
    private var findImageRequest: DataRequest?
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        
        self.apply(appearance)
    }
    
    override func render(_ message: Message) {
        super.render(message)
        
        self.layoutSubviews()
        DispatchQueue.main.async {
            self.imageImageView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
            self.addMetaGradient()
        }
        
        if let image = message.image {
            self.imageImageView.image = image
            
            self.loadingActivityIndicatorView.isHidden = true
            self.loadingActivityIndicatorView.stopAnimating()
        } else if let id = message.id {
            self.findImageRequest?.cancel()
            
            self.loadingActivityIndicatorView.isHidden = false
            self.loadingActivityIndicatorView.startAnimating()
            
            self.findImageRequest = MessageRepository().findImage(id, onSuccess: { (image) in
                self.loadingActivityIndicatorView.isHidden = true
                self.loadingActivityIndicatorView.stopAnimating()
                
                self.imageImageView.image = image
            }) { (error) in
                self.loadingActivityIndicatorView.isHidden = true
                self.loadingActivityIndicatorView.stopAnimating()
            }
        }
    }
    
    private func addMetaGradient() {
        let gradient = CAGradientLayer()
        gradient.startPoint = CGPoint(x: 1, y: 1)
        gradient.endPoint = CGPoint(x: 0, y: 0.45)
        gradient.type = .radial
        gradient.colors = [
            self.appearance.shadowStartColor.cgColor,
            self.appearance.shadowEndColor.cgColor
        ]
        
        let width = self.timeLabel.frame.width + self.metaRightLayoutConstraint.constant + 50
        let height = self.timeLabel.frame.height + self.metaBottomLayoutConstraint.constant + 30
        gradient.frame = CGRect(
            x: self.imageImageView.frame.width - width,
            y: self.imageImageView.frame.height - height,
            width: width,
            height: height
        )
        
        self.imageImageView.layer.insertSublayer(gradient, at: 0)
    }
    
    func apply(_ appearance: ImageUserTableViewCellAppearance) {
        super.apply(appearance)
        
        self.imageImageView.image = appearance.imagePlaceholder
        self.imageImageView.layer.cornerRadius = CGFloat(appearance.imageCornerRadius)
        
        self.loadingActivityIndicatorView.color = appearance.loaderTintColor
    }
}

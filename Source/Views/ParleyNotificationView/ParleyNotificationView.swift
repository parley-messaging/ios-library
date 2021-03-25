public class ParleyNotificationView: UIView {
    
    @IBOutlet var contentView: UIView! {
        didSet {
            self.contentView.backgroundColor = UIColor.clear
        }
    }
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var label: UILabel!
    
    var appearance: ParleyNotificationViewAppearance? {
        didSet {
            guard let appearance = self.appearance else { return }
            
            self.apply(appearance)
        }
    }
    
    var text: String? {
        didSet {
            self.label.text = self.text
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
    }
    
    private func loadXib() {
        Bundle(for: type(of: self)).loadNibNamed("ParleyNotificationView", owner: self, options: nil)
        
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.contentView)
        
        NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: self.contentView, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: self.contentView, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: self.contentView, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: self.contentView, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
    }
    
    private func apply(_ appearance: ParleyNotificationViewAppearance) {
        self.backgroundColor = appearance.backgroundColor
        
        if let iconTintColor = appearance.iconTintColor {
            self.imageView.image = appearance.icon.withRenderingMode(.alwaysTemplate)
            self.imageView.tintColor = iconTintColor
        } else {
            self.imageView.image = appearance.icon.withRenderingMode(.alwaysOriginal)
        }
        
        self.label.textColor = appearance.textColor
        self.label.font = appearance.font
    }
}

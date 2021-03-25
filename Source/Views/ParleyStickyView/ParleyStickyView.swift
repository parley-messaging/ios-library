public class ParleyStickyView: UIView {
    
    @IBOutlet var contentView: UIView! {
        didSet {
            self.contentView.backgroundColor = UIColor.clear
        }
    }
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var textView: ParleyTextView!
    
    var appearance: ParleyStickyViewAppearance = ParleyStickyViewAppearance() {
        didSet {
            self.apply(self.appearance)
        }
    }
    
    var text: String? {
        didSet {
            self.textView.markdownText = self.text
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
        
        self.apply(self.appearance)
    }
    
    private func loadXib() {
        Bundle(for: type(of: self)).loadNibNamed("ParleyStickyView", owner: self, options: nil)
        
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.contentView)
        
        NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: self.contentView, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: self.contentView, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: self.contentView, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: self.contentView, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
    }
    
    private func apply(_ appearance: ParleyStickyViewAppearance) {
        self.backgroundColor = appearance.backgroundColor
        
        if let iconTintColor = appearance.iconTintColor {
            self.imageView.image = appearance.icon.withRenderingMode(.alwaysTemplate)
            self.imageView.tintColor = iconTintColor
        } else {
            self.imageView.image = appearance.icon.withRenderingMode(.alwaysOriginal)
        }
        
        self.textView.textColor = appearance.color
        self.textView.tintColor = appearance.tintColor
        
        self.textView.regularFont = appearance.regularFont
        self.textView.italicFont = appearance.italicFont
        self.textView.boldFont = appearance.boldFont
    
        self.textView.markdownText = self.text
    }
}

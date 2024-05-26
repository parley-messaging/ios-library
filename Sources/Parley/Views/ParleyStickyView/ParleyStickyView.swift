import UIKit

final class ParleyStickyView: UIView {
    
    @IBOutlet private weak var contentHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet var contentView: UIView! {
        didSet {
            self.contentView.backgroundColor = UIColor.clear
        }
    }
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var textView: ParleyTextView!
    
    private var heightObserver: NSKeyValueObservation?
    private let totalVerticalContentInsets: CGFloat = 16
    
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
        
        apply(appearance)
        watchContentHeight()
    }
    
    private func loadXib() {
        Bundle.module.loadNibNamed("ParleyStickyView", owner: self, options: nil)
        
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
        
        self.textView.appearance = appearance.textViewAppearance
    
        self.textView.markdownText = self.text
        
        textView.contentInset = UIEdgeInsets(
            top: totalVerticalContentInsets / 2,
            left: 0,
            bottom: totalVerticalContentInsets / 2,
            right: 0
        )
        textView.isScrollEnabled = true
    }
    
    private func watchContentHeight() {
        heightObserver = observe(\.textView?.contentSize, options: [.initial, .new]) { [weak self] _, change in
            guard
                let newValue = change.newValue,
                let height = newValue?.height,
                let self
            else { return }
            
            let totalVerticalInsets: CGFloat = self.totalVerticalContentInsets
            self.contentHeightConstraint.constant = min(200, (height + totalVerticalInsets))
            
            self.layoutIfNeeded()
        }
    }
}

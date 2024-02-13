import UIKit

public class ParleyNotificationView: UIView {
    
    @IBOutlet private var contentView: UIView! {
        didSet {
            self.contentView.backgroundColor = UIColor.clear
        }
    }
    
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var label: UILabel!
    
    var appearance: ParleyNotificationViewAppearance? {
        didSet {
            guard let appearance = appearance else { return }
            
            apply(appearance)
        }
    }
    
    var text: String? {
        didSet {
            label.text = text
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
    
    private func setup() {
        loadXib()
    }
    
    private func loadXib() {
        Bundle.current.loadNibNamed("ParleyNotificationView", owner: self, options: nil)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor)
        ])
    }
    
    private func apply(_ appearance: ParleyNotificationViewAppearance) {
        backgroundColor = appearance.backgroundColor
        
        if let iconTintColor = appearance.iconTintColor {
            imageView.image = appearance.icon.withRenderingMode(.alwaysTemplate)
            imageView.tintColor = iconTintColor
        } else {
            imageView.image = appearance.icon.withRenderingMode(.alwaysOriginal)
        }
        
        label.textColor = appearance.textColor
        label.font = appearance.font
        label.numberOfLines = .zero
        label.adjustsFontForContentSizeCategory = true
    }
}
import UIKit

public class ParleyStickyViewAppearance {
    
    public var backgroundColor = UIColor(red:1, green:1, blue:1, alpha:0.9)
    
    public var icon: UIImage
    public var iconTintColor: UIColor? = UIColor(red:0.29, green:0.37, blue:0.51, alpha:1.0)
    
    public var color = UIColor(red:0.29, green:0.37, blue:0.51, alpha:1.0)
    public var tintColor = UIColor(red:0.08, green:0.49, blue:0.98, alpha:1.0)
    
    public var regularFont = UIFont.systemFont(ofSize: 13)
    public var italicFont = UIFont.italicSystemFont(ofSize: 13)
    public var boldFont = UIFont.boldSystemFont(ofSize: 13)
    
    init() {
        self.icon = UIImage(named: "ic_error_outline", in: Bundle.current, compatibleWith: nil)!
    }
}

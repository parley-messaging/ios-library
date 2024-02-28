import UIKit

public class ParleyMessageViewAppearance {
    
    // Balloon
    public var balloonImage: UIImage?
    public var balloonTintColor: UIColor?
    
    public var balloonContentInsets: UIEdgeInsets?
    public var balloonContentTextInsets: UIEdgeInsets?
    
    // Image
    public var imageCornerRadius: Float = 20
    public var imagePlaceholder: UIImage
    public var imageLoaderTintColor: UIColor = UIColor(white:0, alpha:0.8)
    
    public var imageInnerColor: UIColor = .white
    public var imageInnerShadowStartColor: UIColor = UIColor(white: 0, alpha: 0.3)
    public var imageInnerShadowEndColor: UIColor = UIColor(white: 0, alpha: 0)
    
    public var imageInsets: UIEdgeInsets? = UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
    
    // Name
    public var name: Bool = true
    public var nameColor: UIColor = UIColor(red:0.29, green:0.37, blue:0.51, alpha:1.0)
    @ParleyScaledFont(textStyle: .body) public var nameFont = .boldSystemFont(ofSize: 13)
    
    public var nameInsets: UIEdgeInsets? = UIEdgeInsets(top: 0, left: 0, bottom: 4, right: 0)
    
    // Title
    public var titleColor: UIColor = UIColor(white: 0, alpha: 1)
    @ParleyScaledFont(textStyle: .body) public var titleFont: UIFont = .boldSystemFont(ofSize: 13)
    
    public var titleInsets: UIEdgeInsets? = UIEdgeInsets(top: 0, left: 0, bottom: 4, right: 0)
    
    // Message
    public var messageColor: UIColor = UIColor(white:0.28, alpha:1.0)
    public var messageTintColor: UIColor = UIColor(red:0.08, green:0.49, blue:0.98, alpha:1.0)
    
    @ParleyScaledFont(textStyle: .body) public var messageRegularFont = .systemFont(ofSize: 14)
    @ParleyScaledFont(textStyle: .body) public var messageItalicFont = .italicSystemFont(ofSize: 14)
    @ParleyScaledFont(textStyle: .body) public var messageBoldFont = .boldSystemFont(ofSize: 14)
    
    public var messageInsets: UIEdgeInsets?
    
    // Meta
    public var metaInsets: UIEdgeInsets?
    
    public var timeColor: UIColor = UIColor(white: 0, alpha: 0.6)
    @ParleyScaledFont(textStyle: .callout) public var timeFont = .systemFont(ofSize: 12)
    
    public var statusTintColor: UIColor = UIColor(white: 1, alpha: 0.6)
    
    // Buttons
    public var buttonsInsets: UIEdgeInsets?
    public var buttonInsets: UIEdgeInsets?
    
    public var buttonSeperatorColor: UIColor = UIColor(white:0.91, alpha:1.0)
    
    @ParleyScaledFont(textStyle: .headline) public var buttonFont = .systemFont(ofSize: 16)
    public var buttonColor: UIColor = UIColor(red:0.29, green:0.37, blue:0.51, alpha:1.0)
    
    init() {
        self.imagePlaceholder = UIImage(named: "placeholder", in: .module, compatibleWith: nil)!
    }
}

public class UserTableViewCellAppearance {
        
    public var backgroundImage: UIImage?
    public var backgroundTintColor: UIColor? = UIColor(red:0.29, green:0.37, blue:0.51, alpha:1.0)
    
    public var contentInset: UIEdgeInsets?
    
    public var metaInset: UIEdgeInsets?
    
    public var timeColor: UIColor
    public var timeFont: UIFont = UIFont.systemFont(ofSize: 12)
    
    public var statusTintColor: UIColor
    
    init(timeColor: UIColor, statusTintColor: UIColor) {
        self.timeColor = timeColor
        self.statusTintColor = statusTintColor
        
        let edgdeInsets = UIEdgeInsets(top: 21, left: 21, bottom: 21, right: 23)
        self.backgroundImage = UIImage(named: "user_balloon", in: Bundle(for: type(of: self)), compatibleWith: nil)?.resizableImage(withCapInsets: edgdeInsets)
    }
}

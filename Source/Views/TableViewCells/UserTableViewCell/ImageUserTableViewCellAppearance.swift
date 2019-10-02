public class ImageUserTableViewCellAppearance: UserTableViewCellAppearance {
        
    public var imageCornerRadius: Float = 20
    public var imagePlaceholder: UIImage
    
    public var loaderTintColor: UIColor = UIColor(white:0, alpha:0.8)
    
    public var shadowStartColor: UIColor = UIColor(white: 0, alpha: 0.3)
    public var shadowEndColor: UIColor = UIColor(white: 0, alpha: 0)
    
    init() {
        self.imagePlaceholder = UIImage(named: "placeholder", in: Bundle(for: type(of: self)), compatibleWith: nil)!
        
        super.init(timeColor: UIColor(white: 1, alpha: 1), statusTintColor: UIColor(white: 1, alpha: 1))
        
        self.contentInset = UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 5)
        self.metaInset = UIEdgeInsets(top: 0, left: 0, bottom: 4, right: 9)
    }
}

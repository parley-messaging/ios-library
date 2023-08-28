import UIKit

public class InfoTableViewCellAppearance {
    
    public var textColor: UIColor = UIColor(red:0.29, green:0.37, blue:0.51, alpha:1.0)
    
    @ParleyScaledFont(textStyle: .body) public var regularFont = .systemFont(ofSize: 14)
    @ParleyScaledFont(textStyle: .body) public var italicFont = .italicSystemFont(ofSize: 14)
    @ParleyScaledFont(textStyle: .body) public var boldFont = .boldSystemFont(ofSize: 14)

    public var contentInset: UIEdgeInsets? = UIEdgeInsets(top: 16, left: 32, bottom: 16, right: 32)
}

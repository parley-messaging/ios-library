import UIKit

final class AccesibilityTappableView: UIView {
    
    protocol Delegate: AnyObject {
        func didActivate() -> Bool
    }
    
    weak var delegate: Delegate?
    
    override func accessibilityActivate() -> Bool {
        return delegate?.didActivate() ?? true
    }
}

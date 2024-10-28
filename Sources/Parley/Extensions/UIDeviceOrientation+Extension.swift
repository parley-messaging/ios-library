import UIKit

extension UIDeviceOrientation {
 
    enum Simplified {
        case portrait
        case landscape
    }
    
    var simplifiedOrientation: Simplified? {
        switch self {
        case .portrait, .portraitUpsideDown: .portrait
        case .landscapeLeft, .landscapeRight: .landscape
        default: nil
        }
    }
}

import Foundation

extension String {
    
    internal var localized: String {
        NSLocalizedString(self, bundle: Bundle.current, comment: "")
    }
}

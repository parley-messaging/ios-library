import Foundation

private class BundleFinder {}

extension Bundle {
    
    static var current: Bundle = {
        #if SWIFT_PACKAGE
            return Bundle.module
        #endif
        
        return Bundle(for: BundleFinder.self)
    }()
}

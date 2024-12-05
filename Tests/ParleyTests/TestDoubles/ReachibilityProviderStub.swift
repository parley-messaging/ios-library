@testable import Parley

struct ReachibilityProviderStub: ReachibilityProvider {
    
    private(set) var reachable: Bool = true
}

extension ReachibilityProviderStub {
    
    mutating func whenReachable(_ result: Bool) {
        reachable = result
    }
}

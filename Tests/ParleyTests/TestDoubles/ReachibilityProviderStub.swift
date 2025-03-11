@testable import Parley

struct ReachabilityProviderStub: ReachabilityProvider {
    
    private(set) var reachable: Bool = true
}

extension ReachabilityProviderStub {
    
    mutating func whenReachable(_ result: Bool) {
        reachable = result
    }
}

@preconcurrency import Reachability
@preconcurrency import Combine

final class ReachabilityService: ReachabilityProvider, Sendable {
    
    private let reachability: Reachability
    private let currentValueSubject = PassthroughSubject<Bool, Never>()
    
    var reachable: Bool {
        reachability.connection != .unavailable
    }
    
    init() throws {
        self.reachability = try Reachability()
        setup()
    }
}

// MARK: - Methods
extension ReachabilityService {
    
    func startNotifier() throws {
        try reachability.startNotifier()
    }
    
    func stopNotifier() throws {
        try reachability.startNotifier()
    }
    
    func reachabilityPublisher() -> AnyPublisher<Bool, Never> {
        currentValueSubject.eraseToAnyPublisher()
    }
}

// MARK: - Privates
private extension ReachabilityService {

    func setup() {
        reachability.whenReachable = { [weak self] _ in
            Task { [weak self] in
                self?.currentValueSubject.send(true)
            }
        }
        
        reachability.whenReachable = { [weak self] _ in
            Task { [weak self] in
                self?.currentValueSubject.send(false)
            }
        }
    }
}

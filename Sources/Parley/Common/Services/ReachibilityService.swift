@preconcurrency import Combine

final class ReachabilityService: ReachabilityProvider, Sendable {
    
    private nonisolated(unsafe) var networkMonitor: NetworkMonitorProtocol!
    private let currentValueSubject = PassthroughSubject<Bool, Never>()
    
    var reachable: Bool {
        get async {
            await networkMonitor.isConnected
        }
    }
    
    init() throws {
        networkMonitor = NetworkMonitor(delegate: self)
    }
}

// MARK: - Methods
extension ReachabilityService {
    
    func startNotifier() async {
        await networkMonitor.start()
    }
    
    func stopNotifier() async {
        await networkMonitor.stop()
    }
    
    func reachabilityPublisher() -> AnyPublisher<Bool, Never> {
        currentValueSubject.eraseToAnyPublisher()
    }
}

// MARK: - Privates
extension ReachabilityService: NetworkMonitorDelegate {
    
    func didUpdateConnection(isConnected: Bool) {
        currentValueSubject.send(isConnected)
    }
}

import Foundation
import Network

protocol NetworkMonitorDelegate: AnyObject, Sendable {
    @MainActor func didUpdateConnection(isConnected: Bool)
}

protocol NetworkMonitorProtocol: Sendable {
    func start() async
    func stop() async
    var isConnected: Bool { get async }
}

final actor NetworkMonitor<NWPathMonitorType: NWPathMonitorProtocol>: Sendable, NetworkMonitorProtocol {
    private let networkMonitor: NWPathMonitorType
    private let workerQueue = DispatchQueue(label: "nu.parley.NetworkMonitor")

    private weak var delegate: NetworkMonitorDelegate?
    
    var isConnected: Bool {
        Self.hasConnection(status: networkMonitor.currentPath.status)
    }

    init(
        networkMonitor: NWPathMonitorType = NWPathMonitor(),
        delegate: NetworkMonitorDelegate
    ) {
        self.networkMonitor = networkMonitor
        self.delegate = delegate
    }

    func start() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }

            Task { [weak self] in
                await self?.delegate?.didUpdateConnection(isConnected: Self.hasConnection(status: path.status))
            }
        }
        networkMonitor.start(queue: workerQueue)
        let status = networkMonitor.currentPath.status
        Task {
            /// When there is no change, the start monitor will not call the `pathUpdateHandler` on start.
            await delegate?.didUpdateConnection(isConnected: Self.hasConnection(status: status))
        }
    }

    func stop() {
        networkMonitor.cancel()
    }

    private static func hasConnection(status: NWPath.Status) -> Bool {
        status == .satisfied
    }
}

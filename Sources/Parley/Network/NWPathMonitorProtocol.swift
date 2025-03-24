import Network

protocol NWPathMonitorProtocol: AnyObject {
    associatedtype Path: PathProtocol
    func start(queue: DispatchQueue)
    func cancel()
    var pathUpdateHandler: (@Sendable (Path) -> Void)? { get set }
    var currentPath: Path { get }
}

extension NWPathMonitor: NWPathMonitorProtocol {}

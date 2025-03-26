import Network
@testable import Parley

public final class NWPathMonitorSpy<Path: PathProtocol>: NWPathMonitorProtocol {
    
    public init() {}

    public var pathUpdateHandler: (@Sendable (Path) -> Void)?
    public var currentPath: Path {
        get { return underlyingCurrentPath }
        set(value) { underlyingCurrentPath = value }
    }

    public var underlyingCurrentPath: Path!

    // MARK: - start

    public var startQueueCallsCount = 0
    public var startQueueCalled: Bool {
        return startQueueCallsCount > 0
    }

    public var startQueueReceivedQueue: DispatchQueue?
    public var startQueueReceivedInvocations: [DispatchQueue] = []
    public var startQueueClosure: ((DispatchQueue) -> Void)?

    public func start(queue: DispatchQueue) {
        startQueueCallsCount += 1
        startQueueReceivedQueue = queue
        startQueueReceivedInvocations.append(queue)
        startQueueClosure?(queue)
    }

    // MARK: - cancel

    public var cancelCallsCount = 0
    public var cancelCalled: Bool {
        return cancelCallsCount > 0
    }

    public var cancelClosure: (() -> Void)?

    public func cancel() {
        cancelCallsCount += 1
        cancelClosure?()
    }

}

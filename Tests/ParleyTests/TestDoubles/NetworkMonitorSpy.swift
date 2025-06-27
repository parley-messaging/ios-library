import Foundation

@testable import Parley

public final class NetworkMonitorSpy: @unchecked Sendable, NetworkMonitorProtocol {

    public init() {}
    
    public var isConnected: Bool = false

    // MARK: - start

    public var startCallsCount = 0
    public var startCalled: Bool {
        return startCallsCount > 0
    }

    public var startClosure: (() -> Void)?

    public func start() {
        startCallsCount += 1
        startClosure?()
    }

    // MARK: - stop

    public var stopCallsCount = 0
    public var stopCalled: Bool {
        return stopCallsCount > 0
    }

    public var stopClosure: (() -> Void)?

    public func stop() {
        stopCallsCount += 1
        stopClosure?()
    }
}

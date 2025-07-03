import Foundation

@testable import Parley

public final class NetworkMonitorDelegateSpy: @unchecked Sendable, NetworkMonitorDelegate {

    public init() {}

    // MARK: - didUpdateConnection

    public var didUpdateConnectionIsConnectedCallsCount = 0
    public var didUpdateConnectionIsConnectedCalled: Bool {
        return didUpdateConnectionIsConnectedCallsCount > 0
    }
    public var didUpdateConnectionIsConnectedReceivedIsConnected: Bool?
    public var didUpdateConnectionIsConnectedReceivedInvocations: [Bool] = []
    public var didUpdateConnectionIsConnectedClosure: ((Bool) -> Void)?

    public func didUpdateConnection(isConnected: Bool) {
        didUpdateConnectionIsConnectedCallsCount += 1
        didUpdateConnectionIsConnectedReceivedIsConnected = isConnected
        didUpdateConnectionIsConnectedReceivedInvocations.append(isConnected)
        didUpdateConnectionIsConnectedClosure?(isConnected)
    }

}

import Foundation
import Testing
import Network
@testable import Parley

@Suite("Network Monitor Tests", .serialized)
struct NetworkMonitorTests {

    private var networkMonitorSpy: NWPathMonitorSpy<PathStub>!
    private var delegateSpy: NetworkMonitorDelegateSpy!

    init() {
        networkMonitorSpy = NWPathMonitorSpy()
        networkMonitorSpy.underlyingCurrentPath = PathStub(underlyingStatus: .satisfied)
        delegateSpy = NetworkMonitorDelegateSpy()
    }

    @Test
    func callDelegateOnStart() {
        let sut = NetworkMonitor(networkMonitor: networkMonitorSpy, delegate: delegateSpy)

        sut.start()

        #expect(networkMonitorSpy.startQueueCallsCount == 1)
        #expect(networkMonitorSpy.pathUpdateHandler != nil)
        #expect(delegateSpy.didUpdateConnectionIsConnectedCalled)
    }

    @Test
    func stopMonitorOnStop() {
        let sut = NetworkMonitor(networkMonitor: networkMonitorSpy, delegate: delegateSpy)

        sut.stop()

        #expect(networkMonitorSpy.startQueueCalled == false)
        #expect(networkMonitorSpy.cancelCalled == true)
        #expect(delegateSpy.didUpdateConnectionIsConnectedCalled == false)
    }
}

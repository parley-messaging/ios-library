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
    func callDelegateOnStart() async throws {
        let sut = NetworkMonitor(networkMonitor: networkMonitorSpy, delegate: delegateSpy)

        await sut.start()
        try await Task.sleep(nanoseconds: 300_000) // 30 milliseconds

        #expect(networkMonitorSpy.startQueueCallsCount == 1)
        #expect(networkMonitorSpy.pathUpdateHandler != nil)
        #expect(delegateSpy.didUpdateConnectionIsConnectedCalled)
    }

    @Test
    func stopMonitorOnStop() async {
        let sut = NetworkMonitor(networkMonitor: networkMonitorSpy, delegate: delegateSpy)

        await sut.stop()

        #expect(networkMonitorSpy.startQueueCalled == false)
        #expect(networkMonitorSpy.cancelCalled == true)
        #expect(delegateSpy.didUpdateConnectionIsConnectedCalled == false)
    }
}

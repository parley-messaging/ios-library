@testable import Parley

final class PollingServiceStub: PollingServiceProtocol {
    func startRefreshing() {
    }

    func stopRefreshing() {
    }

    var delegate: ParleyDelegate?
}

@testable import Parley

final class NotificationServiceStub: NotificationServiceProtocol {
    func notificationsEnabled() async -> Bool {
        true
    }
}

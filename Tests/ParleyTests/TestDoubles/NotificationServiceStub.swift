@testable import Parley

final class NotificationServiceStub: NotificationServiceProtocol {
    func notificationsEnabled(completion: @escaping ((Bool) -> Void)) {
        completion(true)
    }
}

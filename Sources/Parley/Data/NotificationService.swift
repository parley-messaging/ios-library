import Foundation
import UIKit

struct NotificationService {

    func notificationsEnabled(completion: @escaping ((Bool) -> Void)) {
        let current = UNUserNotificationCenter.current()

        current.getNotificationSettings(completionHandler: { settings in
            switch settings.authorizationStatus {
            case .authorized, .ephemeral, .provisional:
                completion(true)
            default:
                completion(false)
            }
        })
    }
}

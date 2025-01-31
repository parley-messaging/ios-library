import Foundation
import UIKit

protocol NotificationServiceProtocol {
    func notificationsEnabled(completion: @escaping ((Bool) -> Void))
    func notificationsEnabled() async -> Bool
}

struct NotificationService: NotificationServiceProtocol {

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

extension NotificationService {
    
    func notificationsEnabled() async -> Bool {
        let current = UNUserNotificationCenter.current()
        let settings = await current.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .ephemeral, .provisional:
            return true
        default:
            return false
        }
    }
}

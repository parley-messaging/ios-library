import Foundation

internal class NotificationService {
    
    internal func notificationsEnabled(completion: @escaping  ((Bool) -> ())) {
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

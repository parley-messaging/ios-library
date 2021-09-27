import Foundation

class NotificationService: NSObject {
    
    let current = UNUserNotificationCenter.current()
    
    func notificationsEnabled(completion: @escaping  ((Bool) -> ())) {
        

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

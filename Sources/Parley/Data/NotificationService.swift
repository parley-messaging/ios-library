import Foundation
import UIKit

protocol NotificationServiceProtocol: Sendable {
    func notificationsEnabled() async -> Bool
}

struct NotificationService: NotificationServiceProtocol {

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

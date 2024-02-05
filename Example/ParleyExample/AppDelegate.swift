import UIKit
import Firebase
import Parley
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Start: Configuring Firebase Cloud Messaging
        FirebaseApp.configure()
        
        Messaging.messaging().delegate = self

        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: { pushEnabled, error in
            Parley.shared.setPushEnabled(pushEnabled)
        })

        application.registerForRemoteNotifications()
        // Stop: Configuring Firebase Cloud Messaging
        
        return true
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        UNUserNotificationCenter.current().getNotificationSettings { notificationSettings in
            let pushEnabled = notificationSettings.authorizationStatus == .authorized

            Parley.shared.setPushEnabled(pushEnabled)
        }
    }
}

extension AppDelegate : UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        _ = Parley.shared.handle(userInfo)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if UIApplication.shared.applicationState == .active {
            completionHandler([])
        } else {
            completionHandler([.alert, .sound])
        }
    }
}

extension AppDelegate: MessagingDelegate {
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken pushToken: String?) {
        guard let pushToken = pushToken else { return }
        
        Parley.shared.setPushToken(pushToken)
    }
}

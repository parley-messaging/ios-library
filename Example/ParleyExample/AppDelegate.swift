import Firebase
import Parley
import UIKit
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Start: Configuring Firebase Cloud Messaging
        FirebaseApp.configure()

        Messaging.messaging().delegate = self

        UNUserNotificationCenter.current().delegate = self

        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { pushEnabled, _ in
                Parley.setPushEnabled(pushEnabled)
            }
        )

        application.registerForRemoteNotifications()
        // Stop: Configuring Firebase Cloud Messaging

        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        UNUserNotificationCenter.current().getNotificationSettings { notificationSettings in
            let pushEnabled = notificationSettings.authorizationStatus == .authorized

            Parley.setPushEnabled(pushEnabled)
        }
    }
}

extension AppDelegate: @preconcurrency UNUserNotificationCenterDelegate {
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any]
    ) async -> UIBackgroundFetchResult {
        await Parley.handle(Parley.RemoteMessageData(userInfo))
        return .noData
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        if UIApplication.shared.applicationState == .active {
            return []
        } else {
            return [.alert, .sound]
        }
    }
}

extension AppDelegate: @preconcurrency MessagingDelegate {

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken pushToken: String?) {
        guard let pushToken = pushToken else { return }

        Parley.setPushToken(pushToken)
    }
}

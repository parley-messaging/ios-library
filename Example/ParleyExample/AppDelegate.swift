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

        Task {
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            let notificationCenter = UNUserNotificationCenter.current()
            guard let enabled = try? await notificationCenter.requestAuthorization(options: authOptions) else { return }
            _ = await Parley.setPushEnabled(enabled)
        }

        application.registerForRemoteNotifications()
        // Stop: Configuring Firebase Cloud Messaging

        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        UNUserNotificationCenter.current().getNotificationSettings { notificationSettings in
            let pushEnabled = notificationSettings.authorizationStatus == .authorized

            Task {
                await Parley.setPushEnabled(pushEnabled)
            }
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        Task {
            _ = await Parley.handle(Parley.RemoteMessageData(userInfo))
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
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
        Task {
            await Parley.setPushToken(pushToken)
        }
    }
}

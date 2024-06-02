import UIKit

extension UIView {

    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        var viewController = UIApplication.shared.windows.first(where: \.isKeyWindow)?.rootViewController
        if viewController?.presentedViewController != nil {
            viewController = viewController?.presentedViewController
        }
        if let navigationController = viewController as? UINavigationController {
            viewController = navigationController.viewControllers.last
        }

        viewController?.present(viewControllerToPresent, animated: true, completion: nil)
    }

    func watchForVoiceOverDidChangeNotification(observer: AnyObject) {
        NotificationCenter.default.addObserver(
            observer,
            selector: #selector(voiceOverDidChangeNotificationCallback),
            name: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil
        )

        // Run callback function immediately
        voiceOverDidChangeNotificationCallback()
    }

    @objc
    private func voiceOverDidChangeNotificationCallback() {
        voiceOverDidChange(isVoiceOverRunning: UIAccessibility.isVoiceOverRunning)
    }

    /// Called when VoiceOver status changed.
    /// - Important: Call `watchForVoiceOverDidChangeNotification(observer:)` to get callbacks.
    @objc
    func voiceOverDidChange(isVoiceOverRunning: Bool) { }
}

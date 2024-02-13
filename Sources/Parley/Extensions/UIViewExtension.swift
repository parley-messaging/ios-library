import UIKit

extension UIView {
    
    internal func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        var viewController = UIApplication.shared.keyWindow?.rootViewController
        if viewController?.presentedViewController != nil {
            viewController = viewController?.presentedViewController
        }
        if let navigationController = viewController as? UINavigationController {
            viewController = navigationController.viewControllers.last
        }
        
        viewController?.present(viewControllerToPresent, animated: true, completion: nil)
    }
    
    internal func watchForVoiceOverDidChangeNotification(observer: AnyObject) {
        NotificationCenter.default.addObserver(
            observer,
            selector: #selector(voiceOverDidChangeNotificationCallback),
            name: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil
        )
        
        // Run callback function immediately
        voiceOverDidChangeNotificationCallback()
    }
    
    @objc private func voiceOverDidChangeNotificationCallback() {
        voiceOverDidChange(isVoiceOverRunning: UIAccessibility.isVoiceOverRunning)
    }
    
    /// Called when VoiceOver status changed.
    /// - Important: Call `watchForVoiceOverDidChangeNotification(observer:)` to get callbacks.
    @objc internal func voiceOverDidChange(isVoiceOverRunning: Bool) { }
}
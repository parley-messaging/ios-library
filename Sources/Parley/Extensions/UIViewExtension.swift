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
    
    func pinToSides(in view: UIView, insets: UIEdgeInsets = .zero) {        
        NSLayoutConstraint.activate([
            self.topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top),
            self.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: insets.right),
            self.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: insets.bottom),
            self.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: insets.left),
        ])
    }
    
    func hasUserIntrefaceStyleChanged(_ previousTraitCollection: UITraitCollection) -> Bool {
        traitCollection.userInterfaceStyle != previousTraitCollection.userInterfaceStyle
    }
}

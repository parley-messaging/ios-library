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
}

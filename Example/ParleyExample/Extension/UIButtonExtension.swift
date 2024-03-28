import UIKit

extension UIButton {

    func setLoading(_ loading: Bool) {
        DispatchQueue.main.async {
            let tag = 808404 // The tag of a UIActivityIndicatorView
            if loading {
                self.isEnabled = false
                self.alpha = 0.5

                let buttonHeight = self.bounds.size.height
                let buttonWidth = self.bounds.size.width

                let activityIndicatorView = UIActivityIndicatorView()
                activityIndicatorView.center = CGPoint(x: buttonWidth / 2, y: buttonHeight / 2)
                activityIndicatorView.tag = tag
                activityIndicatorView.color = UIColor.white
                activityIndicatorView.startAnimating()

                self.addSubview(activityIndicatorView)
            } else {
                self.isEnabled = true
                self.alpha = 1.0
                if let indicator = self.viewWithTag(tag) as? UIActivityIndicatorView {
                    indicator.stopAnimating()
                    indicator.removeFromSuperview()
                }
            }
        }
    }
}

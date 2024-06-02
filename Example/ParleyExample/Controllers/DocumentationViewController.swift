import UIKit
import WebKit

class DocumentationViewController: BaseViewController {

    @IBOutlet weak var webView: WKWebView! {
        didSet {
            webView.navigationDelegate = self

            if let url = URL(string: "https://github.com/parley-messaging/ios-library#readme") {
                let urlRequest = URLRequest(url: url)

                webView.load(urlRequest)
            }
        }
    }

    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("documentation_title", comment: "")
    }
}

// MARK: WKNavigationDelegate
extension DocumentationViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        activityIndicatorView.startAnimating()
        activityIndicatorView.isHidden = false
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicatorView.stopAnimating()
        activityIndicatorView.isHidden = true
    }
}

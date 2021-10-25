import UIKit
import WebKit

class DocumentationViewController: BaseViewController {
        
    @IBOutlet weak var webView: WKWebView! {
        didSet {
            self.webView.navigationDelegate = self
            
            if let url = URL(string: "https://developers.parley.nu/docs/introduction-2") {
                let urlRequest = URLRequest(url: url)
                
                self.webView.load(urlRequest)
            }
        }
    }
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("documentation_title", comment: "")
    }
}

// MARK: WKNavigationDelegate
extension DocumentationViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.activityIndicatorView.startAnimating()
        self.activityIndicatorView.isHidden = false
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.activityIndicatorView.stopAnimating()
        self.activityIndicatorView.isHidden = true
    }
}

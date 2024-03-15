import UIKit

class TabBarViewController: UITabBarController {
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupTabBarItems()
    }
    
    // MARK: UITabBarItems
    private func setupTabBarItems() {
        self.tabBar.items?[0].title = NSLocalizedString("chat_title", comment: "")
        self.tabBar.items?[1].title = NSLocalizedString("documentation_title", comment: "")
        
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        self.tabBar.standardAppearance = appearance
    }
}

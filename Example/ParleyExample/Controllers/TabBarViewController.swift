import UIKit

class TabBarViewController: UITabBarController {

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupTabBarItems()
    }

    // MARK: UITabBarItems
    private func setupTabBarItems() {
        tabBar.items?[0].title = NSLocalizedString("chat_title", comment: "")
        tabBar.items?[1].title = NSLocalizedString("documentation_title", comment: "")

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        tabBar.standardAppearance = appearance
    }
}

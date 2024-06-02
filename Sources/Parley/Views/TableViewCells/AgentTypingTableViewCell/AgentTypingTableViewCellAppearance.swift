import UIKit

public class AgentTypingTableViewCellAppearance {

    public var backgroundImage: UIImage?
    public var backgroundTintColor: UIColor? = UIColor.white

    public var contentInset: UIEdgeInsets? = UIEdgeInsets(top: 3, left: 15, bottom: 3, right: 13)

    public var dotColor = UIColor.black

    init() {
        let edgeInsets = UIEdgeInsets(top: 21, left: 23, bottom: 21, right: 21)
        backgroundImage = UIImage(named: "agent_balloon", in: .module, compatibleWith: nil)?
            .resizableImage(withCapInsets: edgeInsets)
    }
}

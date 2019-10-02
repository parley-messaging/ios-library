public class AgentTableViewCellAppearance {
        
    public var backgroundImage: UIImage?
    public var backgroundTintColor: UIColor?
    
    public var contentInset: UIEdgeInsets?
    
    public var metaInset: UIEdgeInsets?
    
    public var timeColor: UIColor
    public var timeFont: UIFont = UIFont.systemFont(ofSize: 12)
    
    public var showAgentName: Bool
    public var agentColor: UIColor
    public var agentFont: UIFont = UIFont.boldSystemFont(ofSize: 13)
    
    init(agentColor: UIColor, timeColor: UIColor) {
        self.agentColor = agentColor
        self.timeColor = timeColor

        self.showAgentName = true
        let edgeInsets = UIEdgeInsets(top: 21, left: 23, bottom: 21, right: 21)
        self.backgroundImage = UIImage(named: "agent_balloon", in: Bundle(for: type(of: self)), compatibleWith: nil)?.resizableImage(withCapInsets: edgeInsets)
        self.backgroundTintColor = UIColor.white
    }
}

public class MessageAgentTableViewCellAppearance: AgentTableViewCellAppearance {
        
    public var messageColor: UIColor = UIColor.black
    public var messageTintColor: UIColor = UIColor(red:0.08, green:0.49, blue:0.98, alpha:1.0)
    
    public var messageRegularFont: UIFont = UIFont.systemFont(ofSize: 14)
    public var messageItalicFont: UIFont = UIFont.italicSystemFont(ofSize: 14)
    public var messageBoldFont: UIFont = UIFont.boldSystemFont(ofSize: 14)
    
    init() {
        super.init(agentColor: UIColor(white: 0, alpha: 1), timeColor: UIColor(white: 0, alpha: 0.6))
        
        self.contentInset = UIEdgeInsets(top: 8, left: 14, bottom: 6, right: 14)
        self.metaInset = UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)
    }
}

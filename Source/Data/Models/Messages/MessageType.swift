enum MessageType: Int, Codable {
    
    case loading = -3
    case agentTyping = -2
    case date = -1
    case info = 0
    case user = 1
    case agent = 2
    case auto = 3
    case systemMessageUser = 4
    case systemMessageAgent = 5
    
    static let ignored: [MessageType] = [.auto, .systemMessageUser, .systemMessageAgent]
}

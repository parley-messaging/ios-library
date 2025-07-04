struct Settings {
    
    enum Flow {
        case `default`(openChatDirectly: Bool)
        case specialLightweight
        
        var openChatDirectly: Bool? {
            return switch self {
            case .default(let openChatDirectly): openChatDirectly
            case .specialLightweight: nil
            }
        }
    }
    
    static let flow: Flow = .default(openChatDirectly: false) // Recomended
//    static let flow: Flow = .default(openChatDirectly: true) // Chat shows loader while configuring
//    static let flow: Flow = .specialLightweight // Requires special handling
    
    /// Disable offline messaging in the demo app to show error messages as an alert before opening the chat
    static let offlineMessagingEnabled = false
}

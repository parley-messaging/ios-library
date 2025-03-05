struct StoredMessageButton: Codable, Sendable {
    
    enum MessageButtonType: String, Codable {
        case reply
        case phoneNumber
        case webUrl
        
        func toDomainModel() -> MessageButton.MessageButtonType {
            switch self {
            case .reply: return .reply
            case .phoneNumber: return .phoneNumber
            case .webUrl: return .webUrl
            }
        }
        
        static func from(_ type: MessageButton.MessageButtonType) -> Self {
            switch type {
            case .reply: return .reply
            case .phoneNumber: return .phoneNumber
            case .webUrl: return .webUrl
            }
        }
    }

    let title: String
    let payload: String?
    let type: MessageButtonType
    
    func toDomainModel() -> MessageButton {
        MessageButton(title: title, payload: payload, type: type.toDomainModel())
    }
    
    static func from(_ button: MessageButton) -> Self {
        Self(title: button.title, payload: button.payload, type: .from(button.type))
    }
}

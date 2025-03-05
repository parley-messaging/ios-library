struct MessageButton: Sendable {
    enum MessageButtonType: String {
        case reply
        case phoneNumber
        case webUrl
    }

    let title: String
    let payload: String?
    let type: MessageButtonType

    init(title: String, payload: String?, type: MessageButtonType = .reply) {
        self.title = title
        self.payload = payload
        self.type = type
    }
}

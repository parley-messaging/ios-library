
public struct MessageButton: Codable {
   
    var title: String
    var payload: String?
    var type: MessageButtonType!
    
    init(title: String, payload: String, type: MessageButtonType = .reply) {
        self.title = title
        self.payload = payload
        self.type = type
    }
}

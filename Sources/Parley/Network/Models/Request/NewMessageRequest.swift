import Foundation

struct NewMessageRequest: Codable {
    
    let time: Int
    let message: String?
    let media: MediaObject?
    let type: MessageResponse.MessageType?
    let referrer: String?
    
    init(message: Message) {
        self.time = Int(message.time.timeIntervalSince1970)
        self.message = message.message
        self.media = message.media
        self.type = .from(message.type)
        self.referrer = message.referrer
    }
}

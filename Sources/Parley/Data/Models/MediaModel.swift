import UIKit

internal struct MediaModel: Codable {
    let image: Data
    var url: URL
    var type: ParleyImageType { .map(from: url) }
    let filename: String
    var hasUploaded = false
    
    func createMessage(status: Message.MessageStatus) -> Message {
        let message = Message()
        message.mediaSendRequest = self
        message.status = status
        message.type = .user
        message.time = Date()
        return message
    }
}

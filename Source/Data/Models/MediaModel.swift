import UIKit

internal struct MediaModel {
    let image: UIImage
    let data: Data
    var url: URL
    var type: ParleyImageType { .map(from: url) }
    let filename: String
    
    func createMessage(status: Message.MessageStatus) -> Message {
        let message = Message()
        message.image = image
        message.mediaSendRequest = self
        message.status = status
        message.type = .user
        return message
    }
}

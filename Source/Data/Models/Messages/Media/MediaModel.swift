import UIKit

internal struct MediaModel {
    let image: UIImage
    let data: Data
    var url: URL
    var type: ParleyImageType { .map(from: url) }
    let filename: String
    
    func createMessage(status: Message.MessageStatus) -> Message {
        let message = Message()
        switch Parley.shared.network.apiVersion {
        case .v1_6:
            message.cachedMedia = self
        default:
            message.image = image
        }
        message.status = status
        message.type = .user
        return message
    }
}

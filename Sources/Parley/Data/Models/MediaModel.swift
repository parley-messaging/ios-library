import UIKit

internal struct MediaModel: Codable {
    let image: Data
    let url: URL
    let type: ParleyImageType
    let filename: String
    var hasUploaded = false
    
    init?(image: UIImage, data: Data, url: URL) {
        self.url = url
        self.filename = url.lastPathComponent
        self.type = .map(from: url)
        
        switch type {
        case .png, .jpg:
            guard let jpegData = image.jpegData(compressionQuality: 1) else { return nil }
            self.image = jpegData
        case .gif:
            self.image = data
        }
    }
    
    func createMessage(status: Message.MessageStatus) -> Message {
        let message = Message()
        message.mediaSendRequest = self
        message.status = status
        message.type = .user
        message.time = Date()
        return message
    }
    
    /// Returns wether the file is larger than a specified size in MB
    /// - Parameter size: Size in megabytes
    func isLargerThan(size: Int) -> Bool {
        let sizeInMB = size * 1024 * 1024
        return image.count > sizeInMB
    }
}

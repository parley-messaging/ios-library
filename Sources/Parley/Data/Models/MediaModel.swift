import UIKit
import UniformTypeIdentifiers

struct MediaModel: Codable {
    let data: Data
    let type: ParleyImageType
    let filename: String
    var hasUploaded = false

    init?(image: UIImage, data: Data, url: URL) {
        filename = url.lastPathComponent
        type = .map(from: url)

        switch type {
        case .png, .jpg:
            guard let jpegData = Self.convertToJpegData(image) else { return nil }
            self.data = jpegData
        case .gif:
            self.data = data
        }
    }

    @available(iOS 14.0, *)
    init?(image: UIImage, data: Data, fileName: String, type: UTType) {
        filename = fileName

        switch type {
        case .gif:
            self.data = data
            self.type = .gif
        default:
            guard let jpegData = Self.convertToJpegData(image) else { return nil }
            self.data = jpegData
            self.type = .jpg
        }
    }
}

extension MediaModel {

    func createMessage(status: Message.MessageStatus) -> Message {
        let message = Message()
        message.status = status
        message.type = .user
        message.time = Date()
        return message
    }

    /// Returns wether the file is larger than a specified size in MB
    /// - Parameter size: Size in megabytes
    func isLargerThan(size: Int) -> Bool {
        let sizeInMB = size * 1000 * 1000
        return data.count > sizeInMB
    }

    static func convertToJpegData(_ image: UIImage) -> Data? {
        image.jpegData(compressionQuality: 1)
    }
}

import UIKit
import UniformTypeIdentifiers

struct MediaModel: Codable {
    let data: Data
    let type: ParleyMediaType
    let filename: String

    init(data: Data, url: URL) {
        filename = url.lastPathComponent
        type = .map(from: url)
        self.data = data
    }

    init?(image: UIImage, data: Data, url: URL) {
        filename = url.lastPathComponent
        type = .map(from: url)

        switch type {
        case .imagePng, .imageJPeg:
            guard let jpegData = Self.convertToJpegData(image) else { return nil }
            self.data = jpegData
        case .imageGif, .applicationPdf, .other:
            self.data = data
        }
    }

    @available(iOS 14.0, *)
    init?(image: UIImage, data: Data, fileName: String, type: UTType) {
        filename = fileName

        switch type {
        case .gif:
            self.data = data
            self.type = .imageGif
        default:
            guard let jpegData = Self.convertToJpegData(image) else { return nil }
            self.data = jpegData
            self.type = .imageJPeg
        }
    }
}

extension MediaModel {

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

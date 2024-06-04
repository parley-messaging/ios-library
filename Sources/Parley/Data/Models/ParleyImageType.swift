import Foundation
import UIKit

enum ParleyImageType: String, CaseIterable, Codable {
    case png
    case gif
    case jpg

    /// Returns a mime type
    /// for example: "image/png"
    var mimeType: String {
        switch self {
        case .png:
            "image/png"
        case .gif:
            "image/gif"
        case .jpg:
            "image/jpeg"
        }
    }

    /// Appends a dot (.) before the file extension.
    /// example: .png
    var fileExtension: String {
        ".\(rawValue)"
    }

    /// Returns a ParleyImageType from a given URL
    /// Defaults to .jpg.
    /// - Parameters:
    ///  - url: Local URL of the image
    /// - Returns: ParleyImageType
    static func map(from url: URL) -> ParleyImageType {
        let imageName = url.lastPathComponent
        return ParleyImageType.allCases.first { imageName.contains($0.fileExtension) } ?? .jpg
    }
}

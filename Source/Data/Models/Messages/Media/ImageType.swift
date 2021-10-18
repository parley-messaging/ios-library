import Foundation
import UIKit

internal enum ImageType: String, CaseIterable {
    case png
    case gif
    case jpg
    
    var mimeType: String {
        switch self {
        case .png:
            return "image/png"
        case .gif:
            return "image/gif"
        case .jpg:
            return "image/gif"
        }
    }
    
    /// Appends a dot (.) before the file extension.
    /// example: .png
    var fileExtension: String {
        return ".\(self.rawValue)"
    }
    
    static func map(from url: URL) -> ImageType? {
        let imageName = url.lastPathComponent
        return ImageType.allCases.first { imageName.contains($0.fileExtension) }
    }
}

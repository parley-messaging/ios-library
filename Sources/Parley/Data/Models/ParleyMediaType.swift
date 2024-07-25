import Foundation
import UIKit

enum ParleyMediaType: String, CaseIterable, Codable {
    case imagePng = "image/png"
    case imageGif = "image/gif"
    case imageJPeg = "image/jpeg"
    case applicationPdf = "application/pdf"
    case other = "application/octet-stream"

    /// Appends a dot (.) before the file extension.
    /// example: .png
    var fileExtension: String {
        switch self {
        case .imagePng:
            ".png"
        case .imageGif:
            ".gif"
        case .imageJPeg:
            ".jpg"
        case .applicationPdf:
            ".pdf"
        case .other:
            ".bin"
        }
    }
    
    var isImageType: Bool {
        switch self {
        case .imagePng, .imageGif, .imageJPeg:
            true
        case .applicationPdf, .other:
            false
        }
    }

    /// Returns a ParleyMediaType from a given mimetype
    /// Defaults to .other.
    /// - Parameters:
    ///  - mimetype: MimeType of the media
    /// - Returns: ParleyMediaType
    static func from(mimeType: String) -> ParleyMediaType {
        ParleyMediaType(rawValue: mimeType) ?? .other
    }
    
    /// Returns a ParleyMediaType from a given URL
    /// Defaults to .other.
    /// - Parameters:
    ///  - url: Local URL of the media
    /// - Returns: ParleyMediaType
    static func map(from url: URL) -> ParleyMediaType {
        let mediaName = url.lastPathComponent
        return ParleyMediaType.allCases.first { mediaName.contains($0.fileExtension) } ?? .other
    }
}

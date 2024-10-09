import Foundation
import UIKit

struct MediaObject: Codable {
    let id: String
    let mimeType: String

    func getMediaType() -> ParleyMediaType {
        ParleyMediaType.from(mimeType: mimeType);
    }

    func imageFromData(_ imageData: Data) -> UIImage? {
        if getMediaType() == .imageGif {
            UIImage.gif(data: imageData)
        } else {
            UIImage(data: imageData)
        }
    }

    /// Returns a displayable file name for a MediaObject.
    ///
    /// The **displayFileName** is not used to reference the file name in local storage and as such can not be used to retrieve the file from local storage.
    /// - Returns: A file name to display to the user
    var displayFileName: String {
        let filePath = ParleyStoredMedia.FilePath.from(media: self) ?? ParleyStoredMedia.FilePath(
            name: UUID().uuidString,
            type: .applicationPdf
        )
        return filePath.fileName
    }
}

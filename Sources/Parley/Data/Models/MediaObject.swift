import Foundation
import UIKit

struct MediaObject: Codable {
    let id: String
    let mimeType: String
    
    func getMediaType() -> ParleyImageType {
        return ParleyImageType.from(mimeType: mimeType);
    }
    
    func imageFromData(_ imageData: Data) -> UIImage? {
        if getMediaType() == .imageGif {
            return UIImage.gif(data: imageData)
        } else {
            return UIImage(data: imageData)
        }
    }
}

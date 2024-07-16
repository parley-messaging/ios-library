import Foundation

struct MediaObject: Codable {
    let id: String
    let mimeType: String
    
    public func getMediaType() -> ParleyImageType {
        return ParleyImageType.from(mimeType: mimeType);
    }
}

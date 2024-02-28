import Foundation

/// An image stored locally on-device.
///
/// This image can either be already uploaded or is pending to be uploaded later when the user is online.
public struct ParleyStoredImage: Codable, Identifiable, Equatable {
    public let id: String
    var data: Data
    let type: ParleyImageType
    var filename: String { id }
    
    static func from(media: MediaModel) -> ParleyStoredImage {
        ParleyStoredImage(id: UUID().uuidString, data: media.data, type: media.type)
    }
}

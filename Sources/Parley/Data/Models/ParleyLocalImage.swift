import Foundation

public struct ParleyLocalImage: Codable, Identifiable, Equatable {
    public let id: String
    var data: Data
    let type: ParleyImageType
    var filename: String { id }
    
    static func from(media: MediaModel) -> ParleyLocalImage {
        ParleyLocalImage(id: UUID().uuidString, data: media.data, type: media.type)
    }
}

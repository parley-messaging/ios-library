import Foundation

public struct ParleyLocalImage: Codable, Identifiable {
    public let id: String
    var data: Data
    let type: ParleyImageType
    let filename: String
    
    init(data: Data, type: ParleyImageType) {
        self.data = data
        self.type = type
        self.id = UUID().uuidString
        self.filename = id
    }
    
    static func from(media: MediaModel) -> ParleyLocalImage {
        ParleyLocalImage(data: media.data, type: media.type)
    }
}

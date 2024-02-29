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
    
    struct FilePath {
        let name: String
        let type: ParleyImageType
        
        private init(name: String, type: ParleyImageType) {
            self.name = name
            self.type = type
        }
        
        static func create(image: ParleyStoredImage) -> String {
            return [image.id, image.type.fileExtension].joined()
        }
        
        static func decode(url: URL) -> FilePath? {
            var splitFilename = url.lastPathComponent.split(separator: ".")
            let fileName = String(splitFilename.removeFirst())
            let type = String(splitFilename.removeLast())
            guard let imageType = ParleyImageType(rawValue: type) else { return nil }
            
            return FilePath(name: fileName, type: imageType)
        }
    }
}

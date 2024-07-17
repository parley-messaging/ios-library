import Foundation

/// An image stored locally on-device.
///
/// This image can either be already uploaded or is pending to be uploaded later when the user is online.
public struct ParleyStoredImage: Codable {
    let filename: String
    var data: Data
    let type: ParleyImageType
    let path: FilePath

    init(filename: String, data: Data, type: ParleyImageType) {
        self.filename = filename
        self.data = data
        self.type = type
        path = FilePath(name: filename, type: type)
    }

    static func from(media: MediaModel) -> ParleyStoredImage {
        ParleyStoredImage(
            filename: UUID().uuidString,
            data: media.data,
            type: media.type
        )
    }

    struct FilePath: Codable {
        let name: String
        let type: ParleyImageType

        var fileName: String {
            [name, type.fileExtension].joined().replacingOccurrences(of: "/", with: "_")
        }

        package init(name: String, type: ParleyImageType) {
            self.name = name
            self.type = type
        }

        static func from(image: ParleyStoredImage) -> FilePath {
            FilePath(name: image.filename, type: image.type)
        }

        static func from(media: MediaObject) -> FilePath? {
            return .from(id: media.id, type: media.getMediaType())
        }
        
        static func from(id: String, type: ParleyImageType) -> FilePath? {
            guard let fileName = decodeFileName(id: id) else {
                return nil
            }
            return FilePath(name: fileName, type: type)
        }
        
        static func from(url: URL) -> FilePath? {
            let type = ParleyImageType.map(from: url)
            guard let fileName = decodeFileName(id: url.absoluteString) else {
                return nil
            }
            
            return FilePath(name: fileName, type: type)
        }

        private static func decodeFileName(id: String) -> String? {
            guard var splitFilename = id.split(separator: "/").last?.split(separator: "."), splitFilename.count >= 2 else {
                return nil
            }

            splitFilename.removeLast()
            return String(splitFilename.removeLast())
        }
    }
}

extension ParleyStoredImage: Identifiable {

    public var id: String { filename }
}

extension ParleyStoredImage: Equatable {

    public static func == (lhs: ParleyStoredImage, rhs: ParleyStoredImage) -> Bool {
        lhs.id == rhs.id
    }
}

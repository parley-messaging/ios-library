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

    struct FilePath: Codable, CustomStringConvertible {
        let name: String
        let type: ParleyImageType

        var description: String {
            [name, type.fileExtension].joined().replacingOccurrences(of: "/", with: "_")
        }

        package init(name: String, type: ParleyImageType) {
            self.name = name
            self.type = type
        }

        static func create(image: ParleyStoredImage) -> String {
            FilePath(name: image.filename, type: image.type).description
        }

        static func create(path: String) -> FilePath? {
            if let url = URL(string: path) {
                decode(url: url)
            } else {
                nil
            }
        }

        static func decode(url: URL) -> FilePath? {
            var splitFilename = url.lastPathComponent.split(separator: ".")
            guard splitFilename.count >= 2 else { return nil }

            let type = String(splitFilename.removeLast())
            let fileName = String(splitFilename.removeLast())

            guard let imageType = ParleyImageType(rawValue: type) else { return nil }
            return FilePath(name: fileName, type: imageType)
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

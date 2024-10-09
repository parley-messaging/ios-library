import Foundation

/// A file stored locally on-device.
///
/// This file can either be already uploaded or is pending to be uploaded later when the user is online.
public struct ParleyStoredMedia: Codable {
    let filename: String
    var data: Data
    let type: ParleyMediaType
    let path: FilePath

    init(filename: String, data: Data, type: ParleyMediaType) {
        self.filename = filename
        self.data = data
        self.type = type
        path = FilePath(name: filename, type: type)
    }

    static func from(media: MediaModel) -> ParleyStoredMedia {
        ParleyStoredMedia(
            filename: UUID().uuidString,
            data: media.data,
            type: media.type
        )
    }

    struct FilePath: Codable {
        let name: String
        let type: ParleyMediaType

        var fileName: String {
            [name, type.fileExtension].joined().replacingOccurrences(of: "/", with: "_")
        }

        package init(name: String, type: ParleyMediaType) {
            self.name = name
            self.type = type
        }

        static func from(media: ParleyStoredMedia) -> FilePath {
            FilePath(name: media.filename, type: media.type)
        }

        static func from(media: MediaObject) -> FilePath? {
            .from(id: media.id, type: media.getMediaType())
        }

        static func from(id: String, type: ParleyMediaType) -> FilePath? {
            guard let fileName = decodeFileName(id: id) else {
                return nil
            }
            return FilePath(name: fileName, type: type)
        }

        static func from(url: URL) -> FilePath? {
            let type = ParleyMediaType.map(from: url)
            guard let fileName = decodeFileName(id: url.absoluteString) else {
                return nil
            }

            return FilePath(name: fileName, type: type)
        }

        private static func decodeFileName(id: String) -> String? {
            guard
                var splitFilename = id.split(separator: "/").last?.split(separator: "."),
                splitFilename.count >= 2 else
            {
                return nil
            }

            splitFilename.removeLast()
            return String(splitFilename.removeLast())
        }
    }
}

extension ParleyStoredMedia: Identifiable {

    public var id: String { filename }
}

extension ParleyStoredMedia: Equatable {

    public static func == (lhs: ParleyStoredMedia, rhs: ParleyStoredMedia) -> Bool {
        lhs.id == rhs.id
    }
}

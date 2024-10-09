import Foundation

class ParleyFileManager {

    private let fileManager: FileManager = .default
    private let destination: URL

    init() throws {
        destination = fileManager.temporaryDirectory.appendingPathComponent(kParleyCacheFilesDirectory)
        try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
    }

    func save(fileData: Data, for media: MediaObject) -> URL? {
        guard
            let path = path(for: media),
            fileManager.createFile(atPath: path.path, contents: fileData) else
        {
            return nil
        }

        return path
    }

    func file(for media: MediaObject) -> Data? {
        guard let path = path(for: media) else {
            return nil
        }

        return fileManager.contents(atPath: path.path)
    }

    func path(for media: MediaObject) -> URL? {
        guard let fileName = ParleyStoredMedia.FilePath.from(media: media)?.fileName else {
            return nil
        }

        return destination.appendingPathComponent(fileName)
    }
}

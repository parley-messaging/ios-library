import Foundation

protocol ShareManagerProtocol: Sendable {
    func share(media: MediaObject) async throws -> URL
}

final class ShareManager: ShareManagerProtocol {

    enum ShareManagerError: Error {
        case unableToSaveFile(id: String)
    }

    private let fileManager: ParleyFileManager
    private let mediaLoader: MediaLoaderProtocol

    init(mediaLoader: MediaLoaderProtocol) throws {
        self.mediaLoader = mediaLoader
        fileManager = try ParleyFileManager()
    }

    func share(media: MediaObject) async throws -> URL {
        if await fileManager.file(for: media) != nil, let url = await fileManager.path(for: media) {
            return url
        }

        let data = try await mediaLoader.load(media: media)
        guard let url = await fileManager.save(fileData: data, for: media) else {
            throw ShareManagerError.unableToSaveFile(id: media.id)
        }

        return url
    }
}

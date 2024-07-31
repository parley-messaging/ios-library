import Foundation

class MediaRepository {

    enum MediaRepositoryError: Error {
        case invalidRemoteURL
    }

    weak var dataSource: ParleyMediaDataSource?
    private var messageRemoteService: MessageRemoteService

    init(messageRemoteService: MessageRemoteService) {
        self.messageRemoteService = messageRemoteService
    }

    func store(media: MediaModel) -> ParleyStoredMedia {
        let storedMedia = ParleyStoredMedia.from(media: media)
        store(media: storedMedia)
        return storedMedia
    }
    
    func getStoredMedia(for media: MediaObject) -> ParleyStoredMedia? {
        return dataSource?.media(id: media.id)
    }

    func getRemoteMedia(for media: MediaObject) async throws -> Data {
        let mediaURL = try createMediaURL(path: media.id)
        let mediaType = media.getMediaType()
        let networkMedia = try await fetchMedia(url: mediaURL, type: mediaType)

        await MainActor.run {
            storeMedia(data: networkMedia, for: media)
        }

        return networkMedia
    }

    func upload(media storedMedia: ParleyStoredMedia) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            messageRemoteService.upload(
                data: storedMedia.data,
                type: storedMedia.type,
                fileName: storedMedia.filename
            ) { [weak self] mediaResult in
                guard let self else { return }
                do {
                    let mediaResponse = try mediaResult.get()
                    
                    move(storedMedia, to: mediaResponse.media)
                    
                    continuation.resume(returning: mediaResponse.media)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func reset() {
        dataSource?.clear()
    }
}

// MARK: Privates
extension MediaRepository {

    private func createMediaURL(path: String) throws -> URL {
        if let mediaIdUrl = URL(string: path) {
            return mediaIdUrl
        } else {
            throw MediaRepositoryError.invalidRemoteURL
        }
    }

    private func fetchMedia(url: URL, type: ParleyMediaType) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            let remotePath = getRemoteFetchPath(url: url)
            messageRemoteService.findMedia(remotePath, type: type, result: { result in
                continuation.resume(with: result)
            })
        }
    }

    private func getRemoteFetchPath(url: URL) -> String {
        url.pathComponents.dropFirst().dropFirst().joined(separator: "/")
    }

    private func move(_ local: ParleyStoredMedia, to remoteId: String) {
        dataSource?.delete(id: local.id)
        let storedMedia = ParleyStoredMedia(filename: remoteId, data: local.data, type: local.type)
        store(media: storedMedia)
    }
    
    private func storeMedia(data: Data, for media: MediaObject) {
        guard let filePath = ParleyStoredMedia.FilePath.from(media: media) else { return }
        let storedMedia = ParleyStoredMedia(filename: filePath.name, data: data, type: filePath.type)
        store(media: storedMedia)
    }

    private func store(media: ParleyStoredMedia) {
        dataSource?.save(media: media)
    }
}

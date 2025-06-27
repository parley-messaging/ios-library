import Foundation

final actor MediaRepository {

    enum MediaRepositoryError: Error {
        case invalidRemoteURL
    }

    private(set) weak var dataSource: ParleyMediaDataSource?
    private var messageRemoteService: MessageRemoteService
    
    func set(dataSource: ParleyMediaDataSource?) {
        self.dataSource = dataSource
    }

    init(messageRemoteService: MessageRemoteService) {
        self.messageRemoteService = messageRemoteService
    }

    func store(media: MediaModel) async -> ParleyStoredMedia {
        let storedMedia = ParleyStoredMedia.from(media: media)
        await store(media: storedMedia)
        return storedMedia
    }

    func getStoredMedia(for media: MediaObject) async -> ParleyStoredMedia? {
        await dataSource?.media(id: media.id)
    }

    func getRemoteMedia(for media: MediaObject) async throws -> Data {
        let mediaURL = try createMediaURL(path: media.id)
        let mediaType = media.getMediaType()
        let networkMedia = try await fetchMedia(url: mediaURL, type: mediaType)

        await storeMedia(data: networkMedia, for: media)

        return networkMedia
    }

    func upload(media storedMedia: ParleyStoredMedia) async throws -> String {
        let mediaResult = await messageRemoteService.upload(
            data: storedMedia.data,
            type: storedMedia.type,
            fileName: storedMedia.filename
        )
        let mediaResponse = try mediaResult.get()
        await move(storedMedia, to: mediaResponse.media)
        return mediaResponse.media
    }

    func reset() async {
        await dataSource?.clear()
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
        let remotePath = getRemoteFetchPath(url: url)
        return try await messageRemoteService.findMedia(remotePath, type: type)
    }

    private func getRemoteFetchPath(url: URL) -> String {
        url.pathComponents.dropFirst().dropFirst().joined(separator: "/")
    }

    private func move(_ local: ParleyStoredMedia, to remoteId: String) async {
        await dataSource?.delete(id: local.id)
        let storedMedia = ParleyStoredMedia(filename: remoteId, data: local.data, type: local.type)
        await store(media: storedMedia)
    }

    private func storeMedia(data: Data, for media: MediaObject) async {
        guard let filePath = ParleyStoredMedia.FilePath.from(media: media) else { return }
        let storedMedia = ParleyStoredMedia(filename: filePath.name, data: data, type: filePath.type)
        await store(media: storedMedia)
    }

    private func store(media: ParleyStoredMedia) async {
        await dataSource?.save(media: media)
    }
}

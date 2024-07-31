import Foundation

protocol MediaLoaderProtocol {
    func load(media: MediaObject) async throws -> Data
    func reset() async
}

actor MediaLoader: MediaLoaderProtocol {

    enum MediaLoaderError: Error {
        case deinitialized
    }

    private let mediaRepository: MediaRepository
    private var mediaCache: [String: Data]
    private var requests: [String: Task<Data, Error>]

    init(mediaRepository: MediaRepository) {
        self.mediaRepository = mediaRepository
        mediaCache = [String: Data]()
        requests = [:]
    }

    func load(media: MediaObject) async throws -> Data {
        if let cachedMedia = mediaCache[media.id] {
            return cachedMedia
        } else if let storedMedia = mediaRepository.getStoredMedia(for: media) {
            mediaCache[media.id] = storedMedia.data
            return storedMedia.data
        } else {
            return try await fetchFromRemote(media: media)
        }
    }

    func reset() {
        mediaCache.removeAll()
        clearRequests()
    }
}

extension MediaLoader {

    private func fetchFromRemote(media: MediaObject) async throws -> Data {
        let request = requests[media.id] ?? makeRemoteMediaFetchTask(media: media)

        do {
            let displayModel = try await request.value
            mediaCache[media.id] = displayModel
            requests[media.id] = nil
            return displayModel
        } catch {
            requests[media.id] = nil
            throw error
        }
    }

    private func makeRemoteMediaFetchTask(media: MediaObject) -> Task<Data, Error> {
        let request = Task.detached { [weak self] in
            guard let self else { throw MediaLoaderError.deinitialized }
            return try await mediaRepository.getRemoteMedia(for: media)
        }

        requests[media.id] = request
        return request
    }

    private func clearRequests() {
        for (_, task) in requests {
            task.cancel()
        }
        requests.removeAll()
    }
}

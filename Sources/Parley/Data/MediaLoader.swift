import Foundation

protocol MediaLoaderProtocol {
    func load(media: MediaObject) async throws -> MediaDisplayModel
    func share(media: MediaObject) async throws -> URL
    func reset() async
}

actor MediaLoader: MediaLoaderProtocol {

    enum MediaLoaderError: Error {
        case unableToConvertImageData
        case unableToFindMedia
        case deinitialized
    }

    private let mediaRepository: MediaRepository
    private var mediaCache: [String: MediaDisplayModel]
    private var requests: [String: Task<MediaDisplayModel, Error>]

    init(mediaRepository: MediaRepository) {
        self.mediaRepository = mediaRepository
        mediaCache = [String: MediaDisplayModel]()
        requests = [:]
    }

    func load(media: MediaObject) async throws -> MediaDisplayModel {
        if let cachedImage = mediaCache[media.id] {
            return cachedImage
        } else if let storedImage = mediaRepository.getStoredImage(for: media) {
            let mediaDisplayModel = try handleResult(for: media, data: storedImage.data)
            mediaCache[media.id] = mediaDisplayModel
            return mediaDisplayModel
        } else {
            return try await fetchFromRemote(media: media)
        }
    }
    
    func share(media: MediaObject) async throws -> URL {
        guard let path = mediaRepository.getStoredPath(for: media) else {
            throw MediaLoaderError.unableToFindMedia
        }
        
        return path
    }

    func reset() {
        mediaCache.removeAll()
        clearRequests()
    }
}

extension MediaLoader {

    private func fetchFromRemote(media: MediaObject) async throws -> MediaDisplayModel {
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

    private func makeRemoteMediaFetchTask(media: MediaObject) -> Task<MediaDisplayModel, Error> {
        let request = Task.detached { [weak self] in
            guard let self else { throw MediaLoaderError.deinitialized }
            let networkMedia = try await mediaRepository.getRemoteMedia(for: media)
            return try await handleResult(for: media, data: networkMedia.data)
        }

        requests[media.id] = request
        return request
    }
    
    private func handleResult(for media: MediaObject, data: Data) throws -> MediaDisplayModel {
        let mediaDisplayModel: MediaDisplayModel
        if media.getMediaType().isImageType {
            guard let image = ImageDisplayModel(data: data, type: media.getMediaType()) else {
                throw MediaLoaderError.unableToConvertImageData
            }
            
            mediaDisplayModel = .image(model: image)
        } else {
            guard let path = mediaRepository.getStoredPath(for: media) else {
                throw MediaLoaderError.unableToFindMedia
            }
            
            mediaDisplayModel = .file(model: FileDisplayModel(location: path))
        }
        
        return mediaDisplayModel
    }

    private func clearRequests() {
        for (_, task) in requests {
            task.cancel()
        }
        requests.removeAll()
    }
}

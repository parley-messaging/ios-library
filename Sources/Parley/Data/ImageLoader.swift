import Foundation

protocol ImageLoaderProtocol {
    func load(id: String) async throws -> ImageDisplayModel
    func reset() async
}

actor ImageLoader: ImageLoaderProtocol {

    enum ImageLoaderError: Error {
        case unableToConvertImageData
        case deinitialized
    }

    private let imageRepository: ImageRepository
    private var imageCache: [String: ImageDisplayModel]
    private var requests: [String: Task<ImageDisplayModel, Error>]

    init(imageRepository: ImageRepository) {
        self.imageRepository = imageRepository
        imageCache = [String: ImageDisplayModel]()
        requests = [:]
    }

    func load(id: String) async throws -> ImageDisplayModel {
        if let cachedImage = imageCache[id] {
            return cachedImage
        } else if let storedImage = imageRepository.getStoredImage(for: id) {
            guard let image = ImageDisplayModel.from(stored: storedImage) else {
                throw ImageLoaderError.unableToConvertImageData
            }
            imageCache[id] = image
            return image
        } else {
            return try await fetchFromRemote(id: id)
        }
    }

    func reset() {
        imageCache.removeAll()
        clearRequests()
    }
}

extension ImageLoader {

    private func fetchFromRemote(id: String) async throws -> ImageDisplayModel {
        let request = requests[id] ?? makeRemoteImageFetchTask(id: id)

        do {
            let image = try await request.value
            imageCache[id] = image
            requests[id] = nil
            return image
        } catch {
            requests[id] = nil
            throw error
        }
    }

    private func makeRemoteImageFetchTask(id: String) -> Task<ImageDisplayModel, Error> {
        let request = Task.detached { [weak self] in
            guard let self else { throw ImageLoaderError.deinitialized }
            let networkImage = try await imageRepository.getRemoteImage(for: id)
            guard let image = ImageDisplayModel.from(remote: networkImage) else {
                throw ImageLoaderError.unableToConvertImageData
            }
            return image
        }

        requests[id] = request
        return request
    }

    private func clearRequests() {
        for (_, task) in requests {
            task.cancel()
        }
        requests.removeAll()
    }
}

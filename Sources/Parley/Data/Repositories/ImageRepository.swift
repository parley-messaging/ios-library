import Foundation

class ImageRepository {

    enum ImageRepositoryError: Error {
        case invalidRemoteURL
    }

    weak var dataSource: ParleyImageDataSource?
    private var messageRemoteService: MessageRemoteService

    init(messageRemoteService: MessageRemoteService) {
        self.messageRemoteService = messageRemoteService
    }

    func store(media: MediaModel) -> ParleyStoredImage {
        let image = ParleyStoredImage.from(media: media)
        store(image: image)
        return image
    }

    func getStoredImage(for imageId: ParleyStoredImage.ID) -> ParleyStoredImage? {
        if isLocalId(imageId: imageId) {
            return dataSource?.image(id: imageId)
        } else {
            guard let filePath = ParleyStoredImage.FilePath.create(path: imageId) else { return nil }
            return dataSource?.image(id: filePath.description)
        }
    }

    func getRemoteImage(for imageId: RemoteImage.ID) async throws -> ParleyImageNetworkModel {
        let mediaURL = try createMediaURL(path: imageId)
        let networkImage = try await fetchMedia(url: mediaURL)

        await MainActor.run {
            store(networkImage: networkImage, remotePath: imageId)
        }

        return networkImage
    }

    func upload(image storedImage: ParleyStoredImage) async throws -> RemoteImage {
        try await withCheckedThrowingContinuation { continuation in
            messageRemoteService.upload(
                imageData: storedImage.data,
                imageType: storedImage.type,
                fileName: storedImage.filename
            ) { [weak self] imageResult in
                guard let self else { return }
                do {
                    let mediaResponse = try imageResult.get()
                    let remoteImage = RemoteImage(id: mediaResponse.media, type: storedImage.type)

                    move(storedImage, to: remoteImage.id)

                    continuation.resume(returning: remoteImage)
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
extension ImageRepository {

    private func isLocalId(imageId: ParleyStoredImage.ID) -> Bool {
        guard let url = URL(string: imageId) else { return true }
        return url.pathComponents.count == 1
    }

    private func createMediaURL(path: String) throws -> URL {
        if let mediaIdUrl = URL(string: path) {
            return mediaIdUrl
        } else {
            throw ImageRepositoryError.invalidRemoteURL
        }
    }

    private func fetchMedia(url: URL) async throws -> ParleyImageNetworkModel {
        try await withCheckedThrowingContinuation { continuation in
            let remotePath = getRemoteFetchPath(url: url)
            messageRemoteService.findMedia(remotePath, result: { result in
                continuation.resume(with: result)
            })
        }
    }

    private func getRemoteFetchPath(url: URL) -> String {
        url.pathComponents.dropFirst().dropFirst().joined(separator: "/")
    }

    private func move(_ local: ParleyStoredImage, to remoteId: RemoteImage.ID) {
        guard
            let storedImage = dataSource?.image(id: local.id),
            let filePath = ParleyStoredImage.FilePath.create(path: remoteId) else { return }

        dataSource?.delete(id: storedImage.id)
        storeImage(data: storedImage.data, path: filePath)
    }

    private func store(networkImage: ParleyImageNetworkModel, remotePath: String) {
        guard let filePath = ParleyStoredImage.FilePath.create(path: remotePath) else { return }
        storeImage(data: networkImage.data, path: filePath)
    }

    private func storeImage(data: Data, path: ParleyStoredImage.FilePath) {
        store(image: ParleyStoredImage(filename: path.name, data: data, type: path.type))
    }

    private func store(image: ParleyStoredImage) {
        dataSource?.save(image: image)
    }
}

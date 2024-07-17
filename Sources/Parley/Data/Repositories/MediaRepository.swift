import Foundation

class MediaRepository {

    enum MediaRepositoryError: Error {
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
    
    func getStoredPath(for media: MediaObject) -> URL? {
        if media.getMediaType().isImageType {
            return nil
        } else {
            return ParleyFileManager.shared.path(for: media)
        }
    }
    
    func getStoredImage(for media: MediaObject) -> ParleyStoredImage? {
        if media.getMediaType().isImageType {
            return dataSource?.image(id: media.id)
        } else {
            guard let data = ParleyFileManager.shared.file(for: media),
                  let fileName = ParleyStoredImage.FilePath.from(media: media)?.fileName else {
                return nil
            }
            
            return ParleyStoredImage(filename: fileName, data: data, type: media.getMediaType())
        }
    }

    func getRemoteMedia(for media: MediaObject) async throws -> ParleyImageNetworkModel {
        let mediaURL = try createMediaURL(path: media.id)
        let networkImage = try await fetchMedia(url: mediaURL, type: media.getMediaType())

        await MainActor.run {
            if networkImage.type.isImageType {
                store(networkImage: networkImage, remotePath: media.id)
            } else {
                storeLocal(networkImage: networkImage, for: media)
            }
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
extension MediaRepository {

    private func isLocalId(imageId: ParleyStoredImage.ID) -> Bool {
        guard let url = URL(string: imageId) else { return true }
        return url.pathComponents.count == 1
    }

    private func createMediaURL(path: String) throws -> URL {
        if let mediaIdUrl = URL(string: path) {
            return mediaIdUrl
        } else {
            throw MediaRepositoryError.invalidRemoteURL
        }
    }

    private func fetchMedia(url: URL, type: ParleyImageType) async throws -> ParleyImageNetworkModel {
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

    private func move(_ local: ParleyStoredImage, to remoteId: RemoteImage.ID) {
        guard
            let storedImage = dataSource?.image(id: local.id),
            let filePath = ParleyStoredImage.FilePath.from(id: remoteId, type: storedImage.type) else { return }

        dataSource?.delete(id: storedImage.id)
        storeImage(data: storedImage.data, path: filePath)
    }
    
    private func storeLocal(networkImage: ParleyImageNetworkModel, for media: MediaObject) {
        ParleyFileManager.shared.save(fileData: networkImage.data, for: media)
    }

    private func store(networkImage: ParleyImageNetworkModel, remotePath: String) {
        guard let filePath = ParleyStoredImage.FilePath.from(id: remotePath, type: networkImage.type) else { return }
        storeImage(data: networkImage.data, path: filePath)
    }

    private func storeImage(data: Data, path: ParleyStoredImage.FilePath) {
        store(image: ParleyStoredImage(filename: path.name, data: data, type: path.type))
    }

    private func store(image: ParleyStoredImage) {
        dataSource?.save(image: image)
    }
}

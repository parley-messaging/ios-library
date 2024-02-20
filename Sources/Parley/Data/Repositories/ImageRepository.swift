import Foundation

class ImageRepository {
    
    enum ParleyImageRepositoryError: Error {
        case unableToConvertImageData
        case invalidRemoteURL
    }
    
    weak var dataSource: ParleyImageDataSource?
    private var messageRemoteService: MessageRemoteService
    private var imageCache: [String: ParleyImageDisplayModel]
    
    init(remote: ParleyRemote) {
        self.messageRemoteService = MessageRemoteService(remote: remote)
        self.imageCache = [String: ParleyImageDisplayModel]()
    }
    
    func add(image: ParleyLocalImage) {
        imageCache[image.id] = .from(local: image)
    }
    
    func getLocalImage(for imageId: ParleyLocalImage.ID) -> ParleyImageDisplayModel? {
        guard let image = dataSource?.image(id: imageId) else { return nil }
        return .from(local: image)
    }
    
    func getImage(for imageId: String, result: @escaping ((Result<ParleyImageDisplayModel, Error>) -> Void)) {
        if let data = getLocalImage(for: imageId) {
            result(.success(data))
        } else {
            getRemoteImage(for: imageId, result: result)
        }
    }
    
    func getRemoteImage(for imageId: RemoteImage.ID, result: @escaping ((Result<ParleyImageDisplayModel, Error>) -> Void)) {
        if let cachedImage = imageCache[imageId] {
            result(.success(cachedImage))
            return
        }
        
        guard let mediaIdUrl = URL(string: imageId) else {
            result(.failure(ParleyImageRepositoryError.invalidRemoteURL))
            return
        }
        
        let url = mediaIdUrl.pathComponents.dropFirst().dropFirst().joined(separator: "/")
        messageRemoteService.findMedia(url) { [weak self] imageResult in
            do {
                let image = try imageResult.get()
                guard let displayModel = ParleyImageDisplayModel.from(remote: image) else {
                    throw ParleyImageRepositoryError.unableToConvertImageData
                }
                self?.imageCache[imageId] = displayModel
                result(.success(displayModel))
            } catch {
                result(.failure(error))
            }
        }
    }
    
    func upload(image localImage: ParleyLocalImage, result: @escaping (Result<RemoteImage, Error>) -> Void) {
        messageRemoteService.upload(
            imageData: localImage.data,
            imageType: localImage.type,
            fileName: localImage.filename
        ) { [weak self] imageResult in
            do {
                let mediaResponse = try imageResult.get()
                let remoteImage = RemoteImage(id: mediaResponse.media, type: localImage.type)
                
                self?.moveCachedImage(from: localImage.id, to: remoteImage.id)
                
                result(.success(remoteImage))
            } catch {
                result(.failure(error))
            }
        }
    }
    
    func reset() {
        imageCache.removeAll()
    }
}

private extension ImageRepository {
    
    func moveCachedImage(from localImageId: ParleyLocalImage.ID, to remoteImageId: RemoteImage.ID) {
        if let image = imageCache[localImageId] {
            imageCache[localImageId] = nil
            imageCache[remoteImageId] = image
        }
    }
}

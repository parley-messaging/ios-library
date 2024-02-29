import Foundation

class ImageRepository {
    
    enum ImageRepositoryError: Error {
        case unableToConvertImageData
        case invalidRemoteURL
    }
    
    weak var dataSource: ParleyImageDataSource?
    private var messageRemoteService: MessageRemoteService
    private var imageCache: [String: ImageDisplayModel]
    
    init(remote: ParleyRemote) {
        self.messageRemoteService = MessageRemoteService(remote: remote)
        self.imageCache = [String: ImageDisplayModel]()
    }
    
    func store(image: ParleyStoredImage) {
        dataSource?.save(image: image)
    }
    
    func getStoredImage(for imageId: ParleyStoredImage.ID) -> ImageDisplayModel? {
        guard let image = dataSource?.image(id: imageId) else { return nil }
        return .from(stored: image)
    }
    
    func getImage(for imageId: String, result: @escaping ((Result<ImageDisplayModel, Error>) -> Void)) {
        if let data = getStoredImage(for: imageId) {
            result(.success(data))
        } else {
            getRemoteImage(for: imageId, result: result)
        }
    }
    
    func getRemoteImage(for imageId: RemoteImage.ID, result: @escaping ((Result<ImageDisplayModel, Error>) -> Void)) {
        if let cachedImage = imageCache[imageId] {
            result(.success(cachedImage))
            return
        }
        
        guard let mediaIdUrl = URL(string: imageId) else {
            result(.failure(ImageRepositoryError.invalidRemoteURL))
            return
        }
        
        let url = mediaIdUrl.pathComponents.dropFirst().dropFirst().joined(separator: "/")
        messageRemoteService.findMedia(url) { [weak self] imageResult in
            do {
                let image = try imageResult.get()
                guard let displayModel = ImageDisplayModel.from(remote: image) else {
                    throw ImageRepositoryError.unableToConvertImageData
                }
                self?.imageCache[imageId] = displayModel
                self?.dataSource?.save(image: ParleyStoredImage(id: imageId, data: image.data, type: image.type))
                result(.success(displayModel))
            } catch {
                result(.failure(error))
            }
        }
    }
    
    func upload(image storedImage: ParleyStoredImage, result: @escaping (Result<RemoteImage, Error>) -> Void) {
        messageRemoteService.upload(
            imageData: storedImage.data,
            imageType: storedImage.type,
            fileName: storedImage.filename
        ) { [weak self] imageResult in
            do {
                let mediaResponse = try imageResult.get()
                let remoteImage = RemoteImage(id: mediaResponse.media, type: storedImage.type)
                
                self?.move(storedImage, to: remoteImage.id)
                self?.imageCache[remoteImage.id] = .from(stored: storedImage)
                
                result(.success(remoteImage))
            } catch {
                result(.failure(error))
            }
        }
    }
    
    func reset() {
        imageCache.removeAll()
        dataSource?.clear()
    }
}

private extension ImageRepository {
    
    func move(_ local: ParleyStoredImage, to remoteId: RemoteImage.ID) {
        if let data = dataSource?.image(id: local.id) {
            dataSource?.delete(id: local.id)
            dataSource?.save(image: ParleyStoredImage(id: remoteId, data: local.data, type: local.type))
        }
    }
}

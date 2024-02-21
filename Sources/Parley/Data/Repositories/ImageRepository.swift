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
    
    func store(image: ParleyLocalImage) {
        dataSource?.save(image: image)
    }
    
    func getLocalImage(for imageId: ParleyLocalImage.ID) -> ImageDisplayModel? {
        guard let image = dataSource?.image(id: imageId) else { return nil }
        return .from(local: image)
    }
    
    func getImage(for imageId: String, result: @escaping ((Result<ImageDisplayModel, Error>) -> Void)) {
        if let data = getLocalImage(for: imageId) {
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
                
                self?.dataSource?.delete(id: localImage.id)
                self?.imageCache[remoteImage.id] = .from(local: localImage)
                
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

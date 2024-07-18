import Foundation

class ShareManager {
    
    enum ShareManagerError: Error {
        case unableToSaveFile(id: String)
    }
    
    private let fileManager: ParleyFileManager
    private let mediaLoader: MediaLoaderProtocol
    
    init(mediaLoader: MediaLoaderProtocol) throws {
        self.mediaLoader = mediaLoader
        self.fileManager = try ParleyFileManager()
    }
    
    func share(media: MediaObject) async throws -> URL {
        if fileManager.file(for: media) != nil, let url = fileManager.path(for: media) {
            return url
        }
        
        let data = try await mediaLoader.load(media: media)
        guard let url = fileManager.save(fileData: data, for: media) else {
            throw ShareManagerError.unableToSaveFile(id: media.id)
        }
        
        return url
    }
}

import Foundation

class ParleyFileManager {
    
    static var shared: ParleyFileManager = .init()
    
    private let fileManager: FileManager = .default
    private let destination: URL
    
    init() {
        do {
            destination = fileManager.temporaryDirectory.appendingPathComponent(kParleyCacheFilesDirectory)
            try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
        } catch {
            print("Failed to create storage directory: \(error)")
        }
    }
    
    func save(fileData: Data, for media: MediaObject) {
        guard let path = path(for: media) else {
            return
        }
        
        fileManager.createFile(atPath: path.path, contents: fileData)
    }
    
    func file(for media: MediaObject) -> Data? {
        guard let path = path(for: media) else {
            return nil
        }
        
        return fileManager.contents(atPath: path.path)
    }
    
    func path(for media: MediaObject) -> URL? {
        guard let fileName = ParleyStoredImage.FilePath.from(media: media)?.fileName else {
            return nil
        }
        
        return destination.appendingPathComponent(fileName)
    }
}

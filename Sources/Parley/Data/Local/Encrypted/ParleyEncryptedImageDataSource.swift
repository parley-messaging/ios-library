import Foundation

public class ParleyEncryptedImageDataSource {
    
    private let crypter: ParleyCrypter
    private let destination: URL
    private let fileManager: FileManager
    
    public init() throws {
        self.crypter = ParleyCrypter()
        self.fileManager = .default
        self.destination = fileManager.temporaryDirectory.appendingPathComponent(kParleyCacheImagesDirectory)
        try? fileManager.createDirectory(at: destination, withIntermediateDirectories: true, attributes: nil)
    }
}

extension ParleyEncryptedImageDataSource: ParleyImageDataSource {
    
    public func clear() -> Bool {
        do {
            for url in urls() {
                try fileManager.removeItem(at: url)
            }
            return true
        } catch {
            print(error)
            return false
        }
    }
    
    public func all() -> [ParleyStoredImage] {
        urls().compactMap(obtainLocalImage(from:))
    }
    
    public func image(id: ParleyStoredImage.ID) -> ParleyStoredImage? {
        guard let url = urls().first(where: { $0.lastPathComponent.contains(id) }) else { return nil }
        return obtainLocalImage(from: url)
    }
    
    private func obtainLocalImage(from url: URL) -> ParleyStoredImage? {
        guard
            let data = fileManager.contents(atPath: url.path),
            let decryptedData = try? crypter.decrypt(data)
        else { return nil }
        
        var splitFilename = url.lastPathComponent.split(separator: ".")
        let fileName = String(splitFilename.removeFirst())
        let type = String(splitFilename.removeLast())
        guard let imageType = ParleyImageType(rawValue: type) else { return nil }
        
        return ParleyStoredImage(id: fileName, data: decryptedData, type: imageType)
    }
    
    public func save(images: [ParleyStoredImage]) {
        for image in images {
            save(image: image)
        }
    }
    
    public func save(image: ParleyStoredImage) {
        let path = [image.id, image.type.fileExtension].joined()
        let absoluteURL = destination.appendingPathComponent(path)
        
        if let encryptedImageData = try? crypter.encrypt(image.data) {
            fileManager.createFile(atPath: absoluteURL.path, contents: encryptedImageData)
        }
    }
    
    public func delete(id: ParleyStoredImage.ID) -> Bool {
        guard let url = urls().first(where: { $0.lastPathComponent.contains(id) }) else {
            return false
        }
        
        do {
            try fileManager.removeItem(at: url)
            return true
        } catch {
            return false
        }
    }
}

private extension ParleyEncryptedImageDataSource {
    
    func urls() -> [URL] {
        guard let urls = try? fileManager.contentsOfDirectory(at: destination, includingPropertiesForKeys: [
            .isRegularFileKey
        ]) else { return [URL]() }

        return urls
    }
}

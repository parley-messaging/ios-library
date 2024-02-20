import Foundation
import UIKit

public class ParleyEncryptedImageDataSource {
    
    private let crypter: ParleyCrypter
    private let destination: URL
    private let fileManager: FileManager
    
    public init (key: Data) throws {
        self.crypter = try ParleyCrypter(key: key)
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
    
    public func all() -> [ParleyLocalImage] {
        let urls = urls()
        
        var images = [ParleyLocalImage]()
        images.reserveCapacity(urls.count)
        
        for url in urls {
            guard 
                let data = fileManager.contents(atPath: url.path),
                let decryptedData = try? crypter.decrypt(data)
            else { continue }
            
            var splitFilename = url.lastPathComponent.split(separator: ".")
            let fileName = String(splitFilename.removeFirst())
            let type = String(splitFilename.removeLast())
            guard let imageType = ParleyImageType(rawValue: type) else { continue }
            
            let localImage = ParleyLocalImage(id: fileName, data: decryptedData, type: imageType)
            images.append(localImage)
        }
        
        return images
    }
    
    public func image(id: ParleyLocalImage.ID) -> ParleyLocalImage? {
        let urls = urls()
        
        guard
            let url = urls.first(where: { $0.lastPathComponent.contains(id) }),
            let data = fileManager.contents(atPath: url.path)
        else { return nil }
        
        guard let decryptedImageData = try? crypter.decrypt(data) else { return nil }
        
        return ParleyLocalImage(id: id, data: decryptedImageData, type: .jpg)
    }
    
    public func save(images: [ParleyLocalImage]) {
        for image in images {
            save(image: image)
        }
    }
    
    public func save(image: ParleyLocalImage) {
        let path = [image.id, image.type.fileExtension].joined()
        let absoluteURL = destination.appendingPathComponent(path)
        
        if let encryptedImageData = try? crypter.encrypt(image.data) {
            fileManager.createFile(atPath: absoluteURL.path, contents: encryptedImageData)
        }
    }
    
    public func delete(id: ParleyLocalImage.ID) -> Bool {
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

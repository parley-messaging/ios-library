import Foundation

public class ParleyEncryptedImageDataSource {

    private let store: ParleyEncryptedStore

    public enum Directory {
        case `default`
        case custom(String)

        var path: String {
            switch self {
            case .default:
                kParleyCacheImagesDirectory
            case .custom(let string):
                string
            }
        }
    }

    public init(
        crypter: ParleyCrypter,
        directory: Directory = .default,
        fileManager: FileManager = .default
    ) throws {
        store = try ParleyEncryptedStore(
            crypter: crypter,
            directory: directory.path,
            fileManager: fileManager
        )
    }
}

extension ParleyEncryptedImageDataSource: ParleyImageDataSource {

    public func clear() -> Bool {
        do {
            for url in getFiles() {
                try store.fileManager.removeItem(at: url)
            }
            return true
        } catch {
            return false
        }
    }

    public func all() -> [ParleyStoredMedia] {
        getFiles().compactMap(obtainStoredImage(from:))
    }

    public func image(id: ParleyStoredMedia.ID) -> ParleyStoredMedia? {
        guard let url = path(id: id) else { return nil }
        return obtainStoredImage(from: url)
    }
    
    private func path(id: ParleyStoredMedia.ID) -> URL? {
        return getFiles().first(where: { $0.lastPathComponent.contains(id) })
    }

    private func obtainStoredImage(from url: URL) -> ParleyStoredMedia? {
        guard
            let decryptedData = getDecryptedStoredImageData(url: url),
            let filePath = ParleyStoredMedia.FilePath.from(url: url) else { return nil }
        
        return ParleyStoredMedia(filename: filePath.name, data: decryptedData, type: filePath.type)
    }

    private func getDecryptedStoredImageData(url: URL) -> Data? {
        guard let data = store.fileManager.contents(atPath: url.path) else { return nil }
        return try? store.crypter.decrypt(data)
    }

    public func save(images: [ParleyStoredMedia]) {
        for image in images {
            save(image: image)
        }
    }

    public func save(image: ParleyStoredMedia) {
        let path = ParleyStoredMedia.FilePath.from(image: image).fileName
        let absoluteURL = store.destination.appendingPathComponent(path)

        if let encryptedImageData = try? store.crypter.encrypt(image.data) {
            store.fileManager.createFile(atPath: absoluteURL.path, contents: encryptedImageData)
        }
    }

    public func delete(id: ParleyStoredMedia.ID) -> Bool {
        guard let url = findUrlForStoredImage(id: id) else { return false }
        return removeItem(at: url)
    }

    private func findUrlForStoredImage(id: ParleyStoredMedia.ID) -> URL? {
        getFiles().first(where: { $0.lastPathComponent.contains(id) })
    }

    private func removeItem(at url: URL) -> Bool {
        do {
            try store.fileManager.removeItem(at: url)
            return true
        } catch {
            return false
        }
    }
}

extension ParleyEncryptedImageDataSource {

    private func getFiles() -> [URL] {
        guard
            let urls = try? store.fileManager.contentsOfDirectory(at: store.destination, includingPropertiesForKeys: [
                .isRegularFileKey,
            ]) else { return [URL]() }

        return urls
    }
}

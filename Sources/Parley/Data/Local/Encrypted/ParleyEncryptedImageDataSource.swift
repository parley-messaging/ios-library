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

    public func all() -> [ParleyStoredImage] {
        getFiles().compactMap(obtainStoredImage(from:))
    }

    public func image(id: ParleyStoredImage.ID) -> ParleyStoredImage? {
        guard let url = getFiles().first(where: { $0.lastPathComponent.contains(id) }) else { return nil }
        return obtainStoredImage(from: url)
    }

    private func obtainStoredImage(from url: URL) -> ParleyStoredImage? {
        guard
            let decryptedData = getDecryptedStoredImageData(url: url),
            let file = ParleyStoredImage.FilePath.decode(url: url) else { return nil }

        return ParleyStoredImage(filename: file.name, data: decryptedData, type: file.type)
    }

    private func getDecryptedStoredImageData(url: URL) -> Data? {
        guard let data = store.fileManager.contents(atPath: url.path) else { return nil }
        return try? store.crypter.decrypt(data)
    }

    public func save(images: [ParleyStoredImage]) {
        for image in images {
            save(image: image)
        }
    }

    public func save(image: ParleyStoredImage) {
        let path = ParleyStoredImage.FilePath.create(image: image)
        let absoluteURL = store.destination.appendingPathComponent(path)

        if let encryptedImageData = try? store.crypter.encrypt(image.data) {
            store.fileManager.createFile(atPath: absoluteURL.path, contents: encryptedImageData)
        }
    }

    public func delete(id: ParleyStoredImage.ID) -> Bool {
        guard let url = findUrlForStoredImage(id: id) else { return false }
        return removeItem(at: url)
    }

    private func findUrlForStoredImage(id: ParleyStoredImage.ID) -> URL? {
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

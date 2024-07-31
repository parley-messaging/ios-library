import Foundation

@available(*, deprecated, renamed: "ParleyEncryptedMediaDataSource", message: "Use ParleyEncryptedMediaDataSource instead")
public typealias ParleyEncryptedImageDataSource = ParleyEncryptedMediaDataSource

public class ParleyEncryptedMediaDataSource {

    private let store: ParleyEncryptedStore

    public enum Directory {
        case `default`
        case custom(String)

        var path: String {
            switch self {
            case .default:
                kParleyCacheMediaDirectory
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

extension ParleyEncryptedMediaDataSource: ParleyMediaDataSource {

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
        getFiles().compactMap(obtainStoredMedia(from:))
    }

    public func media(id: ParleyStoredMedia.ID) -> ParleyStoredMedia? {
        guard let url = path(id: id) else { return nil }
        return obtainStoredMedia(from: url)
    }
    
    private func path(id: ParleyStoredMedia.ID) -> URL? {
        return getFiles().first(where: { $0.lastPathComponent.contains(id) })
    }

    private func obtainStoredMedia(from url: URL) -> ParleyStoredMedia? {
        guard
            let decryptedData = getDecryptedStoredMediaData(url: url),
            let filePath = ParleyStoredMedia.FilePath.from(url: url) else { return nil }
        
        return ParleyStoredMedia(filename: filePath.name, data: decryptedData, type: filePath.type)
    }

    private func getDecryptedStoredMediaData(url: URL) -> Data? {
        guard let data = store.fileManager.contents(atPath: url.path) else { return nil }
        return try? store.crypter.decrypt(data)
    }

    public func save(media: [ParleyStoredMedia]) {
        for medium in media {
            save(media: medium)
        }
    }

    public func save(media: ParleyStoredMedia) {
        let path = ParleyStoredMedia.FilePath.from(media: media).fileName
        let absoluteURL = store.destination.appendingPathComponent(path)

        if let encryptedMediaData = try? store.crypter.encrypt(media.data) {
            store.fileManager.createFile(atPath: absoluteURL.path, contents: encryptedMediaData)
        }
    }

    public func delete(id: ParleyStoredMedia.ID) -> Bool {
        guard let url = findUrlForStoredMedia(id: id) else { return false }
        return removeItem(at: url)
    }

    private func findUrlForStoredMedia(id: ParleyStoredMedia.ID) -> URL? {
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

extension ParleyEncryptedMediaDataSource {

    private func getFiles() -> [URL] {
        guard
            let urls = try? store.fileManager.contentsOfDirectory(at: store.destination, includingPropertiesForKeys: [
                .isRegularFileKey,
            ]) else { return [URL]() }

        return urls
    }
}

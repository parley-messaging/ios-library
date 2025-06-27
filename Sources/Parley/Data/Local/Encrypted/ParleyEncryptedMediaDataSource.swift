@preconcurrency import Foundation

@available(
    *,
    deprecated,
    renamed: "ParleyEncryptedMediaDataSource",
    message: "Use ParleyEncryptedMediaDataSource instead"
)
public typealias ParleyEncryptedImageDataSource = ParleyEncryptedMediaDataSource

public final class ParleyEncryptedMediaDataSource {

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

    public func clear() async -> Bool {
        do {
            for url in await getFiles() {
                try await store.removeItem(at: url)
            }
            return true
        } catch {
            return false
        }
    }

    public func all() async -> [ParleyStoredMedia] {
        var allMedia = [ParleyStoredMedia]()
        for file in await getFiles() {
            if let media = await obtainStoredMedia(from: file) {
                allMedia.append(media)
            }
        }
        return allMedia
    }

    public func media(id: ParleyStoredMedia.ID) async -> ParleyStoredMedia? {
        guard let url = await path(id: id) else { return nil }
        return await obtainStoredMedia(from: url)
    }

    private func path(id: ParleyStoredMedia.ID) async -> URL? {
        await getFiles().first(where: { $0.lastPathComponent.contains(id) })
    }

    private func obtainStoredMedia(from url: URL) async -> ParleyStoredMedia? {
        guard
            let decryptedData = await getDecryptedStoredMediaData(url: url),
            let filePath = ParleyStoredMedia.FilePath.from(url: url) else { return nil }

        return ParleyStoredMedia(filename: filePath.name, data: decryptedData, type: filePath.type)
    }

    private func getDecryptedStoredMediaData(url: URL) async -> Data? {
        guard let data = await store.contents(atPath: url.path) else { return nil }
        return try? store.crypter.decrypt(data)
    }

    public func save(media: [ParleyStoredMedia]) async {
        for medium in media {
            await save(media: medium)
        }
    }

    public func save(media: ParleyStoredMedia) async {
        let path = ParleyStoredMedia.FilePath.from(media: media).fileName
        let absoluteURL = store.destination.appendingPathComponent(path)

        if let encryptedMediaData = try? store.crypter.encrypt(media.data) {
            await store.createFile(atPath: absoluteURL.path, contents: encryptedMediaData)
        }
    }

    public func delete(id: ParleyStoredMedia.ID) async -> Bool {
        guard let url = await findUrlForStoredMedia(id: id) else { return false }
        return await removeItem(at: url)
    }

    private func findUrlForStoredMedia(id: ParleyStoredMedia.ID) async -> URL? {
        await getFiles().first(where: { $0.lastPathComponent.contains(id) })
    }

    private func removeItem(at url: URL) async -> Bool {
        do {
            try await store.removeItem(at: url)
            return true
        } catch {
            return false
        }
    }
}

extension ParleyEncryptedMediaDataSource {

    private func getFiles() async -> [URL] {
        guard
            let urls = try? await store.filesOfDirectory(at: store.destination)
        else { return [URL]() }

        return urls
    }
}

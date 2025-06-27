@preconcurrency import Foundation

public final actor ParleyEncryptedStore {

    let crypter: ParleyCrypter
    let destination: URL
    private let fileManager: FileManager

    public init(crypter: ParleyCrypter, directory: String, fileManager: FileManager) throws {
        self.crypter = crypter
        self.fileManager = fileManager
        destination = fileManager.temporaryDirectory.appendingPathComponent(directory)
        try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
    }
}

extension ParleyEncryptedStore {

    public func clear() -> Bool {
        do {
            try fileManager.removeItem(at: destination)
            try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)

            return true
        } catch {
            return false
        }
    }

    func string(forKey key: String) -> String? {
        guard let data = data(forKey: key) else { return nil }
        return String(decoding: data, as: UTF8.self)
    }

    func data(forKey key: String) -> Data? {
        let destination = destination(forKey: key)

        do {
            let encrypted = try Data(contentsOf: destination)
            return try crypter.decrypt(encrypted)
        } catch {
            return nil
        }
    }

    @discardableResult
    public func set(_ string: String, forKey key: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        return set(data, forKey: key)
    }

    public func set(_ data: Data, forKey key: String) -> Bool {
        let destination = destination(forKey: key)

        do {
            let encrypted = try crypter.encrypt(data)
            try encrypted.write(to: destination)

            return true
        } catch {
            return false
        }
    }

    @discardableResult
    public func removeObject(forKey key: String) -> Bool {
        let destination = destination(forKey: key)

        do {
            try fileManager.removeItem(at: destination)
            return true
        } catch {
            return false
        }
    }
    
    public func removeItem(at url: URL) throws {
        try fileManager.removeItem(at: url)
    }
    
    public func filesOfDirectory(at url: URL) throws -> [URL] {
        try fileManager.contentsOfDirectory(at: destination, includingPropertiesForKeys: [
            .isRegularFileKey
        ])
    }
    
    public func createFile(atPath path: String, contents: Data) {
        fileManager.createFile(atPath: path, contents: contents)
    }
    
    public func contents(atPath path: String) -> Data? {
        fileManager.contents(atPath: path)
    }
}

extension ParleyEncryptedStore {

    private func destination(forKey key: String) -> URL {
        destination.appendingPathComponent(key)
    }
}

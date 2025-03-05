@preconcurrency import CryptoKit
import Foundation

public final class ParleyCrypter: Sendable {

    enum ParleyCrypterError: Error {
        case failedToEncrypt
    }

    private let key: SymmetricKey

    public init(key: String, size: SymmetricKeySize = .bits128) throws {
        self.key = try SymmetricKey(key: key, size: size)
    }

    func encrypt(_ data: Data) throws -> Data {
        guard let encrypted = try AES.GCM.seal(data, using: key).combined else {
            throw ParleyCrypterError.failedToEncrypt
        }

        return encrypted
    }

    func decrypt(_ data: Data) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }
}

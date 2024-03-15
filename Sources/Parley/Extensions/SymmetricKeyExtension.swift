import Foundation
import CryptoKit

extension SymmetricKey {
    
    init(key: String, size: SymmetricKeySize = .bits128) throws {
        let keyData = try Self.getKeyData(key)
        try Self.checkSize(key: keyData, size)
        self.init(data: keyData)
    }
    
    private static func getKeyData(_ key: String) throws -> Data {
        guard let keyData = key.data(using: .utf8) else {
            print("Could not create base64 encoded Data from String.")
            throw CryptoKitError.incorrectParameterSize
        }
        return keyData
    }
    
    private static func checkSize(key: Data, _ size: SymmetricKeySize) throws {
        let sizeInBytes = size.bitCount / 8
        guard key.count >= sizeInBytes else {
            throw CryptoKitError.incorrectKeySize
        }
    }
}

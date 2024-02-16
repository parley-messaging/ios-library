import CommonCrypto
import Foundation
import Security

class ParleyCrypter {
    
    enum Error: Swift.Error {
        
        case cryptoFailed(status: CCCryptorStatus)
        case badKeyLength
        case badInitialisationVector
    }
    
    private var key: Data
    
    init(key: Data) throws {
        guard key.count == kCCKeySizeAES128 else {
            throw Error.badKeyLength
        }
        
        self.key = key
    }
    
    private func crypt(input: Data, iv: Data, operation: CCOperation) throws -> Data {
        guard iv.count == kCCKeySizeAES128 else {
            throw Error.badInitialisationVector
        }
        
        var outLength = Int(0)
        var outBytes = [UInt8](repeating: 0, count: input.count + kCCBlockSizeAES128)
        var status: CCCryptorStatus = CCCryptorStatus(kCCSuccess)
        input.withUnsafeBytes { (encryptedBytes: UnsafePointer<UInt8>!) -> () in
            iv.withUnsafeBytes { (ivBytes: UnsafePointer<UInt8>!) in
                key.withUnsafeBytes { (keyBytes: UnsafePointer<UInt8>!) -> () in
                    status = CCCrypt(operation,
                        CCAlgorithm(kCCAlgorithmAES128),            // algorithm
                        CCOptions(kCCOptionPKCS7Padding),           // options
                        keyBytes,                                   // key
                        key.count,                                  // keylength
                        ivBytes,                                    // iv
                        encryptedBytes,                             // dataIn
                        input.count,                                // dataInLength
                        &outBytes,                                  // dataOut
                        outBytes.count,                             // dataOutAvailable
                        &outLength)                                 // dataOutMoved
                }
            }
        }
        guard status == kCCSuccess else {
            throw Error.cryptoFailed(status: status)
        }
        return Data(bytes: UnsafePointer<UInt8>(outBytes), count: outLength)
    }
    
    func encrypt(_ data: Data) throws -> Data {
        let iv = ParleyCrypter.randomIV()
        
        var encrypted = try self.crypt(input: data, iv: iv, operation: CCOperation(kCCEncrypt))
        encrypted.append(iv)
        
        return encrypted
    }
    
    func decrypt(_ data: Data) throws -> Data {
        if data.count < kCCBlockSizeAES128 {
            throw Error.badInitialisationVector
        }
        
        let encrypted = data.subdata(in: Range(NSRange(location: 0, length: data.count - kCCBlockSizeAES128))!)
        let iv = data.subdata(in: Range(NSRange(location: data.count - kCCBlockSizeAES128, length: kCCBlockSizeAES128))!)
        
        return try self.crypt(input: encrypted, iv: iv, operation: CCOperation(kCCDecrypt))
    }
}

extension ParleyCrypter {
    
    private static func randomIV() -> Data {
        return random(length: kCCBlockSizeAES128)
    }
    
    private static func random(length: Int) -> Data {
        var data = Data(count: length)
        data.withUnsafeMutableBytes { mutableBytes in
            SecRandomCopyBytes(kSecRandomDefault, length, mutableBytes)
        }
        
        return data
    }
}

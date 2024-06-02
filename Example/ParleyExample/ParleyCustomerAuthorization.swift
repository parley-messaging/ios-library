import CommonCrypto
import Foundation

class ParleyCustomerAuthorization {

    /**
     Generation based on the documentation: https://developers.parley.nu/docs/authorization-header
     *NOTE*: It is important you generate the authHeader in a safe and secure location (not on a client device).
            This is intended as an example inside the demo app to show the use of registered customers in Parley.
            Especially the `sharedSecret` below should not exist anywhere on the client device.
     */
    @available(
        *,
        deprecated,
        message: "Always generate the user authorization for Parley on a safe and secure location (never on a client device). Use this method for test purposes only."
    )
    static func generate(identification: String, secret: String, sharedSecret: String) -> String {
        // 1. Customer authentication key
        let customerAuthenticationKey = hmac(identification, withKey: secret)

//        debugPrint("1: CustomerAuthenticationKey")
//        debugPrint("Identification: \(identification)")
//        debugPrint("Secret: \(secret)")
//        debugPrint("Result: \(customerAuthenticationKey)")

        // 2. Verify hash
        let validUntillTimestamp = Int(Date().timeIntervalSince1970 + 60 * 60 * 24 * 7)
        let validUntillTimestampString = String(format: "%lu", validUntillTimestamp)
        let verifyHashData = [identification, customerAuthenticationKey, validUntillTimestampString]
        let verifyHashDataString = verifyHashData.joined()
        let verifyHash = hmac(verifyHashDataString, withKey: sharedSecret)

//        debugPrint("2: VerifyHash")
//        debugPrint("Identification: \(identification)")
//        debugPrint("CustomerAuthenticationKey: \(customerAuthenticationKey)")
//        debugPrint("ValidUntill: \(validUntillTimestampString)")
//        debugPrint("Combined: \(verifyHashDataString)")
//        debugPrint("Secret: \(sharedSecret)")
//        debugPrint("Result: \(verifyHash)")

        // 3. Authentication key
        let authenticationEncodedDataArray = [
            identification,
            customerAuthenticationKey,
            validUntillTimestampString,
            verifyHash,
        ]
        let authenticationEncodedData = authenticationEncodedDataArray.joined(separator: "|")
        let authenticationEncodedString = authenticationEncodedData.data(using: .utf8)!
        let userAuthentication = authenticationEncodedString.base64EncodedString(options: .endLineWithCarriageReturn)

//        debugPrint("3: UserAuthentication")
//        debugPrint("Data: \(authenticationEncodedData)")
//        debugPrint("Result: \(userAuthentication)")

        return userAuthentication
    }

    private static func hmac(_ plainText: String, withKey key: String) -> String {
        let cKey = key.cString(using: .ascii)!
        let cData = plainText.cString(using: .ascii)!

        let cHMAC = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: Int(CC_SHA512_DIGEST_LENGTH))

        CCHmac(
            CCHmacAlgorithm(kCCHmacAlgSHA512),
            cKey,
            key.lengthOfBytes(using: .utf8),
            cData,
            plainText.lengthOfBytes(using: .utf8),
            cHMAC
        )

        var hmac = ""
        for i in 0..<Int(CC_SHA512_DIGEST_LENGTH) {
            hmac = hmac.appendingFormat("%02x", cHMAC[i])
        }

        return hmac
    }
}

import Foundation

public struct ParleyHTTPDataResponse: Sendable, ResponseValidator {

    public let statusCode: Int
    public let headers: [String: String]
    public let body: Data?

    public init(body: Data?, statusCode: Int, headers: [String: String]) {
        self.body = body
        self.statusCode = statusCode
        self.headers = headers
    }
}

import Foundation

public struct ParleyHTTPErrorResponse: Error {
    public let statusCode: Int?
    public let headers: [String: String]?
    public let data: Data?
    public let error: Error

    public init(
        statusCode: Int? = nil,
        headers: [String: String]? = nil,
        data: Data? = nil,
        error: Error
    ) {
        self.statusCode = statusCode
        self.headers = headers
        self.data = data
        self.error = error
    }

    var isOfflineError: Bool {
        statusCode == nil && headers == nil && data == nil
    }
}

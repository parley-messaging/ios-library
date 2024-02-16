import Foundation

public struct HTTPDataResponse: ResponseValidator {

    public let statusCode: Int
    public let headers: [String: String]
    public let body: Data?

    public init(body: Data?, statusCode: Int, headers: [String: String]) {
        self.body = body
        self.statusCode = statusCode
        self.headers = headers
    }

    func decodeAtKeyPath<T: Codable>(of type: T.Type, keyPath: ParleyResponseKeyPath?) throws -> T {
        guard let body else {
            throw HTTPResponseError.dataMissing
        }
        switch keyPath {
        case .data:
            return try CodableHelper.shared.decode(ParleyResponse<T>.self, from: body).data
        case nil:
            return try CodableHelper.shared.decode(T.self, from: body)
        }
    }
}

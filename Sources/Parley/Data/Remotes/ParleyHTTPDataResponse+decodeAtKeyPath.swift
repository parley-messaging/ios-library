import Foundation

extension ParleyHTTPDataResponse {

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

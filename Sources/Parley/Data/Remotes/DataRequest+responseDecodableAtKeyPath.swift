import Alamofire
import Foundation

extension DataRequest {

    enum KeyPath {
        case data, none
    }

    @discardableResult
    func responseDecodableAtKeyPath<T: Codable>(
        of type: T.Type = T.self,
        keyPath: KeyPath,
        onSuccess: @escaping (_ item: T) -> (), onFailure: @escaping (_ error: Error)->()
    ) -> Self {
        switch keyPath {
        case .data:
            responseDecodable(of: ParleyResponse<T>.self) { response in
                switch response.result {
                case .success(let responseData):
                    onSuccess(responseData.data)
                case .failure(let defaultError):
                    onFailure(Self.decodeError(for: response.data) ?? defaultError)
                }
            }
        case .none:
            responseDecodable(of: T.self) { response in
                switch response.result {
                case .success(let items):
                    onSuccess(items)
                case .failure(let defaultError):
                    onFailure(Self.decodeError(for: response.data) ?? defaultError)
                }
            }
        }
    }
    
    private static func decodeError(for responseData: Data?) -> Error? {
        guard let data = responseData else { return nil }
        return ParleyRemote.decodeBackendError(responseData: data)
    }
}

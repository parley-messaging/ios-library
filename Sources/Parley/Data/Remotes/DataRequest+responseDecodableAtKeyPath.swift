import Alamofire
import Foundation

extension DataRequest {

    enum KeyPath {
        case data
        case none
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
                case .failure(let error):
                    onFailure(error)
                }
            }
        case .none:
            responseDecodable(of: T.self) { response in
                switch response.result {
                case .success(let items):
                    onSuccess(items)
                case .failure(let error):
                    onFailure(error)
                }
            }
        }

    }

}

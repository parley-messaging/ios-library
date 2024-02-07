import Alamofire
import AlamofireImage
import Foundation
import Parley
import UIKit

public class AlamofireNetworkSession: ParleyNetworkSession {

    private let encoding = URLEncoding(boolEncoding: URLEncoding.BoolEncoding.literal)
    private let networkConfig: ParleyNetworkConfig
    private let session: Session

    public init(networkConfig: ParleyNetworkConfig) {
        self.networkConfig = networkConfig

        guard let host = URL(string: networkConfig.url)?.host else {
            fatalError("ParleyRemote: Invalid url")
        }

        let evaluators: [String: ServerTrustEvaluating] = [
            host: PublicKeysTrustEvaluator(),
        ]

        session = Session(
            configuration: URLSessionConfiguration.af.default,
            serverTrustManager: ServerTrustManager(evaluators: evaluators)
        )
    }

    public func request(
        _ url: URL,
        method: HTTPRequestMethod,
        parameters: [String : Any]?,
        headers: [String : String],
        completion: @escaping (Result<HTTPDataResponse, Error>) -> Void
    ) -> RequestCancelable {
        let dataRequest = session.request(
            url,
            method: Alamofire.HTTPMethod(method),
            parameters: parameters,
            encoding: encoding,
            headers: HTTPHeaders(headers)
        ).response { response in
            guard let statusCode = response.response?.statusCode else {
                completion(.failure(HTTPResponseError.dataMissing))
                return
            }
            switch response.result {
            case .success(let data):
                completion(.success(HTTPDataResponse(
                    body: data,
                    statusCode: statusCode,
                    headers: response.response?.headers.dictionary ?? [:]
                )))
            case .failure(let error):
                completion(.failure(error))
            }
        }

        return dataRequest
    }

    @discardableResult
    public func requestImage(
        _ url: URL,
        method: HTTPRequestMethod,
        parameters: [String: Any]?,
        headers: [String: String],
        completion: @escaping (_ result: Result<HTTPImageResponse, Error>) -> Void
    ) -> RequestCancelable {
        let dataRequest = session.request(
            url,
            method: Alamofire.HTTPMethod(method),
            parameters: parameters,
            encoding: encoding,
            headers: HTTPHeaders(headers)
        ).responseImage { responseImage in
            guard let statusCode = responseImage.response?.statusCode else {
                completion(.failure(HTTPResponseError.dataMissing))
                return
            }
            switch responseImage.result {
            case .success(let image):
                completion(.success(HTTPImageResponse(
                    body: responseImage.data,
                    image: image,
                    statusCode: statusCode,
                    headers: responseImage.response?.headers.dictionary ?? [:]
                )))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        return dataRequest
    }

    public func upload(
        data: Data,
        to url: URL,
        method: HTTPRequestMethod,
        headers: [String : String],
        completion: @escaping (Result<HTTPDataResponse, Error>) -> Void
    ) -> RequestCancelable {
        session.upload(data, to: url, method: Alamofire.HTTPMethod(method), headers: HTTPHeaders(headers))
            .response { response in
                guard let statusCode = response.response?.statusCode else {
                    completion(.failure(HTTPResponseError.dataMissing))
                    return
                }
                switch response.result {
                case .success(let data):
                    completion(.success(HTTPDataResponse(
                        body: data,
                        statusCode: statusCode,
                        headers: response.response?.headers.dictionary ?? [:]
                    )))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }

}

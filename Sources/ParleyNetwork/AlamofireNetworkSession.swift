import Alamofire
import AlamofireImage
import Foundation
import Parley
import UIKit

final class AlamofireNetworkSession: ParleyNetworkSession {

    private let networkConfig: ParleyNetworkConfig
    private let session: Session

    init(networkConfig: ParleyNetworkConfig) {
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

    func request(
        _ url: URL,
        data: Data?,
        method: ParleyHTTPRequestMethod,
        headers: [String: String],
        completion: @escaping (Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse>) -> Void
    ) -> ParleyRequestCancelable {
        var request = URLRequest(url: url)
        request.method = Alamofire.HTTPMethod(method)
        request.headers = HTTPHeaders(headers)
        request.httpBody = data

        let dataRequest = session.request(request).response { response in
            guard let statusCode = response.response?.statusCode else {
                completion(.failure(ParleyHTTPErrorResponse(error: HTTPResponseError.dataMissing)))
                return
            }
            switch response.result {
            case .success(let data):
                completion(.success(ParleyHTTPDataResponse(
                    body: data,
                    statusCode: statusCode,
                    headers: response.response?.headers.dictionary ?? [:]
                )))
            case .failure(let error):
                let headers = response.response?.headers.dictionary
                let responseError = ParleyHTTPErrorResponse(
                    statusCode: statusCode,
                    headers: headers,
                    data: response.data,
                    error: error
                )
                completion(.failure(responseError))
            }
        }

        return dataRequest
    }

    func upload(
        data: Data,
        to url: URL,
        method: ParleyHTTPRequestMethod,
        headers: [String: String],
        completion: @escaping (Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse>) -> Void
    ) -> ParleyRequestCancelable {
        session.upload(data, to: url, method: Alamofire.HTTPMethod(method), headers: HTTPHeaders(headers))
            .response { response in
                guard let statusCode = response.response?.statusCode else {
                    completion(.failure(ParleyHTTPErrorResponse(error: HTTPResponseError.dataMissing)))
                    return
                }
                switch response.result {
                case .success(let data):
                    completion(.success(ParleyHTTPDataResponse(
                        body: data,
                        statusCode: statusCode,
                        headers: response.response?.headers.dictionary ?? [:]
                    )))
                case .failure(let error):
                    let headers = response.response?.headers.dictionary
                    let responseError = ParleyHTTPErrorResponse(
                        statusCode: statusCode,
                        headers: headers,
                        data: response.data,
                        error: error
                    )
                    completion(.failure(responseError))
                }
            }
    }

}

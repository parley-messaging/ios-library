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

    func request(_ url: URL, data: Data?, method: ParleyHTTPRequestMethod, headers: [String: String]) async throws(ParleyHTTPErrorResponse) -> ParleyHTTPDataResponse {
        var request = URLRequest(url: url)
        request.method = Alamofire.HTTPMethod(method)
        request.headers = HTTPHeaders(headers)
        request.httpBody = data

        let response = await withCheckedContinuation { continuation in
            session.request(request).response { response in
                continuation.resume(returning: response)
            }
        }
        
        guard let statusCode = response.response?.statusCode else {
            throw ParleyHTTPErrorResponse(error: HTTPResponseError.dataMissing)
        }
        
        switch response.result {
        case .success(let data):
            return ParleyHTTPDataResponse(
                body: data,
                statusCode: statusCode,
                headers: response.response?.headers.dictionary ?? [:]
            )
        case .failure(let error):
            let headers = response.response?.headers.dictionary
            throw ParleyHTTPErrorResponse(
                statusCode: statusCode,
                headers: headers,
                data: response.data,
                error: error
            )
        }
    }
    
    func upload(data: Data, to url: URL, method: ParleyHTTPRequestMethod, headers: [String : String]) async throws(ParleyHTTPErrorResponse) -> ParleyHTTPDataResponse {
        let response = await withCheckedContinuation { continuation in
            session.upload(data, to: url, method: Alamofire.HTTPMethod(method), headers: HTTPHeaders(headers))
                .response { response in
                    continuation.resume(returning: response)
                }
        }
        
        guard let statusCode = response.response?.statusCode else {
            throw ParleyHTTPErrorResponse(error: HTTPResponseError.dataMissing)
        }
        
        switch response.result {
        case .success(let data):
            return ParleyHTTPDataResponse(
                body: data,
                statusCode: statusCode,
                headers: response.response?.headers.dictionary ?? [:]
            )
        case .failure(let error):
            let headers = response.response?.headers.dictionary
            throw ParleyHTTPErrorResponse(
                statusCode: statusCode,
                headers: headers,
                data: response.data,
                error: error
            )
        }
    }
}

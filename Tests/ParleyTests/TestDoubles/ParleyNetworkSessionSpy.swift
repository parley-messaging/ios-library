import Foundation
@testable import Parley

public final class ParleyNetworkSessionSpy: ParleyNetworkSession, @unchecked Sendable {

    public init() {}

    // MARK: - request

    public private(set) var requestDataMethodHeadersCompletionCallsCount = 0
    
    private var requestDataMethodHeadersResult: Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse>!

    public func request(
        _ url: URL,
        data: Data?,
        method: ParleyHTTPRequestMethod,
        headers: [String : String],
        completion: @escaping @Sendable (Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse>) -> Void
    ) {
        requestDataMethodHeadersCompletionCallsCount += 1
        completion(requestDataMethodHeadersResult)
    }

    // MARK: - upload

    public private(set) var uploadDataToMethodHeadersCompletionCallsCount = 0

    private var uploadDataMethodHeadersResult: Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse>!

    public func upload(
        data: Data,
        to url: URL,
        method: ParleyHTTPRequestMethod,
        headers: [String: String],
        completion: @escaping @Sendable (Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse>
    ) -> Void) {
        uploadDataToMethodHeadersCompletionCallsCount += 1
        completion(uploadDataMethodHeadersResult)
    }

}

// MARK: Setters
extension ParleyNetworkSessionSpy {
    
    func setRequestDataMethodHeadersResult(_ result: Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse>!) {
        self.requestDataMethodHeadersResult = result
    }
    
    func setUploadDataMethodHeadersResult(_ result: Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse>) {
        self.uploadDataMethodHeadersResult = result
    }
}

extension ParleyNetworkSessionSpy {
    
    public func request(
        _ url: URL,
        data: Data?,
        method: ParleyHTTPRequestMethod,
        headers: [String: String],
        completion: @escaping @Sendable (Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse>
    ) -> Void) {
        Task {
            completion(await request(url, data: data, method: method, headers: headers))
        }
    }
    
    
    public func upload(
        data: Data,
        to url: URL,
        method: ParleyHTTPRequestMethod,
        headers: [String: String],
        completion: @escaping @Sendable (Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse>
    ) -> Void) {
        Task {
            completion(await upload(data: data, to: url, method: method, headers: headers))
        }
    }
}

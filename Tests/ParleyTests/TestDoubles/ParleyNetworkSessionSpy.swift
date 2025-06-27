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
    ) async throws(ParleyHTTPErrorResponse) -> ParleyHTTPDataResponse {
        requestDataMethodHeadersCompletionCallsCount += 1
        switch requestDataMethodHeadersResult! {
        case .success(let data):
            return data
        case .failure(let error):
            throw error
        }
    }

    // MARK: - upload

    public private(set) var uploadDataToMethodHeadersCompletionCallsCount = 0

    private var uploadDataMethodHeadersResult: Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse>!

    public func upload(
        data: Data,
        to url: URL,
        method: ParleyHTTPRequestMethod,
        headers: [String: String]
    ) async throws(ParleyHTTPErrorResponse) -> ParleyHTTPDataResponse {
        uploadDataToMethodHeadersCompletionCallsCount += 1
        switch uploadDataMethodHeadersResult! {
        case .success(let data):
            return data
        case .failure(let error):
            throw error
        }
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

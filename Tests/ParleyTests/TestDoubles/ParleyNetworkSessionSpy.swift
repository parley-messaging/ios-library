import Foundation
@testable import Parley

public final actor ParleyNetworkSessionSpy: ParleyNetworkSession {

    public init() {}

    // MARK: - request

    public private(set) var requestDataMethodHeadersCompletionCallsCount = 0
    public var requestDataMethodHeadersCompletionCalled: Bool {
        requestDataMethodHeadersCompletionCallsCount > 0
    }
    
    private var requestDataMethodHeadersResult: Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse>!

    public func request(
        _ url: URL,
        data: Data?,
        method: ParleyHTTPRequestMethod,
        headers: [String: String]
    ) async -> Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse>  {
        requestDataMethodHeadersCompletionCallsCount += 1
        
        return requestDataMethodHeadersResult
    }

    // MARK: - upload

    public private(set) var uploadDataToMethodHeadersCompletionCallsCount = 0
    public var uploadDataToMethodHeadersCompletionCalled: Bool {
        uploadDataToMethodHeadersCompletionCallsCount > 0
    }

    private var uploadDataMethodHeadersResult: Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse>!

    public func upload(
        data: Data,
        to url: URL,
        method: ParleyHTTPRequestMethod,
        headers: [String: String]
    ) async -> Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse> {
        uploadDataToMethodHeadersCompletionCallsCount += 1
        return uploadDataMethodHeadersResult
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

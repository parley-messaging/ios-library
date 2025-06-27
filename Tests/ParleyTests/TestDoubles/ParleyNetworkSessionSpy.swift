import Foundation
@testable import Parley

public final class ParleyNetworkSessionSpy: ParleyNetworkSession {

    public init() {}

    // MARK: - request

    public var requestDataMethodHeadersCompletionCallsCount = 0
    public var requestDataMethodHeadersCompletionCalled: Bool {
        requestDataMethodHeadersCompletionCallsCount > 0
    }

    public var requestDataMethodHeadersCompletionReceivedArguments: (
        url: URL,
        data: Data?,
        method: ParleyHTTPRequestMethod,
        headers: [String: String]
    )?
    public var requestDataMethodHeadersCompletionReceivedInvocations: [(
        url: URL,
        data: Data?,
        method: ParleyHTTPRequestMethod,
        headers: [String: String]
    )] = []
    
    public var requestDataMethodHeadersResult: Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse>!

    public func request(
        _ url: URL,
        data: Data?,
        method: ParleyHTTPRequestMethod,
        headers: [String: String]
    ) async -> Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse>  {
        requestDataMethodHeadersCompletionCallsCount += 1
        requestDataMethodHeadersCompletionReceivedArguments = (
            url: url,
            data: data,
            method: method,
            headers: headers
        )
        requestDataMethodHeadersCompletionReceivedInvocations.append((
            url: url,
            data: data,
            method: method,
            headers: headers
        ))
        
        return requestDataMethodHeadersResult
    }

    // MARK: - upload

    public var uploadDataToMethodHeadersCompletionCallsCount = 0
    public var uploadDataToMethodHeadersCompletionCalled: Bool {
        uploadDataToMethodHeadersCompletionCallsCount > 0
    }

    public var uploadDataToMethodHeadersCompletionReceivedArguments: (
        data: Data,
        url: URL,
        method: ParleyHTTPRequestMethod,
        headers: [String: String]
    )?
    public var uploadDataToMethodHeadersCompletionReceivedInvocations: [(
        data: Data,
        url: URL,
        method: ParleyHTTPRequestMethod,
        headers: [String: String]
    )] = []
    public var uploadDataToMethodHeadersCompletionClosure: ((
        Data,
        URL,
        ParleyHTTPRequestMethod,
        [String: String]
    ) -> Void)?
    public var uploadDataMethodHeadersResult: Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse>!

    public func upload(
        data: Data,
        to url: URL,
        method: ParleyHTTPRequestMethod,
        headers: [String: String]
    ) async -> Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse> {
        uploadDataToMethodHeadersCompletionCallsCount += 1
        uploadDataToMethodHeadersCompletionReceivedArguments = (
            data: data,
            url: url,
            method: method,
            headers: headers
        )
        uploadDataToMethodHeadersCompletionReceivedInvocations.append((
            data: data,
            url: url,
            method: method,
            headers: headers
        ))
        uploadDataToMethodHeadersCompletionClosure?(data, url, method, headers)
        
        return uploadDataMethodHeadersResult
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

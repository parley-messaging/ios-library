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
        headers: [String: String],
        completion: (_ result: Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse>) -> Void
    )?
    public var requestDataMethodHeadersCompletionReceivedInvocations: [(
        url: URL,
        data: Data?,
        method: ParleyHTTPRequestMethod,
        headers: [String: String],
        completion: (_ result: Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse>) -> Void
    )] = []
    public var requestDataMethodHeadersCompletionClosure: ((
        URL,
        Data?,
        ParleyHTTPRequestMethod,
        [String: String],
        @escaping (_ result: Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse>) -> Void
    ) -> Void)?

    public func request(
        _ url: URL,
        data: Data?,
        method: ParleyHTTPRequestMethod,
        headers: [String: String],
        completion: @escaping (_ result: Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse>) -> Void
    ) {
        requestDataMethodHeadersCompletionCallsCount += 1
        requestDataMethodHeadersCompletionReceivedArguments = (
            url: url,
            data: data,
            method: method,
            headers: headers,
            completion: completion
        )
        requestDataMethodHeadersCompletionReceivedInvocations.append((
            url: url,
            data: data,
            method: method,
            headers: headers,
            completion: completion
        ))
        requestDataMethodHeadersCompletionClosure?(url, data, method, headers, completion)
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
        headers: [String: String],
        completion: (_ result: Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse>) -> Void
    )?
    public var uploadDataToMethodHeadersCompletionReceivedInvocations: [(
        data: Data,
        url: URL,
        method: ParleyHTTPRequestMethod,
        headers: [String: String],
        completion: (_ result: Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse>) -> Void
    )] = []
    public var uploadDataToMethodHeadersCompletionClosure: ((
        Data,
        URL,
        ParleyHTTPRequestMethod,
        [String: String],
        @escaping (_ result: Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse>) -> Void
    ) -> Void)?

    public func upload(
        data: Data,
        to url: URL,
        method: ParleyHTTPRequestMethod,
        headers: [String: String],
        completion: @escaping (_ result: Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse>) -> Void
    ) {
        uploadDataToMethodHeadersCompletionCallsCount += 1
        uploadDataToMethodHeadersCompletionReceivedArguments = (
            data: data,
            url: url,
            method: method,
            headers: headers,
            completion: completion
        )
        uploadDataToMethodHeadersCompletionReceivedInvocations.append((
            data: data,
            url: url,
            method: method,
            headers: headers,
            completion: completion
        ))
        uploadDataToMethodHeadersCompletionClosure?(data, url, method, headers, completion)
    }

}

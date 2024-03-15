import Foundation
@testable import Parley

public final class ParleyNetworkSessionSpy: ParleyNetworkSession {

    public init(
        requestMethodParametersHeadersCompletionReturnValue: ParleyRequestCancelable? = nil,
        uploadDataToMethodHeadersCompletionReturnValue: ParleyRequestCancelable? = nil,
        uploadDataToMethodHeadersReturnValue: ParleyRequestCancelable? = nil
    ) {
        self.requestMethodParametersHeadersCompletionReturnValue = requestMethodParametersHeadersCompletionReturnValue
        self.uploadDataToMethodHeadersCompletionReturnValue = uploadDataToMethodHeadersCompletionReturnValue
        self.uploadDataToMethodHeadersReturnValue = uploadDataToMethodHeadersReturnValue
    }

    // MARK: - request

    public var requestMethodParametersHeadersCompletionCallsCount = 0
    public var requestMethodParametersHeadersCompletionCalled: Bool {
        return requestMethodParametersHeadersCompletionCallsCount > 0
    }
    public var requestMethodParametersHeadersCompletionReceivedArguments: (url: URL, method: ParleyHTTPRequestMethod, parameters: [String: Any]?, headers: [String: String], completion: (_ result: Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse>) -> Void)?
    public var requestMethodParametersHeadersCompletionReceivedInvocations: [(url: URL, method: ParleyHTTPRequestMethod, parameters: [String: Any]?, headers: [String: String], completion: (_ result: Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse>) -> Void)] = []
    public var requestMethodParametersHeadersCompletionReturnValue: ParleyRequestCancelable!
    public var requestMethodParametersHeadersCompletionClosure: ((URL, ParleyHTTPRequestMethod, [String: Any]?, [String: String], @escaping (_ result: Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse>) -> Void) -> ParleyRequestCancelable)?

    @discardableResult
    public func request(_ url: URL, method: ParleyHTTPRequestMethod, parameters: [String: Any]?, headers: [String: String], completion: @escaping (_ result: Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse>) -> Void) -> ParleyRequestCancelable {
        requestMethodParametersHeadersCompletionCallsCount += 1
        requestMethodParametersHeadersCompletionReceivedArguments = (url: url, method: method, parameters: parameters, headers: headers, completion: completion)
        requestMethodParametersHeadersCompletionReceivedInvocations.append((url: url, method: method, parameters: parameters, headers: headers, completion: completion))
        if let requestMethodParametersHeadersCompletionClosure = requestMethodParametersHeadersCompletionClosure {
            return requestMethodParametersHeadersCompletionClosure(url, method, parameters, headers, completion)
        } else {
            return requestMethodParametersHeadersCompletionReturnValue
        }
    }
    // MARK: - upload

    public var uploadDataToMethodHeadersCompletionCallsCount = 0
    public var uploadDataToMethodHeadersCompletionCalled: Bool {
        return uploadDataToMethodHeadersCompletionCallsCount > 0
    }
    public var uploadDataToMethodHeadersCompletionReceivedArguments: (data: Data, url: URL, method: ParleyHTTPRequestMethod, headers: [String: String], completion: (_ result: Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse>) -> Void)?
    public var uploadDataToMethodHeadersCompletionReceivedInvocations: [(data: Data, url: URL, method: ParleyHTTPRequestMethod, headers: [String: String], completion: (_ result: Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse>) -> Void)] = []
    public var uploadDataToMethodHeadersCompletionReturnValue: ParleyRequestCancelable!
    public var uploadDataToMethodHeadersCompletionClosure: ((Data, URL, ParleyHTTPRequestMethod, [String: String], @escaping (_ result: Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse>) -> Void) -> ParleyRequestCancelable)?

    @discardableResult
    public func upload(data: Data, to url: URL, method: ParleyHTTPRequestMethod, headers: [String: String], completion: @escaping (_ result: Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse>) -> Void) -> ParleyRequestCancelable {
        uploadDataToMethodHeadersCompletionCallsCount += 1
        uploadDataToMethodHeadersCompletionReceivedArguments = (data: data, url: url, method: method, headers: headers, completion: completion)
        uploadDataToMethodHeadersCompletionReceivedInvocations.append((data: data, url: url, method: method, headers: headers, completion: completion))
        if let uploadDataToMethodHeadersCompletionClosure = uploadDataToMethodHeadersCompletionClosure {
            return uploadDataToMethodHeadersCompletionClosure(data, url, method, headers, completion)
        } else {
            return uploadDataToMethodHeadersCompletionReturnValue
        }
    }

    // MARK: - upload

    public var uploadDataToMethodHeadersCallsCount = 0
    public var uploadDataToMethodHeadersCalled: Bool {
        return uploadDataToMethodHeadersCallsCount > 0
    }
    public var uploadDataToMethodHeadersReceivedArguments: (data: Data, url: URL, method: ParleyHTTPRequestMethod, headers: [String: String])?
    public var uploadDataToMethodHeadersReceivedInvocations: [(data: Data, url: URL, method: ParleyHTTPRequestMethod, headers: [String: String])] = []
    public var uploadDataToMethodHeadersReturnValue: ParleyRequestCancelable!
    public var uploadDataToMethodHeadersClosure: ((Data, URL, ParleyHTTPRequestMethod, [String: String]) -> ParleyRequestCancelable)?

    @discardableResult
    public func upload(data: Data, to url: URL, method: ParleyHTTPRequestMethod, headers: [String: String]) -> ParleyRequestCancelable {
        uploadDataToMethodHeadersCallsCount += 1
        uploadDataToMethodHeadersReceivedArguments = (data: data, url: url, method: method, headers: headers)
        uploadDataToMethodHeadersReceivedInvocations.append((data: data, url: url, method: method, headers: headers))
        if let uploadDataToMethodHeadersClosure = uploadDataToMethodHeadersClosure {
            return uploadDataToMethodHeadersClosure(data, url, method, headers)
        } else {
            return uploadDataToMethodHeadersReturnValue
        }
    }

}

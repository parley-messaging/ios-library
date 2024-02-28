import Foundation
@testable import Parley

public final class ParleyNetworkSessionSpy: ParleyNetworkSession {

    public init(
        requestMethodParametersHeadersCompletionReturnValue: RequestCancelable? = nil,
        uploadDataToMethodHeadersCompletionReturnValue: RequestCancelable? = nil,
        uploadDataToMethodHeadersReturnValue: RequestCancelable? = nil
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
    public var requestMethodParametersHeadersCompletionReceivedArguments: (url: URL, method: HTTPRequestMethod, parameters: [String: Any]?, headers: [String: String], completion: (_ result: Result<HTTPDataResponse, HTTPErrorResponse>) -> Void)?
    public var requestMethodParametersHeadersCompletionReceivedInvocations: [(url: URL, method: HTTPRequestMethod, parameters: [String: Any]?, headers: [String: String], completion: (_ result: Result<HTTPDataResponse, HTTPErrorResponse>) -> Void)] = []
    public var requestMethodParametersHeadersCompletionReturnValue: RequestCancelable!
    public var requestMethodParametersHeadersCompletionClosure: ((URL, HTTPRequestMethod, [String: Any]?, [String: String], @escaping (_ result: Result<HTTPDataResponse, HTTPErrorResponse>) -> Void) -> RequestCancelable)?

    @discardableResult
    public func request(_ url: URL, method: HTTPRequestMethod, parameters: [String: Any]?, headers: [String: String], completion: @escaping (_ result: Result<HTTPDataResponse, HTTPErrorResponse>) -> Void) -> RequestCancelable {
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
    public var uploadDataToMethodHeadersCompletionReceivedArguments: (data: Data, url: URL, method: HTTPRequestMethod, headers: [String: String], completion: (_ result: Result<HTTPDataResponse, HTTPErrorResponse>) -> Void)?
    public var uploadDataToMethodHeadersCompletionReceivedInvocations: [(data: Data, url: URL, method: HTTPRequestMethod, headers: [String: String], completion: (_ result: Result<HTTPDataResponse, HTTPErrorResponse>) -> Void)] = []
    public var uploadDataToMethodHeadersCompletionReturnValue: RequestCancelable!
    public var uploadDataToMethodHeadersCompletionClosure: ((Data, URL, HTTPRequestMethod, [String: String], @escaping (_ result: Result<HTTPDataResponse, HTTPErrorResponse>) -> Void) -> RequestCancelable)?

    @discardableResult
    public func upload(data: Data, to url: URL, method: HTTPRequestMethod, headers: [String: String], completion: @escaping (_ result: Result<HTTPDataResponse, HTTPErrorResponse>) -> Void) -> RequestCancelable {
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
    public var uploadDataToMethodHeadersReceivedArguments: (data: Data, url: URL, method: HTTPRequestMethod, headers: [String: String])?
    public var uploadDataToMethodHeadersReceivedInvocations: [(data: Data, url: URL, method: HTTPRequestMethod, headers: [String: String])] = []
    public var uploadDataToMethodHeadersReturnValue: RequestCancelable!
    public var uploadDataToMethodHeadersClosure: ((Data, URL, HTTPRequestMethod, [String: String]) -> RequestCancelable)?

    @discardableResult
    public func upload(data: Data, to url: URL, method: HTTPRequestMethod, headers: [String: String]) -> RequestCancelable {
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

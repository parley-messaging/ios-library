import Foundation
@testable import Parley

public final class ParleyNetworkSessionSpy: ParleyNetworkSession {

    public init(
        requestMethodParametersHeadersCompletionReturnValue: RequestCancelable? = nil,
        requestImageMethodParametersHeadersCompletionReturnValue: RequestCancelable? = nil,
        uploadDataToMethodHeadersCompletionReturnValue: RequestCancelable? = nil,
        uploadDataToMethodHeadersReturnValue: RequestCancelable? = nil
    ) {
        self.requestMethodParametersHeadersCompletionReturnValue = requestMethodParametersHeadersCompletionReturnValue
        self.requestImageMethodParametersHeadersCompletionReturnValue = requestImageMethodParametersHeadersCompletionReturnValue
        self.uploadDataToMethodHeadersCompletionReturnValue = uploadDataToMethodHeadersCompletionReturnValue
        self.uploadDataToMethodHeadersReturnValue = uploadDataToMethodHeadersReturnValue
    }

    // MARK: - request

    public var requestMethodParametersHeadersCompletionCallsCount = 0
    public var requestMethodParametersHeadersCompletionCalled: Bool {
        return requestMethodParametersHeadersCompletionCallsCount > 0
    }
    public var requestMethodParametersHeadersCompletionReceivedArguments: (url: URL, method: HTTPRequestMethod, parameters: [String: Any]?, headers: [String: String], completion: (_ result: Result<HTTPDataResponse, Error>) -> Void)?
    public var requestMethodParametersHeadersCompletionReceivedInvocations: [(url: URL, method: HTTPRequestMethod, parameters: [String: Any]?, headers: [String: String], completion: (_ result: Result<HTTPDataResponse, Error>) -> Void)] = []
    public var requestMethodParametersHeadersCompletionReturnValue: RequestCancelable!
    public var requestMethodParametersHeadersCompletionClosure: ((URL, HTTPRequestMethod, [String: Any]?, [String: String], @escaping (_ result: Result<HTTPDataResponse, Error>) -> Void) -> RequestCancelable)?

    @discardableResult
    public func request(_ url: URL, method: HTTPRequestMethod, parameters: [String: Any]?, headers: [String: String], completion: @escaping (_ result: Result<HTTPDataResponse, Error>) -> Void) -> RequestCancelable {
        requestMethodParametersHeadersCompletionCallsCount += 1
        requestMethodParametersHeadersCompletionReceivedArguments = (url: url, method: method, parameters: parameters, headers: headers, completion: completion)
        requestMethodParametersHeadersCompletionReceivedInvocations.append((url: url, method: method, parameters: parameters, headers: headers, completion: completion))
        if let requestMethodParametersHeadersCompletionClosure = requestMethodParametersHeadersCompletionClosure {
            return requestMethodParametersHeadersCompletionClosure(url, method, parameters, headers, completion)
        } else {
            return requestMethodParametersHeadersCompletionReturnValue
        }
    }

    // MARK: - requestImage

    public var requestImageMethodParametersHeadersCompletionCallsCount = 0
    public var requestImageMethodParametersHeadersCompletionCalled: Bool {
        return requestImageMethodParametersHeadersCompletionCallsCount > 0
    }
    public var requestImageMethodParametersHeadersCompletionReceivedArguments: (url: URL, method: HTTPRequestMethod, parameters: [String: Any]?, headers: [String: String], completion: (_ result: Result<HTTPImageResponse, Error>) -> Void)?
    public var requestImageMethodParametersHeadersCompletionReceivedInvocations: [(url: URL, method: HTTPRequestMethod, parameters: [String: Any]?, headers: [String: String], completion: (_ result: Result<HTTPImageResponse, Error>) -> Void)] = []
    public var requestImageMethodParametersHeadersCompletionReturnValue: RequestCancelable!
    public var requestImageMethodParametersHeadersCompletionClosure: ((URL, HTTPRequestMethod, [String: Any]?, [String: String], @escaping (_ result: Result<HTTPImageResponse, Error>) -> Void) -> RequestCancelable)?

    @discardableResult
    public func requestImage(_ url: URL, method: HTTPRequestMethod, parameters: [String: Any]?, headers: [String: String], completion: @escaping (_ result: Result<HTTPImageResponse, Error>) -> Void) -> RequestCancelable {
        requestImageMethodParametersHeadersCompletionCallsCount += 1
        requestImageMethodParametersHeadersCompletionReceivedArguments = (url: url, method: method, parameters: parameters, headers: headers, completion: completion)
        requestImageMethodParametersHeadersCompletionReceivedInvocations.append((url: url, method: method, parameters: parameters, headers: headers, completion: completion))
        if let requestImageMethodParametersHeadersCompletionClosure = requestImageMethodParametersHeadersCompletionClosure {
            return requestImageMethodParametersHeadersCompletionClosure(url, method, parameters, headers, completion)
        } else {
            return requestImageMethodParametersHeadersCompletionReturnValue
        }
    }

    // MARK: - upload

    public var uploadDataToMethodHeadersCompletionCallsCount = 0
    public var uploadDataToMethodHeadersCompletionCalled: Bool {
        return uploadDataToMethodHeadersCompletionCallsCount > 0
    }
    public var uploadDataToMethodHeadersCompletionReceivedArguments: (data: Data, url: URL, method: HTTPRequestMethod, headers: [String: String], completion: (_ result: Result<HTTPDataResponse, Error>) -> Void)?
    public var uploadDataToMethodHeadersCompletionReceivedInvocations: [(data: Data, url: URL, method: HTTPRequestMethod, headers: [String: String], completion: (_ result: Result<HTTPDataResponse, Error>) -> Void)] = []
    public var uploadDataToMethodHeadersCompletionReturnValue: RequestCancelable!
    public var uploadDataToMethodHeadersCompletionClosure: ((Data, URL, HTTPRequestMethod, [String: String], @escaping (_ result: Result<HTTPDataResponse, Error>) -> Void) -> RequestCancelable)?

    @discardableResult
    public func upload(data: Data, to url: URL, method: HTTPRequestMethod, headers: [String: String], completion: @escaping (_ result: Result<HTTPDataResponse, Error>) -> Void) -> RequestCancelable {
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

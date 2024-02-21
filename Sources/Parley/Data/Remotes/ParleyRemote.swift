import Foundation
import UIKit

final class ParleyRemote {

    let networkSession: ParleyNetworkSession
    private var networkConfig: ParleyNetworkConfig
    private weak var dataSource: (ParleyMessageDataSource & ParleyKeyValueDataSource)?
    private let createSecret: () -> String?
    private let createUniqueDeviceIdentifier: () -> String?
    private let createUserAuthorizationToken: () -> String?

    private static let successFullHTTPErrorStatusCodes = 200...299

    init(
        networkConfig: ParleyNetworkConfig,
        networkSession: ParleyNetworkSession,
        dataSource: (ParleyMessageDataSource & ParleyKeyValueDataSource)?,
        createSecret: @escaping () -> String?,
        createUniqueDeviceIdentifier: @escaping () -> String?,
        createUserAuthorizationToken: @escaping () -> String?
    ) {
        self.networkConfig = networkConfig
        self.networkSession = networkSession
        self.dataSource = dataSource
        self.createSecret = createSecret
        self.createUniqueDeviceIdentifier = createUniqueDeviceIdentifier
        self.createUserAuthorizationToken = createUserAuthorizationToken
    }

    private func createHeaders() -> [String: String] {
        var headers = networkConfig.headers
        guard let secret = createSecret() else {
            fatalError("ParleyRemote: Secret is not set")
        }
        headers["x-iris-identification"] = "\(secret):\(getDeviceId())"

        if let userAuthorization = createUserAuthorizationToken() {
            headers["Authorization"] = userAuthorization
        }

        return headers
    }

    private func getDeviceId() -> String {
        if let configuredDeviceId = createUniqueDeviceIdentifier() {
            return configuredDeviceId
        }

        if let uuid = UserDefaults.standard.string(forKey: kParleyUserDefaultDeviceUUID) {
            return uuid
        } else {
            let uuid = UUID().uuidString
            UserDefaults.standard.set(uuid, forKey: kParleyUserDefaultDeviceUUID)
            return uuid
        }
    }

    private func getUrl(_ path: String) -> URL {
        networkConfig.absoluteURL.appendingPathComponent(path)
    }

    // MARK: - Execute request

    func execute<T: Codable>(
        _ method: HTTPRequestMethod,
        path: String,
        parameters: [String: Any]? = nil,
        keyPath: ParleyResponseKeyPath? = .data,
        onSuccess: @escaping (_ item: T) -> (),
        onFailure: @escaping (_ error: Error) -> ()
    ) {
        debugPrint("ParleyRemote.execute:: \(method) \(getUrl(path)) \(parameters ?? [:])")

        networkSession.request(
            getUrl(path),
            method: method,
            parameters: parameters,
            headers: createHeaders()
        ) { result in
            self.handleResult(result: result, keyPath: keyPath, onSuccess: onSuccess, onFailure: onFailure)
        }
    }

    func execute(
        _ method: HTTPRequestMethod,
        path: String,
        parameters: [String: Any]? = nil,
        onSuccess: @escaping () -> (),
        onFailure: @escaping (_ error: Error) -> ()
    ) {
        debugPrint("ParleyRemote.execute:: \(method) \(getUrl(path)) \(parameters ?? [:])")

        networkSession.request(
            getUrl(path),
            method: method,
            parameters: parameters,
            headers: createHeaders()
        ) { result in
            switch result {
            case .success(let response):
                do {
                    try response.validate(statusCode: Self.successFullHTTPErrorStatusCodes)
                    onSuccess()
                } catch {
                    if let data = response.body, let apiError = Self.decodeBackendError(responseData: data) {
                        onFailure(apiError)
                    } else {
                        onFailure(error)
                    }
                }
            case .failure(let error):
                    onFailure(error)
            }
        }
    }

    // MARK: - MultipartFormData

    func execute<T: Codable>(
        _ method: HTTPRequestMethod = .post,
        path: String,
        multipartFormData: @escaping (inout MultipartFormData) -> Void,
        keyPath: ParleyResponseKeyPath? = .data,
        onSuccess: @escaping (_ item: T) -> (),
        onFailure: @escaping (_ error: Error) -> ()
    ) {
        debugPrint("ParleyRemote.execute:: \(method) \(getUrl(path))")

        var multipartForm = MultipartFormData()
        multipartFormData(&multipartForm)

        var headers = createHeaders()
        headers[HTTPHeaders.contentType.rawValue] = multipartForm.httpContentTypeHeaderValue

        networkSession.upload(
            data: multipartForm.httpBody,
            to: getUrl(path),
            method: method,
            headers: headers
        ) { [weak self] result in
            self?.handleResult(result: result, keyPath: keyPath, onSuccess: onSuccess, onFailure: onFailure)
        }
    }

    func execute<T: Codable>(
        _ method: HTTPRequestMethod = .post,
        path: String,
        imageData: Data,
        name: String,
        fileName: String,
        imageType: ParleyImageType,
        result: @escaping (Result<T, Error>) -> ()
    ) {
        debugPrint("ParleyRemote.execute:: \(method) \(getUrl(path))")

        var multipartFormData = MultipartFormData()
        multipartFormData.add(
            key: "media",
            fileName: fileName,
            fileMimeType: imageType.mimeType,
            fileData: imageData
        )
        var headers = createHeaders()
        headers[HTTPHeaders.contentType.rawValue] = multipartFormData.httpContentTypeHeaderValue

        networkSession.upload(
            data: multipartFormData.httpBody,
            to: getUrl(path),
            method: method,
            headers: headers
        ) { [weak self] resultToHandle in
            self?.handleResult(result: resultToHandle, keyPath: .data, onSuccess: { success in
                result(.success(success))
            }, onFailure: { error in
                result(.failure(error))
            })
        }
    }

    private func handleResult<T: Codable>(
        result: Result<HTTPDataResponse, HTTPErrorResponse>,
        keyPath: ParleyResponseKeyPath?,
        onSuccess: @escaping (_ item: T) -> (),
        onFailure: @escaping (_ error: Error) -> ()
    ) {
        switch result {
        case .success(let response):
            do {
                let decodedResponse = try response
                    .validate(statusCode: Self.successFullHTTPErrorStatusCodes)
                    .decodeAtKeyPath(of: T.self, keyPath: keyPath)
                onSuccess(decodedResponse)
            } catch {
                if let data = response.body, let apiError = Self.decodeBackendError(responseData: data) {
                    onFailure(apiError)
                } else {
                    onFailure(error)
                }
            }
        case .failure(let failure):
            onFailure(failure)
        }
    }

    // MARK: - Image

    @discardableResult
    func execute(
        _ method: HTTPRequestMethod,
        path: String,
        parameters: [String: Any]? = nil,
        result: @escaping (Result<ParleyImageNetworkModel, Error>) -> ()
    ) -> RequestCancelable? {
        let url = getUrl(path)
        debugPrint("ParleyRemote.execute:: \(method) \(getUrl(path)) \(parameters ?? [:])")

        let request = networkSession.request(url, method: .get, parameters: parameters, headers: createHeaders(), completion: { requestResult in
            switch requestResult {
            case .success(let response):
                if let data = response.body, Self.responseContains(response, contentType: "image/gif") {
                    result(.success(ParleyImageNetworkModel(data: data, type: .gif)))
                } else if let data = response.body {
                    result(.success(ParleyImageNetworkModel(data: data, type: .jpg)))
                }
            case .failure(let error):
                if let data = error.data, let apiError = Self.decodeBackendError(responseData: data) {
                    result(.failure(apiError))
                } else {
                    result(.failure(error))
                }
            }
        })
        
        return request
    }
    
    static func responseContains(_ response: HTTPDataResponse, contentType: String) -> Bool {
        guard let contentType = response.headers["Content-Type"] else { return false }
        return contentType.contains(contentType)
    }

    private static func decodeBackendError(responseData: Data) -> ParleyErrorResponse? {
        try? JSONDecoder().decode(ParleyErrorResponse.self, from: responseData)
    }
}

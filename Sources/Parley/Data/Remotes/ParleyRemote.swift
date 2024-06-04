import Foundation
import UIKit

final class ParleyRemote {

    let networkSession: ParleyNetworkSession
    private var networkConfig: ParleyNetworkConfig
    private let createSecret: () -> String?
    private let createUniqueDeviceIdentifier: () -> String?
    private let createUserAuthorizationToken: () -> String?

    private static let successFullHTTPErrorStatusCodes = 200...299

    init(
        networkConfig: ParleyNetworkConfig,
        networkSession: ParleyNetworkSession,
        createSecret: @escaping () -> String?,
        createUniqueDeviceIdentifier: @escaping () -> String?,
        createUserAuthorizationToken: @escaping () -> String?
    ) {
        self.networkConfig = networkConfig
        self.networkSession = networkSession
        self.createSecret = createSecret
        self.createUniqueDeviceIdentifier = createUniqueDeviceIdentifier
        self.createUserAuthorizationToken = createUserAuthorizationToken
    }

    private func createHeaders() -> [String: String] {
        var headers = networkConfig.headers
        guard let secret = createSecret() else {
            fatalError("ParleyRemote: Secret is not set")
        }
        headers[HTTPHeaders.xIrisIdentification.rawValue] = "\(secret):\(getDeviceId())"
        headers[HTTPHeaders.contentType.rawValue] = "application/json; charset=utf-8"

        if let userAuthorization = createUserAuthorizationToken() {
            headers[HTTPHeaders.authorization.rawValue] = userAuthorization
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

    @discardableResult
    func execute<T: Codable>(
        _ method: ParleyHTTPRequestMethod,
        path: String,
        body: Encodable? = nil,
        keyPath: ParleyResponseKeyPath? = .data,
        onSuccess: @escaping (_ item: T) -> Void,
        onFailure: @escaping (_ error: Error) -> Void
    ) -> any ParleyRequestCancelable {
        debugPrint("ParleyRemote.execute:: \(method) \(getUrl(path)) \(body ?? "")")
        let bodyData = mapBodyToData(body: body)

        return networkSession.request(
            getUrl(path),
            data: bodyData,
            method: method,
            headers: createHeaders()
        ) { [weak self] result in
            self?.handleResult(result: result, keyPath: keyPath, onSuccess: onSuccess, onFailure: onFailure)
        }
    }

    private func mapBodyToData(body: Encodable?) -> Data? {
        guard let body else {
            return nil
        }

        return try? JSONEncoder().encode(body)
    }

    func execute(
        _ method: ParleyHTTPRequestMethod,
        path: String,
        onSuccess: @escaping () -> Void,
        onFailure: @escaping (_ error: Error) -> Void
    ) {
        debugPrint("ParleyRemote.execute:: \(method) \(getUrl(path))")

        networkSession.request(
            getUrl(path),
            data: nil,
            method: method,
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
        _ method: ParleyHTTPRequestMethod = .post,
        path: String,
        multipartFormData: @escaping (inout MultipartFormData) -> Void,
        keyPath: ParleyResponseKeyPath? = .data,
        onSuccess: @escaping (_ item: T) -> Void,
        onFailure: @escaping (_ error: Error) -> Void
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
        _ method: ParleyHTTPRequestMethod = .post,
        path: String,
        imageData: Data,
        name: String,
        fileName: String,
        imageType: ParleyImageType,
        result: @escaping (Result<T, Error>) -> Void
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
        result: Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse>,
        keyPath: ParleyResponseKeyPath?,
        onSuccess: @escaping (_ item: T) -> Void,
        onFailure: @escaping (_ error: Error) -> Void
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
        _ method: ParleyHTTPRequestMethod,
        path: String,
        result: @escaping (Result<ParleyImageNetworkModel, Error>) -> Void
    ) -> ParleyRequestCancelable? {
        let url = getUrl(path)
        debugPrint("ParleyRemote.execute:: \(method) \(getUrl(path))")

        let request = networkSession.request(
            url,
            data: nil,
            method: .get,
            headers: createHeaders(),
            completion: { requestResult in
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
            }
        )

        return request
    }

    static func responseContains(_ response: ParleyHTTPDataResponse, contentType: String) -> Bool {
        guard let contentTypeHeader = response.headers["Content-Type"] else { return false }
        return contentTypeHeader.contains(contentType)
    }

    private static func decodeBackendError(responseData: Data) -> ParleyErrorResponse? {
        try? JSONDecoder().decode(ParleyErrorResponse.self, from: responseData)
    }
}

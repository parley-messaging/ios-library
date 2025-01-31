import Foundation
import UIKit

enum ParleyRemoteError: Error, Equatable {
    case secretNotSet
}

final class ParleyRemote {
    let networkSession: ParleyNetworkSession
    private var networkConfig: ParleyNetworkConfig
    private let createSecret: () -> String?
    private let createUniqueDeviceIdentifier: () -> String?
    private let createUserAuthorizationToken: () -> String?
    private let mainQueue: Queue
    private let backgroundQueue: Queue

    private static let successFullHTTPErrorStatusCodes = 200...299

    init(
        networkConfig: ParleyNetworkConfig,
        networkSession: ParleyNetworkSession,
        createSecret: @escaping () -> String?,
        createUniqueDeviceIdentifier: @escaping () -> String?,
        createUserAuthorizationToken: @escaping () -> String?,
        mainQueue: Queue = DispatchQueue.main,
        backgroundQueue: Queue = DispatchQueue.global(qos: .userInitiated)
    ) {
        self.networkConfig = networkConfig
        self.networkSession = networkSession
        self.createSecret = createSecret
        self.createUniqueDeviceIdentifier = createUniqueDeviceIdentifier
        self.createUserAuthorizationToken = createUserAuthorizationToken
        self.mainQueue = mainQueue
        self.backgroundQueue = backgroundQueue
    }

    private func createHeaders() throws -> [String: String] {
        var headers = networkConfig.headers
        guard let secret = createSecret() else {
            throw ParleyRemoteError.secretNotSet
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

    func execute<T: Codable>(
        _ method: ParleyHTTPRequestMethod,
        path: String,
        body: Encodable? = nil,
        keyPath: ParleyResponseKeyPath? = .data,
        onSuccess: @escaping (_ item: T) -> Void,
        onFailure: @escaping (_ error: Error) -> Void
    ) {
        debugPrint("ParleyRemote.execute:: \(method) \(getUrl(path)) \(body ?? "")")
        let bodyData = mapBodyToData(body: body)
        backgroundQueue.async { [weak self] in
            guard let self else { return }
            do {
                let headers = try createHeaders()

                networkSession.request(
                    getUrl(path),
                    data: bodyData,
                    method: method,
                    headers: headers
                ) { [weak self] result in
                    self?.handleResult(result: result, keyPath: keyPath, onSuccess: onSuccess, onFailure: onFailure)
                }
            } catch let error {
                mainQueue.async {
                    onFailure(error)
                }
            }
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

        backgroundQueue.async { [weak self] in
            guard let self else { return }
            do {

                let headers = try createHeaders()

                networkSession.request(
                    getUrl(path),
                    data: nil,
                    method: method,
                    headers: headers
                ) { [weak self] result in
                    self?.mainQueue.async {
                        switch result {
                        case .success(let response):
                            do {
                                try response.validate(statusCode: Self.successFullHTTPErrorStatusCodes)
                                onSuccess()
                            } catch {
                                if
                                    let data = response.body,
                                    let apiError = Self.decodeBackendError(responseData: data)
                                {
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
            } catch {
                mainQueue.async {
                    onFailure(error)
                }
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

        do {
            var headers = try createHeaders()
            headers[HTTPHeaders.contentType.rawValue] = multipartForm.httpContentTypeHeaderValue

            backgroundQueue.async { [weak self] in
                guard let self else { return }
                networkSession.upload(
                    data: multipartForm.httpBody,
                    to: getUrl(path),
                    method: method,
                    headers: headers
                ) { [weak self] result in
                    self?.handleResult(result: result, keyPath: keyPath, onSuccess: onSuccess, onFailure: onFailure)
                }
            }
        } catch {
            mainQueue.async {
                onFailure(error)
            }
        }
    }

    func execute<T: Codable>(
        _ method: ParleyHTTPRequestMethod = .post,
        path: String,
        data: Data,
        name: String,
        fileName: String,
        type: ParleyMediaType,
        result: @escaping (Result<T, Error>) -> Void
    ) {
        debugPrint("ParleyRemote.execute:: \(method) \(getUrl(path))")

        var multipartFormData = MultipartFormData()
        multipartFormData.add(
            key: "media",
            fileName: fileName,
            fileMimeType: type.rawValue,
            fileData: data
        )
        do {
            var headers = try createHeaders()
            headers[HTTPHeaders.contentType.rawValue] = multipartFormData.httpContentTypeHeaderValue

            backgroundQueue.async { [weak self] in
                guard let self else { return }

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
        } catch {
            mainQueue.async {
                result(.failure(error))
            }
        }
    }

    private func handleResult<T: Codable>(
        result: Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse>,
        keyPath: ParleyResponseKeyPath?,
        onSuccess: @escaping (_ item: T) -> Void,
        onFailure: @escaping (_ error: Error) -> Void
    ) {
        mainQueue.async {
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
    }

    // MARK: - Media

    func execute(
        _ method: ParleyHTTPRequestMethod,
        path: String,
        type: ParleyMediaType,
        result: @escaping (Result<Data, Error>) -> Void
    ) {
        let url = getUrl(path)
        debugPrint("ParleyRemote.execute:: \(method) \(getUrl(path))")

        backgroundQueue.async { [weak self] in
            guard let self else { return }

            do {
                let headers = try createHeaders()

                networkSession.request(
                    url,
                    data: nil,
                    method: .get,
                    headers: headers,
                    completion: { [weak self] requestResult in
                        self?.mainQueue.async {
                            switch requestResult {
                            case .success(let response):
                                if let data = response.body {
                                    result(.success(data))
                                }
                            case .failure(let error):
                                if let data = error.data, let apiError = Self.decodeBackendError(responseData: data) {
                                    result(.failure(apiError))
                                } else {
                                    result(.failure(error))
                                }
                            }
                        }
                    }

                )
            } catch {
                mainQueue.async {
                    result(.failure(error))
                }
            }
        }
    }

    private static func decodeBackendError(responseData: Data) -> ParleyErrorResponse? {
        try? JSONDecoder().decode(ParleyErrorResponse.self, from: responseData)
    }
}

// MARK: Async Methods
extension ParleyRemote {
    
    func execute<T: Codable>(
        _ method: ParleyHTTPRequestMethod,
        path: String,
        body: Encodable? = nil,
        keyPath: ParleyResponseKeyPath? = .data
    ) async throws -> T {
        debugPrint("ParleyRemote.execute:: \(method) \(getUrl(path)) \(body ?? "")")
        let bodyData = mapBodyToData(body: body)
        let headers = try createHeaders()
        let result = await networkSession.request(
            getUrl(path),
            data: bodyData,
            method: method,
            headers: headers
        )
                        
        return try handleResult(result: result, keyPath: keyPath)
    }
    
    func execute(_ method: ParleyHTTPRequestMethod, path: String) async throws {
        debugPrint("ParleyRemote.execute:: \(method) \(getUrl(path))")
        let headers = try createHeaders()
        
        let result = await networkSession.request(
            getUrl(path),
            data: nil,
            method: method,
            headers: headers
        )
        let response = try result.get()
        do {
            try response.validate(statusCode: Self.successFullHTTPErrorStatusCodes)
        } catch {
            if
                let data = response.body,
                let apiError = Self.decodeBackendError(responseData: data)
            {
                throw apiError
            } else {
                throw error
            }
        }
    }

    func execute<T: Codable>(
        _ method: ParleyHTTPRequestMethod = .post,
        path: String,
        data: Data,
        name: String,
        fileName: String,
        type: ParleyMediaType
    ) async throws -> T {
        debugPrint("ParleyRemote.execute:: \(method) \(getUrl(path))")
        
        var multipartFormData = MultipartFormData()
        multipartFormData.add(
            key: "media",
            fileName: fileName,
            fileMimeType: type.rawValue,
            fileData: data
        )
        var headers = try createHeaders()
        headers[HTTPHeaders.contentType.rawValue] = multipartFormData.httpContentTypeHeaderValue
        
        let result = await networkSession.upload(
            data: multipartFormData.httpBody,
            to: getUrl(path),
            method: method,
            headers: headers
        )
        
        return try handleResult(result: result, keyPath: .data)
    }
    
    func execute<T: Codable>(
        _ method: ParleyHTTPRequestMethod = .post,
        path: String,
        multipartFormData: @escaping (inout MultipartFormData) -> Void,
        keyPath: ParleyResponseKeyPath? = .data
    ) async throws -> T {
        debugPrint("ParleyRemote.execute:: \(method) \(getUrl(path))")
        
        var multipartForm = MultipartFormData()
        multipartFormData(&multipartForm)
        
        var headers = try createHeaders()
        headers[HTTPHeaders.contentType.rawValue] = multipartForm.httpContentTypeHeaderValue

        let result = await networkSession.upload(
            data: multipartForm.httpBody,
            to: getUrl(path),
            method: method,
            headers: headers
        )
        
        return try handleResult(result: result, keyPath: keyPath)
    }
    
    private func handleResult<T: Codable>(
        result: Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse>,
        keyPath: ParleyResponseKeyPath?
    ) throws -> T {
        let response = try result.get()
        do {
            let decodedResponse = try response
                .validate(statusCode: Self.successFullHTTPErrorStatusCodes)
                .decodeAtKeyPath(of: T.self, keyPath: keyPath)
            return decodedResponse
        } catch {
            if let data = response.body, let apiError = Self.decodeBackendError(responseData: data) {
                throw apiError
            } else {
                throw error
            }
        }
    }
    
    func execute(
        _ method: ParleyHTTPRequestMethod,
        path: String,
        type: ParleyMediaType
    ) async throws -> Data {
        let url = getUrl(path)
        debugPrint("ParleyRemote.execute:: \(method) \(getUrl(path))")
        
        let headers = try createHeaders()
        
        let result = await networkSession.request(
            url,
            data: nil,
            method: .get,
            headers: headers
        )
        
        switch result {
        case .success(let response):
            if let data = response.body {
                return data
            } else {
                throw ParleyHTTPErrorResponse(error: HTTPResponseError.dataMissing)
            }
        case .failure(let error):
            if let data = error.data, let apiError = Self.decodeBackendError(responseData: data) {
                throw apiError
            } else {
                throw error
            }
        }
    }
}

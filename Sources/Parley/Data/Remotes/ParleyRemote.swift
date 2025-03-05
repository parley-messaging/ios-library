import Foundation
import UIKit

enum ParleyRemoteError: Error, Equatable {
    case secretNotSet
}

final class ParleyRemote: Sendable {
    let networkSession: ParleyNetworkSession
    private let networkConfig: ParleyNetworkConfig
    private let createSecret: @Sendable () async -> String?
    private let createUniqueDeviceIdentifier: @Sendable () async -> String?
    private let createUserAuthorizationToken: @Sendable () async -> String?
    
    private static let successFullHTTPErrorStatusCodes = 200...299

    init(
        networkConfig: ParleyNetworkConfig,
        networkSession: ParleyNetworkSession,
        createSecret: @Sendable @escaping () async -> String?,
        createUniqueDeviceIdentifier: @Sendable @escaping () async -> String?,
        createUserAuthorizationToken: @Sendable @escaping () async -> String?
    ) {
        self.networkConfig = networkConfig
        self.networkSession = networkSession
        self.createSecret = createSecret
        self.createUniqueDeviceIdentifier = createUniqueDeviceIdentifier
        self.createUserAuthorizationToken = createUserAuthorizationToken
    }
}

// MARK: Methods
extension ParleyRemote {
    
    func execute<T: Codable>(
        _ method: ParleyHTTPRequestMethod,
        path: String,
        body: Encodable? = nil,
        keyPath: ParleyResponseKeyPath? = .data
    ) async throws -> T {
        debugPrint("ParleyRemote.execute:: \(method) \(getUrl(path)) \(body ?? "")")
        let bodyData = mapBodyToData(body: body)
        let headers = try await createHeaders()
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
        let headers = try await createHeaders()
        
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
        var headers = try await createHeaders()
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
        
        var headers = try await createHeaders()
        headers[HTTPHeaders.contentType.rawValue] = multipartForm.httpContentTypeHeaderValue

        let result = await networkSession.upload(
            data: multipartForm.httpBody,
            to: getUrl(path),
            method: method,
            headers: headers
        )
        
        return try handleResult(result: result, keyPath: keyPath)
    }
    
    func execute(
        _ method: ParleyHTTPRequestMethod,
        path: String,
        type: ParleyMediaType
    ) async throws -> Data {
        let url = getUrl(path)
        debugPrint("ParleyRemote.execute:: \(method) \(getUrl(path))")
        
        let headers = try await createHeaders()
        
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

// MARK: Privates
private extension ParleyRemote {
    
    func createHeaders() async throws -> [String: String] {
        var headers = networkConfig.headers
        guard let secret = await createSecret() else {
            throw ParleyRemoteError.secretNotSet
        }
        headers[HTTPHeaders.xIrisIdentification.rawValue] = "\(secret):\(await getDeviceId())"
        headers[HTTPHeaders.contentType.rawValue] = "application/json; charset=utf-8"

        if let userAuthorization = await createUserAuthorizationToken() {
            headers[HTTPHeaders.authorization.rawValue] = userAuthorization
        }

        return headers
    }

    func getDeviceId() async -> String {
        if let configuredDeviceId = await createUniqueDeviceIdentifier() {
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

    func getUrl(_ path: String) -> URL {
        networkConfig.absoluteURL.appendingPathComponent(path)
    }

    func mapBodyToData(body: Encodable?) -> Data? {
        guard let body else {
            return nil
        }

        return try? JSONEncoder().encode(body)
    }

    static func decodeBackendError(responseData: Data) -> ParleyErrorResponse? {
        try? JSONDecoder().decode(ParleyErrorResponse.self, from: responseData)
    }
    
    func handleResult<T: Codable>(
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
}

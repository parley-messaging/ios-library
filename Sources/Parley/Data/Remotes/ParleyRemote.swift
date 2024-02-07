import Foundation
import UIKit

class ParleyRemote {

    let networkSession: ParleyNetworkSession
    private var networkConfig: ParleyNetworkConfig
    private weak var dataSource: ParleyDataSource?
    private let createSecret: () -> String?
    private let createUniqueDeviceIdentifier: () -> String?
    private let createUserAuthorizationToken: () -> String?

    private static let successFullHTTPErrorStatusCodes = 200...299

    init(
        networkConfig: ParleyNetworkConfig,
        networkSession: ParleyNetworkSession,
        dataSource: ParleyDataSource?,
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
                    onFailure(error)
                }
            case .failure(let error):
                if let data = response.data, let apiError = decodeBackendError(responseData: data) {
                    onFailure(apiError)
                } else {
                    onFailure(error)
                }
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
        result: Result<HTTPDataResponse, Error>,
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
                onFailure(error)
            }
        case .failure(let failure):
            onFailure(failure)
        }
    }

    // MARK: - Image

    let imageCache = NSCache<NSString, UIImage>()

    @discardableResult
    func execute(
        _ method: HTTPRequestMethod,
        path: String,
        parameters: [String: Any]? = nil,
        onSuccess: @escaping (_ image: UIImage) -> (),
        onFailure: @escaping (_ error: Error) -> ()
    ) -> RequestCancelable? {
        let url = getUrl(path)

        if let image = getImageFromCache(url.absoluteString) {
            onSuccess(image)
            return nil
        }

        debugPrint("ParleyRemote.execute:: \(method) \(getUrl(path)) \(parameters ?? [:])")

        let request = networkSession.requestImage(
            url,
            method: method,
            parameters: parameters,
            headers: createHeaders()
        ) { result in
            switch result {
            case .success(let response):
                do {
                    let validatedResponse = try response.validate(statusCode: Self.successFullHTTPErrorStatusCodes)
                    if
                        let contentType: String = validatedResponse
                            .headers[HTTPHeaders.contentType.rawValue],
                        contentType.contains(ParleyImageType.gif.mimeType), let data = response.body,
                        let image = UIImage.gif(data: data)
                    {
                        self.setImage(url, image: image, data: data, isGif: true)

                        onSuccess(image)
                    } else if let data = response.body {
                        self.setImage(url, image: response.image, data: data)

                        onSuccess(response.image)
                    }
                } catch {
                    if let data = request.data, let apiError = decodeBackendError(responseData: data) {
                        onFailure(apiError)
                    } else {
                        onFailure(error)
                    }
                }
            case .failure(let failure):
                onFailure(failure)
            }
        }

        return request
    }

    private func getImageFromCache(_ url: String) -> UIImage? {
        guard
            let key = url.data(using: .utf8)?.base64EncodedString(),
            let gifKey = "\(url)\(ParleyImageType.gif.fileExtension)".data(using: .utf8)?.base64EncodedString() else
        {
            return nil
        }

        if let image = imageCache.object(forKey: key as NSString) {
            return image
        } else if let image = imageCache.object(forKey: gifKey as NSString) {
            return image
        }

        if let data = dataSource?.data(forKey: key), let image = UIImage(data: data) {
            return image
        } else if let data = dataSource?.data(forKey: gifKey), let image = UIImage.gif(data: data) {
            return image
        }

        return nil
    }

    private func setImage(_ url: URL, image: UIImage, data: Data, isGif: Bool = false) {
        let suffix = isGif ? ParleyImageType.gif.fileExtension : ""
        guard let key = "\(url.absoluteString)\(suffix)".data(using: .utf8)?.base64EncodedString() else { return }

        imageCache.setObject(image, forKey: key as NSString)

        dataSource?.set(data, forKey: key)
    }

    private static func decodeBackendError(responseData: Data) -> ParleyErrorResponse? {
        try? JSONDecoder().decode(ParleyErrorResponse.self, from: responseData)
    }
}

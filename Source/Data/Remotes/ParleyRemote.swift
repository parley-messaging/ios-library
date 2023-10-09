import Alamofire
import AlamofireImage
import ObjectMapper
import UIKit
import Foundation


public typealias ParleyRemoteInterceptor = ParleyRemoteRequestInterceptorProtocol & ParleyRemoteResponseInterceptorProtocol

public protocol ParleyRemoteRequestInterceptorProtocol: AnyObject {
    func httpRequestWillStart(with request: inout URLRequest) throws
}

public protocol ParleyRemoteResponseInterceptorProtocol: AnyObject {
    func httpResponseReceived(response: HTTPURLResponse) throws
}

internal class ParleyRemoteInterceptorProxy: RequestInterceptor {

    private let interceptors: [ParleyRemoteInterceptor]
    
    init(interceptors: [ParleyRemoteInterceptor]) {
        self.interceptors = interceptors
    }
    
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        guard interceptors.count > 0 else {
            completion(.success(urlRequest))
            return
        }
        var editableUrlRequest = urlRequest
        
        interceptors.forEach {
            do {
                try $0.httpRequestWillStart(with: &editableUrlRequest)
            } catch {
                completion(.failure(error))
            }
        }
        completion(.success(editableUrlRequest))
    }
    
    func validate(request: URLRequest?, response: HTTPURLResponse, data: Data?) -> Request.ValidationResult {
        guard interceptors.count > 0 else {
            return Request.ValidationResult.success(())
        }
        
        do {
            try interceptors.forEach { try $0.httpResponseReceived(response: response) }
            return Request.ValidationResult.success(())
        } catch {
            return Request.ValidationResult.failure(error)
        }
    }
}

internal class ParleyRemote {
    
    internal static var sessionManager: Alamofire.Session!
    internal static var parleyRemoteInterceptorProxy: ParleyRemoteInterceptorProxy!
    
    internal static func refresh(_ network: ParleyNetwork) {
        guard let domain = URL(string: network.url)?.host else {
            fatalError("ParleyRemote: Invalid url")
        }
        
        let evaluators: [String: ServerTrustEvaluating] = [
            domain: PublicKeysTrustEvaluator()
        ]
        
        parleyRemoteInterceptorProxy = ParleyRemoteInterceptorProxy(interceptors: network.interceptors)
        
        sessionManager = Session(
            configuration: URLSessionConfiguration.af.default,
            interceptor: parleyRemoteInterceptorProxy,
            serverTrustManager: ServerTrustManager(evaluators: evaluators)
        )
    }
    
    private static func getHeaders() -> HTTPHeaders {
        var headers = Parley.shared.network.headers
        guard let secret = Parley.shared.secret else {
            fatalError("ParleyRemote: Secret is not set")
        }
        headers["x-iris-identification"] = "\(secret):\(getDeviceId())"
        
        if let userAuthorization = Parley.shared.userAuthorization {
            headers["Authorization"] = userAuthorization
        }
        
        return HTTPHeaders(headers)
    }
    
    private static func getDeviceId() -> String {
        if let configuredDeviceId = Parley.shared.uniqueDeviceIdentifier {
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
    
    private static func getUrl(_ path: String) -> URL {
        Parley.shared.network.absoluteURL.appendingPathComponent(path)
    }
    
    // MARK: Execute request
    @discardableResult internal static func execute<T: BaseMappable>(_ method: HTTPMethod, _ path: String, parameters: Parameters? = nil, keyPath: String? = "data", onSuccess: @escaping (_ items: [T])->(), onFailure: @escaping (_ error: Error)->()) -> DataRequest {
        debugPrint("ParleyRemote.execute:: \(method) \(getUrl(path)) \(parameters ?? [:])")
        
        let request = sessionManager.request(getUrl(path), method: method, parameters: parameters, encoding: JSONEncoding.default, headers: getHeaders())
        request
            .validate(parleyRemoteInterceptorProxy.validate)
            .validate(statusCode: 200...299).responseArray(keyPath: keyPath) { (response: AFDataResponse<[T]>) in
            switch response.result {
            case .success(let items):
                onSuccess(items)
            case .failure(let error):
                onFailure(error)
            }
        }
        
        return request
    }
    
    @discardableResult internal static func execute<T: BaseMappable>(_ method: HTTPMethod, _ path: String, parameters: Parameters?=nil, keyPath: String? = "data", onSuccess: @escaping (_ item: T) -> (), onFailure: @escaping (_ error: Error) -> ()) -> DataRequest {
        debugPrint("ParleyRemote.execute:: \(method) \(getUrl(path)) \(parameters ?? [:])")
        
        let request = sessionManager.request(getUrl(path), method: method, parameters: parameters, encoding: JSONEncoding.default, headers: getHeaders())
        request
            .validate(parleyRemoteInterceptorProxy.validate)
            .validate(statusCode: 200...299).responseObject(keyPath: keyPath) { (response: AFDataResponse<T>) in
            switch response.result {
            case .success(let item):
                onSuccess(item)
            case .failure(let error):
                onFailure(error)
            }
        }
        
        return request
    }
    
    @discardableResult internal static func execute(_ method: HTTPMethod, _ path: String, parameters: Parameters?=nil, onSuccess: @escaping ()->(), onFailure: @escaping (_ error: Error)->()) -> DataRequest {
        debugPrint("ParleyRemote.execute:: \(method) \(getUrl(path)) \(parameters ?? [:])")
        
        let request = sessionManager.request(getUrl(path), method: method, parameters: parameters, encoding: JSONEncoding.default, headers: getHeaders())
        request
            .validate(parleyRemoteInterceptorProxy.validate)
            .validate(statusCode: 200...299).responseJSON { (response) in
            switch response.result {
            case .success:
                onSuccess()
            case .failure(let error):
                onFailure(error)
            }
        }
        
        return request
    }
    
    internal static func execute<T: BaseMappable>(_ method: HTTPMethod = HTTPMethod.post, path: String, multipartFormData: @escaping (MultipartFormData) -> Void, keyPath: String? = "data", onSuccess: @escaping (_ item: T) -> (), onFailure: @escaping (_ error: Error)->()) {
        debugPrint("ParleyRemote.execute:: \(method) \(getUrl(path))")
        
        sessionManager.upload(multipartFormData: multipartFormData, to: getUrl(path), method: method, headers: getHeaders())
            .validate(statusCode: 200...299)
            .validate(parleyRemoteInterceptorProxy.validate)
            .responseObject(keyPath: keyPath) { (response: AFDataResponse<T>) in
                switch response.result {
                case .success(let item):
                    onSuccess(item)
                case .failure(let error):
                    onFailure(error)
                }
            }
    }
    
    // MARK: Image
    internal static let imageCache = NSCache<NSString, UIImage>()
    
    @discardableResult internal static func execute(_ method: HTTPMethod, _ path: String, parameters: Parameters?=nil, onSuccess: @escaping (_ image: UIImage)->(), onFailure: @escaping (_ error: Error)->()) -> DataRequest? {
        let url = getUrl(path)
        
        if let image = getImage(url.absoluteString) {
            onSuccess(image)
            
            return nil
        } else {
            debugPrint("ParleyRemote.execute:: \(method) \(getUrl(path)) \(parameters ?? [:])")
            
            let request = sessionManager.request(url, method: method, parameters: parameters, encoding: JSONEncoding.default, headers: getHeaders())
            request
                .validate(statusCode: 200...299)
                .validate(parleyRemoteInterceptorProxy.validate)
                .responseImage { response in
                switch response.result {
                case .success(let image):
                    if let contentType: String = response.response?.allHeaderFields["Content-Type"] as? String, contentType.contains("image/gif"), let data = response.data, let image = UIImage.gif(data: data) {
                        setImage(url, image: image, data: data, isGif: true)
                        
                        onSuccess(image)
                    } else if let data = response.data {
                        setImage(url, image: image, data: data)
                        
                        onSuccess(image)
                    }
                case .failure(let error):
                    onFailure(error)
                }
            }
            
            return request
        }
    }
    
    private static func getImage(_ url: String) -> UIImage? {
        guard let key = url.data(using: .utf8)?.base64EncodedString() else { return nil }
        guard let gifKey = "\(url).gif".data(using: .utf8)?.base64EncodedString() else { return nil }
        
        if let image = imageCache.object(forKey: key as NSString) {
            return image
        } else if let image = imageCache.object(forKey: gifKey as NSString) {
            return image
        }
        
        if let data = Parley.shared.dataSource?.data(forKey: key), let image = UIImage(data: data) {
            return image
        } else if let data = Parley.shared.dataSource?.data(forKey: gifKey), let image = UIImage.gif(data: data) {
            return image
        }
        
        return nil
    }
    
    private static func setImage(_ url: URL, image: UIImage, data: Data, isGif: Bool = false) {
        let suffix = isGif ? ".gif" : ""
        guard let key = "\(url.absoluteString)\(suffix)".data(using: .utf8)?.base64EncodedString() else { return }
        
        imageCache.setObject(image, forKey: key as NSString)
        
        Parley.shared.dataSource?.set(data, forKey: key)
    }
}

// MARK: - Codable implementation

internal extension ParleyRemote {
    
    static func execute<T: Codable>(_ method: HTTPMethod = HTTPMethod.post, path: String, multipartFormData: MultipartFormData, keyPath: String? = "data", result: @escaping ((Result<T, Error>) -> ())) {
        debugPrint("ParleyRemote.execute:: \(method) \(getUrl(path))")
        sessionManager.upload(multipartFormData: multipartFormData, to: getUrl(path), method: method, headers: getHeaders())
            .validate(statusCode: 200...299)
            .responseData(completionHandler: { response in
                decodeData(response: response, result: result)
            })
    }
    
    static func decodeData<T: Codable>(response: AFDataResponse<Data>, result: @escaping ((Result<T, Error>) -> ())) {
        switch response.result {
        case .success(let data):
            do {
                let decodedData = try JSONDecoder().decode(ParleyResponse<T>.self, from: data)
                result(.success(decodedData.data))
            } catch {
                result(.failure(error))
            }
        case .failure(let error):
            result(.failure(error))
        }
    }
}
import Foundation
import UIKit

/// Protocol to implement custom network layer for Parley.
///
/// > Warning: By implementing this protocol you are responsible for SSL pinning
/// and other security related features that `Alamofire` will
/// provide out of the box.
///
/// By default the Parley SDK does use the `Alamofire` library to make
/// network requests. You can also use your own network layer. To do
/// so implement this protocol and register this with the following code:
/// ```swift
/// Parley.configure(
///    "<secret>"
///    networkConfig: ParleyNetworkConfig(url: "https://yourdomain.com"),
///    networkSession: YourImplementationOfParleyNetworkSession(),
/// )
/// ```
public protocol ParleyNetworkSession: Sendable {

    func request(
        _ url: URL,
        data: Data?,
        method: ParleyHTTPRequestMethod,
        headers: [String: String],
        completion: @Sendable @escaping (_ result: Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse>) -> Void
    )

    func upload(
        data: Data,
        to url: URL,
        method: ParleyHTTPRequestMethod,
        headers: [String: String],
        completion: @Sendable @escaping (_ result: Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse>) -> Void
    )
}

extension ParleyNetworkSession {
    
    public func request(
        _ url: URL,
        data: Data?,
        method: ParleyHTTPRequestMethod,
        headers: [String: String]
    ) async -> Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse> {
        await withCheckedContinuation { continuation in
            request(url, data: data, method: method, headers: headers) { result in
                continuation.resume(returning: result)
            }
        }
    }
    
    public func upload(
        data: Data,
        to url: URL,
        method: ParleyHTTPRequestMethod,
        headers: [String: String]
    ) async -> Result<ParleyHTTPDataResponse, ParleyHTTPErrorResponse> {
        await withCheckedContinuation { continuation in
            upload(data: data, to: url, method: method, headers: headers) { result in
                continuation.resume(returning: result)
            }
        }
    }
}



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
public protocol ParleyNetworkSession {

    @discardableResult
    func request(
        _ url: URL,
        method: HTTPRequestMethod,
        parameters: [String: Any]?,
        headers: [String: String],
        completion: @escaping (_ result: Result<HTTPDataResponse, HTTPErrorResponse>) -> Void
    ) -> RequestCancelable

    @discardableResult
    func upload(
        data: Data,
        to url: URL,
        method: HTTPRequestMethod,
        headers: [String: String],
        completion: @escaping (_ result: Result<HTTPDataResponse, HTTPErrorResponse>) -> Void
    ) -> RequestCancelable
}

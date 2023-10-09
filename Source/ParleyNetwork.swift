import UIKit

public struct ParleyNetwork {

    let url: String
    let path: String
    let headers: [String: String]
    var apiVersion: ApiVersion = .v1_6
    var interceptors: [ParleyRemoteInterceptor]

    internal var absoluteURL: URL {
        guard var url = URL(string: url) else {
            fatalError("Invalid URL passed to ParleyNetwork")
        }
        url.appendPathComponent(path)
        return url
    }

    init() {
        url = kParleyNetworkUrl
        path = kParleyNetworkPath
        headers = [:]
        interceptors = []
    }

    public init(
        url: String,
        path: String,
        apiVersion: ApiVersion = .v1_6,
        headers: [String:String] = [:],
        interceptors: [ParleyRemoteInterceptor] = []
    ) {
        self.url = url
        self.path = path
        self.apiVersion = apiVersion
        self.headers = headers
        self.interceptors = interceptors
    }
}
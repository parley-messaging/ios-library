import UIKit

public struct ParleyNetworkConfig {
    public let url: String
    package let path: String
    package let headers: [String: String]
    package var apiVersion: ApiVersion = .v1_6

    package var absoluteURL: URL {
        guard var url = URL(string: url) else {
            fatalError("Invalid URL passed to ParleyNetwork")
        }
        url.appendPathComponent(path)
        return url
    }

    package init() {
        url = kParleyNetworkUrl
        path = kParleyNetworkPath
        headers = [:]
    }

    public init(url: String, path: String, apiVersion: ApiVersion = .v1_6, headers: [String:String] = [:]) {
        self.url = url
        self.path = path
        self.apiVersion = apiVersion
        self.headers = headers
    }
}

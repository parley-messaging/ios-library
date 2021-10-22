import UIKit

public struct ParleyNetwork {
        
    let url: String
    let path: String
    let headers: [String: String]
    var apiVersion: ApiVersion = .v1_6
    
    internal var absoluteURL: URL {
        guard var url = URL(string: self.url) else {
            fatalError("Invalid URL passed to ParleyNetwork")
        }
        url.appendPathComponent(path)
        return url
    }
    
    init () {
        self.url = kParleyNetworkUrl
        self.path = kParleyNetworkPath
        self.headers = [:]
    }
    
    @available(*, deprecated, message: "Please specify your apiVersion.")
    public init(url: String, path: String, headers: [String:String] = [:]) {
        self.url = url
        self.path = path
        self.headers = headers
        self.apiVersion = .v1_6
    }
    
    public init(url: String, path: String, headers: [String:String] = [:], apiVersion: ApiVersion = .v1_6) {
        self.url = url
        self.path = path
        self.headers = headers
        self.apiVersion = apiVersion
    }
}

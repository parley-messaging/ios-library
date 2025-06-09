import Testing
import Alamofire
import Foundation
@testable import Parley
@testable import ParleyNetwork

@Suite(.serialized)
struct AlamofireHTTParleyConfigureTestsPMethodTests {

    func testSettingDefaultConfig() async throws {
        let result = await Parley.configure("secret")
        try result.get()
        
        #expect(Parley.shared.networkConfig.headers == [:])
        #expect(Parley.shared.networkConfig.url == kParleyNetworkUrl)
        #expect(Parley.shared.networkConfig.path == kParleyNetworkPath)

        #expect(Parley.shared.remote.networkSession is AlamofireNetworkSession)
    }

    func testSettingCustomConfig() async throws {
        let url = "https://example.com"
        let path = "/example"
        let headers = ["example": "example"]
        let result = await Parley.configure(
            "secret",
            networkConfig: ParleyNetworkConfig(
                url: url,
                path: path,
                apiVersion: .v1_7,
                headers: headers
            )
        )
        
        try result.get()

        #expect(Parley.shared.networkConfig.headers == headers)
        #expect(Parley.shared.networkConfig.url == url)
        #expect(Parley.shared.networkConfig.path == path)

        #expect(Parley.shared.remote.networkSession is AlamofireNetworkSession)
    }
}

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
        
        await #expect(ParleyActor.shared.networkConfig.headers == [:])
        await #expect(ParleyActor.shared.networkConfig.url == kParleyNetworkUrl)
        await #expect(ParleyActor.shared.networkConfig.path == kParleyNetworkPath)

        await #expect(ParleyActor.shared.remote.networkSession is AlamofireNetworkSession)
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

        await #expect(ParleyActor.shared.networkConfig.headers == headers)
        await #expect(ParleyActor.shared.networkConfig.url == url)
        await #expect(ParleyActor.shared.networkConfig.path == path)

        await #expect(ParleyActor.shared.remote.networkSession is AlamofireNetworkSession)
    }
}

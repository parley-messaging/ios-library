import Alamofire
import Foundation
import XCTest
@testable import Parley
@testable import ParleyNetwork

final class AlamofireHTTParleyConfigureTestsPMethodTests: XCTestCase {

    func testSettingDefaultConfig() {
        Parley.configure("secret")

        XCTAssertEqual(Parley.shared.networkConfig.headers, [:])
        XCTAssertEqual(Parley.shared.networkConfig.url, kParleyNetworkUrl)
        XCTAssertEqual(Parley.shared.networkConfig.path, kParleyNetworkPath)

        XCTAssertTrue(Parley.shared.remote.networkSession is AlamofireNetworkSession)
    }

    func testSettingCustomConfig() {
        let url = "https://example.com"
        let path = "/example"
        let headers = ["example": "example"]
        Parley.configure(
            "secret",
            networkConfig: ParleyNetworkConfig(
                url: url,
                path: path,
                apiVersion: .v1_7,
                headers: headers
            )
        )

        XCTAssertEqual(Parley.shared.networkConfig.headers, headers)
        XCTAssertEqual(Parley.shared.networkConfig.url, url)
        XCTAssertEqual(Parley.shared.networkConfig.path, path)

        XCTAssertTrue(Parley.shared.remote.networkSession is AlamofireNetworkSession)
    }
}

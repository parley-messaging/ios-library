import Alamofire
import Foundation
import XCTest
@testable import Parley
@testable import ParleyNetwork

final class AlamofireHTTParleyConfigureTestsPMethodTests: XCTestCase {

    private var sut: Parley!

    override func setUpWithError() throws {
        sut = Parley.shared
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    func testSettingDefaultConfig() {
        sut.configure("secret")

        XCTAssertEqual(sut.networkConfig.headers, [:])
        XCTAssertEqual(sut.networkConfig.url, kParleyNetworkUrl)
        XCTAssertEqual(sut.networkConfig.path, kParleyNetworkPath)

        XCTAssertTrue(sut.remote.networkSession is AlamofireNetworkSession)
    }

    func testSettingCustomConfig() {
        let url = "https://example.com"
        let path = "/example"
        let headers = ["example": "example"]
        sut.configure(
            "secret",
            networkConfig: ParleyNetworkConfig(
                url: url,
                path: path,
                apiVersion: .v1_6, 
                headers: headers
            )
        )

        XCTAssertEqual(sut.networkConfig.headers, headers)
        XCTAssertEqual(sut.networkConfig.url, url)
        XCTAssertEqual(sut.networkConfig.path, path)

        XCTAssertTrue(sut.remote.networkSession is AlamofireNetworkSession)
    }
}

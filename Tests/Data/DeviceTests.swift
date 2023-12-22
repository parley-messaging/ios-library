import Foundation
import XCTest
@testable import Parley

final class DeviceTests: XCTestCase {

    var decoder: JSONDecoder!
    var encoder: JSONEncoder!

    override func setUpWithError() throws {
        decoder = JSONDecoder()
        encoder = JSONEncoder()
    }

    override func tearDownWithError() throws {
        decoder = nil
        encoder = nil
    }

    func testDecode() throws {
        let pushToken = "YrViSfynsb3eB72Yd7gNfZ_"
        let deviceString = "{\"pushEnabled\":true,\"version\":\"3.1.3\",\"type\":2," +
            "\"pushType\":6,\"pushToken\":\"\(pushToken)\"}"

        let decodedDevice = Device(
            pushToken: pushToken,
            pushType: .fcm,
            pushEnabled: true,
            userAdditionalInformation: nil,
            referrer: nil
        )

        let result = try decoder.decode(Device.self, from: Data(deviceString.utf8))

        XCTAssertEqual(decodedDevice, result)
    }

}

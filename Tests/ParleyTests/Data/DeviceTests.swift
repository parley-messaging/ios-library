import Foundation
import XCTest
@testable import Parley

final class DeviceTests: XCTestCase {

    private let pushToken = "YrViSfynsb3eB72Yd7gNfZ_"
    private lazy var deviceString = "{\"pushEnabled\":true,\"pushType\":6,\"type\":2,\"version\":" +
        "\"3.1.3\",\"pushToken\":\"\(pushToken)\"}"

    private var decoder: JSONDecoder!
    private var encoder: JSONEncoder!

    override func setUpWithError() throws {
        decoder = JSONDecoder()
        encoder = JSONEncoder()
    }

    override func tearDownWithError() throws {
        decoder = nil
        encoder = nil
    }

    func testDecodeEncode() throws {
        let expectedResult = makeDevice()

        let decodedSut = try decoder.decode(Device.self, from: Data(deviceString.utf8))
        let encodedSut = try encoder.encode(decodedSut)
        let result = try decoder.decode(Device.self, from: encodedSut)

        XCTAssertEqual(result, expectedResult)
    }

    private func makeDevice() -> Device {
        Device(
            pushToken: pushToken,
            pushType: .fcm,
            pushEnabled: true,
            userAdditionalInformation: nil,
            referrer: nil
        )
    }

}

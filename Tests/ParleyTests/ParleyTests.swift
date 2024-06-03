import XCTest

@testable import Parley

final class ParleyTests: XCTestCase {

    private var localizationManagerSpy: LocalizationManagerSpy!

    override func setUpWithError() throws {
        localizationManagerSpy = LocalizationManagerSpy()
    }

    override func tearDownWithError() throws {
        localizationManagerSpy = nil

        Parley.setLocalizationManager(ParleyLocalizationManager())
    }

    func testSetLocalizationManager() {
        let localizationKeyReturnValue = "test!"

        XCTAssertNotEqual(ParleyLocalizationKey.cancel.localized, ParleyLocalizationKey.cancel.rawValue)
        XCTAssertEqual(localizationManagerSpy.getLocalizationKeyCallsCount, 0)

        Parley.setLocalizationManager(localizationManagerSpy)
        localizationManagerSpy.getLocalizationKeyReturnValue = localizationKeyReturnValue

        XCTAssertEqual(ParleyLocalizationKey.cancel.localized, localizationKeyReturnValue)
        XCTAssertEqual(localizationManagerSpy.getLocalizationKeyCallsCount, 1)
    }
}

import Testing
@testable import Parley

@Suite("Parley Tests")
struct ParleyTests {

    private let localizationManagerSpy: LocalizationManagerSpy
    
    init() {
        self.localizationManagerSpy = LocalizationManagerSpy()
    }

    @Test
    func testSetLocalizationManager() async {
        let localizationKeyReturnValue = "test!"

        await #expect(ParleyLocalizationKey.cancel.localized() != ParleyLocalizationKey.cancel.rawValue)
        #expect(localizationManagerSpy.getLocalizationKeyArgumentsCallsCount == 0)

        await Parley.setLocalizationManager(localizationManagerSpy)
        localizationManagerSpy.getLocalizationKeyArgumentsReturnValue = localizationKeyReturnValue

        await #expect(ParleyLocalizationKey.cancel.localized() == localizationKeyReturnValue)
        #expect(localizationManagerSpy.getLocalizationKeyArgumentsCallsCount == 1)
    }
}

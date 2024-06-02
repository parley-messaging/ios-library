import Parley
import XCTest

public final class LocalizationManagerSpy: LocalizationManager {

    public init(
        getLocalizationKeyReturnValue: String? = nil
    ) {
        self.getLocalizationKeyReturnValue = getLocalizationKeyReturnValue
    }

    // MARK: - getLocalization

    public var getLocalizationKeyCallsCount = 0
    public var getLocalizationKeyCalled: Bool {
        getLocalizationKeyCallsCount > 0
    }

    public var getLocalizationKeyReceivedKey: ParleyLocalizationKey?
    public var getLocalizationKeyReceivedInvocations: [ParleyLocalizationKey] = []
    public var getLocalizationKeyReturnValue: String!
    public var getLocalizationKeyClosure: ((ParleyLocalizationKey) -> String)?

    public func getLocalization(key: ParleyLocalizationKey) -> String {
        getLocalizationKeyCallsCount += 1
        getLocalizationKeyReceivedKey = key
        getLocalizationKeyReceivedInvocations.append(key)
        if let getLocalizationKeyClosure {
            return getLocalizationKeyClosure(key)
        } else {
            return getLocalizationKeyReturnValue
        }
    }

}

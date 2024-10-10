import Parley
import XCTest

public final class LocalizationManagerSpy: LocalizationManager {

    public init(
        getLocalizationKeyArgumentsReturnValue: String? = nil
    ) {
        self.getLocalizationKeyArgumentsReturnValue = getLocalizationKeyArgumentsReturnValue
    }

    // MARK: - getLocalization

    public var getLocalizationKeyArgumentsCallsCount = 0
    public var getLocalizationKeyArgumentsCalled: Bool {
        getLocalizationKeyArgumentsCallsCount > 0
    }

    public var getLocalizationKeyArgumentsReceivedArguments: (key: ParleyLocalizationKey, arguments: CVarArg)?
    public var getLocalizationKeyArgumentsReceivedInvocations: [(key: ParleyLocalizationKey, arguments: CVarArg)] = []
    public var getLocalizationKeyArgumentsReturnValue: String!
    public var getLocalizationKeyArgumentsClosure: ((ParleyLocalizationKey, CVarArg) -> String)?

    public func getLocalization(key: ParleyLocalizationKey, arguments: CVarArg...) -> String {
        getLocalizationKeyArgumentsCallsCount += 1
        getLocalizationKeyArgumentsReceivedArguments = (key: key, arguments: arguments)
        getLocalizationKeyArgumentsReceivedInvocations.append((key: key, arguments: arguments))
        if let getLocalizationKeyArgumentsClosure {
            return getLocalizationKeyArgumentsClosure(key, arguments)
        } else {
            return getLocalizationKeyArgumentsReturnValue
        }
    }

}

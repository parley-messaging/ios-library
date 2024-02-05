import Foundation

public enum ApiVersion {

    @available(*, deprecated, message: "A newer version is available to support the latest functionality of Parley.")
    case v1_0

    @available(*, deprecated, message: "A newer version is available to support the latest functionality of Parley.")
    case v1_1

    @available(*, deprecated, message: "A newer version is available to support the latest functionality of Parley.")
    case v1_2

    @available(*, deprecated, message: "A newer version is available to support the latest functionality of Parley.")
    case v1_3

    @available(*, deprecated, message: "A newer version is available to support the latest functionality of Parley.")
    case v1_4

    @available(*, deprecated, message: "A newer version is available to support the latest functionality of Parley.")
    case v1_5

    case v1_6

    var isUsingMedia: Bool {
        switch self {
        case .v1_6:
            return true
        default:
            return false
        }
    }
}

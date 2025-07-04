import Foundation

public enum ApiVersion: Sendable, CustomStringConvertible {
    case v1_6
    case v1_7
    case v1_8
    case v1_9
    
    var isSupportingMessageStatus: Bool {
        return switch self {
        case .v1_6: false
        case .v1_7: false
        case .v1_8: false
        case .v1_9: true
        }
    }
    
    public var description: String {
        switch self {
        case .v1_6: "V1.6"
        case .v1_7: "V1.7"
        case .v1_8: "V1.8"
        case .v1_9: "V1.9"
        }
    }
    
    public static let `default` = ApiVersion.v1_9
}

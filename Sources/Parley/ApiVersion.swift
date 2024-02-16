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
  
    case v1_7
    
    var isUsingMedia: Bool {
        switch self {
        case .v1_0, .v1_1, .v1_2, .v1_3, .v1_4, .v1_5: return false
        case .v1_6, .v1_7: return true
        }
    }
}

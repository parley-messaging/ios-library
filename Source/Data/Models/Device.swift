import ObjectMapper

public class Device: Mappable {
    
    public enum DevicePushType: Int {
        
        case customWebhook = 4
        case customWebhookBehindOAuth = 5
        case fcm = 6
    }
    
    var pushToken: String?
    var pushType: DevicePushType?
    var pushEnabled: Bool?
    var userAdditionalInformation: [String: String]?
    var type: Int = 2 // iOS
    var version: String = kParleyVersion
    
    init() {
        //
    }
    
    required public init?(map: Map) {
        //
    }
    
    public func mapping(map: Map) {
        pushToken <- map["pushToken"]
        pushType <- (map["pushType"], EnumTransform<DevicePushType>())
        pushEnabled <- map["pushEnabled"]
        userAdditionalInformation <- map["userAdditionalInformation"]
        type <- map["type"]
        version <- map["version"]
    }
}

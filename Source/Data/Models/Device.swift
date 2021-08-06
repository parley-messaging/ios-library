import ObjectMapper

public class Device: Mappable {
    
    public enum PushType: Int {
        
        case customWebhook = 4
        case customWebhookBehindOAuth = 5
        case fcm = 6
    }
    
    var pushToken: String?
    var pushType: PushType?
    var pushEnabled: Bool?
    var userAdditionalInformation: [String: String]?
    var type: Int = 2 // iOS
    var version: String = kParleyVersion
    var referrer: String?
    
    init() {
        //
    }
    
    required public init?(map: Map) {
        //
    }
    
    public func mapping(map: Map) {
        pushToken <- map["pushToken"]
        pushType <- (map["pushType"], EnumTransform<PushType>())
        pushEnabled <- map["pushEnabled"]
        userAdditionalInformation <- map["userAdditionalInformation"]
        type <- map["type"]
        version <- map["version"]
        referrer <- map["referrer"]
    }
}

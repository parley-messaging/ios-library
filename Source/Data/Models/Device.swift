import ObjectMapper

class Device: Mappable {
    
    var pushToken: String?
    var pushType: Int = kParleyDevicePushTypePushEnabled
    var pushEnabled: Bool?
    var userAdditionalInformation: [String: String]?
    var type: Int = 2 // iOS
    var version: String = kParleyVersion
    
    init() {
        //
    }
    
    required init?(map: Map) {
        //
    }
    
    func mapping(map: Map) {
        pushToken <- map["pushToken"]
        pushType <- map["pushType"]
        pushEnabled <- map["pushEnabled"]
        userAdditionalInformation <- map["userAdditionalInformation"]
        type <- map["type"]
        version <- map["version"]
    }
}

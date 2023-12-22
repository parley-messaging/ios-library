import Foundation

public struct Device: Codable, Equatable {

    public enum PushType: Int, Codable, Equatable {
        case customWebhook = 4
        case customWebhookBehindOAuth = 5
        case fcm = 6
    }
    
    private enum DeviceType: Int, Codable, Equatable {
        case android = 1
        case iOS = 2
        case web = 3
        case generic = 4 // Custom build
    }

    var pushToken: String?
    var pushType: PushType?
    var pushEnabled: Bool?
    var userAdditionalInformation: [String: String]?
    private var type: DeviceType
    var version: String
    var referrer: String?

    init(
        pushToken: String?,
        pushType: PushType?,
        pushEnabled: Bool?,
        userAdditionalInformation: [String : String]?,
        referrer: String?
    ) {
        self.pushToken = pushToken
        self.pushType = pushType
        self.pushEnabled = pushEnabled
        self.userAdditionalInformation = userAdditionalInformation
        type = DeviceType.iOS
        version = kParleyVersion
        self.referrer = referrer
    }
    
    enum CodingKeys: CodingKey {
        case pushToken
        case pushType
        case pushEnabled
        case userAdditionalInformation
        case type
        case version
        case referrer
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.pushToken = try container.decodeIfPresent(String.self, forKey: .pushToken)
        self.pushType = try container.decodeIfPresent(Device.PushType.self, forKey: .pushType)
        self.pushEnabled = try container.decodeIfPresent(Bool.self, forKey: .pushEnabled)
        self.userAdditionalInformation = try container.decodeIfPresent([String : String].self, forKey: .userAdditionalInformation)
        self.type = try container.decodeIfPresent(DeviceType.self, forKey: .type)  ?? DeviceType.iOS
        self.version = try container.decodeIfPresent(String.self, forKey: .version) ?? kParleyVersion
        self.referrer = try container.decodeIfPresent(String.self, forKey: .referrer)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.pushToken, forKey: .pushToken)
        try container.encodeIfPresent(self.pushType, forKey: .pushType)
        try container.encodeIfPresent(self.pushEnabled, forKey: .pushEnabled)
        try container.encodeIfPresent(self.userAdditionalInformation, forKey: .userAdditionalInformation)
        try container.encode(self.type, forKey: .type)
        try container.encode(self.version, forKey: .version)
        try container.encodeIfPresent(self.referrer, forKey: .referrer)
    }

}

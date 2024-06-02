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
        case generic = 4 // Generic custom build
    }

    let pushToken: String?
    let pushType: PushType?
    let pushEnabled: Bool?
    let userAdditionalInformation: [String: String]?
    private let type: DeviceType
    let version: String
    let referrer: String?

    init(
        pushToken: String?,
        pushType: PushType?,
        pushEnabled: Bool?,
        userAdditionalInformation: [String: String]?,
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
        pushToken = try container.decodeIfPresent(String.self, forKey: .pushToken)
        pushType = try container.decodeIfPresent(Device.PushType.self, forKey: .pushType)
        pushEnabled = try container.decodeIfPresent(Bool.self, forKey: .pushEnabled)
        userAdditionalInformation = try container.decodeIfPresent(
            [String: String].self,
            forKey: .userAdditionalInformation
        )
        type = try container.decodeIfPresent(DeviceType.self, forKey: .type) ?? DeviceType.iOS
        version = try container.decodeIfPresent(String.self, forKey: .version) ?? kParleyVersion
        referrer = try container.decodeIfPresent(String.self, forKey: .referrer)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(pushToken, forKey: .pushToken)
        try container.encodeIfPresent(pushType?.rawValue, forKey: .pushType)
        try container.encodeIfPresent(pushEnabled, forKey: .pushEnabled)
        try container.encodeIfPresent(userAdditionalInformation, forKey: .userAdditionalInformation)
        try container.encode(type, forKey: .type)
        try container.encode(version, forKey: .version)
        try container.encodeIfPresent(referrer, forKey: .referrer)
    }
}

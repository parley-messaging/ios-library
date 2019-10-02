import ObjectMapper

public class Message: Mappable, Equatable {
    
    enum MessageType: Int {
        
        case loading = -3
        case agentTyping = -2
        case date = -1
        case info = 0
        case user = 1
        case agent = 2
        case auto = 3
        case systemMessageUser = 4
        case systemMessageAgent = 5
        
        static let ignored: [MessageType] = [.auto, .systemMessageUser, .systemMessageAgent]
    }
    
    enum MessageStatus: Int {
        
        case failed = 0
        case pending = 1
        case success = 2
    }
    
    var id: Int?
    var uuid: String? // Used to identify pending or failed messages.
    
    var time: Date!
    var message: String!
    var imageURL: URL?
    var type: MessageType!
    var agent: Agent?
    
    var image: UIImage?
    var imageData: Data?
    var status: MessageStatus = .success
    
    public init() {
        self.uuid = NSUUID().uuidString
        self.time = Date()
    }

    public required init?(map: Map) {
        //
    }

    public func mapping(map: Map) {
        self.id <- map["id"]
        if self.id == nil {
            self.id <- map["messageId"]
        }
        if self.id == nil {
            self.id <- (map["messageId"], StringToIntTransform())
        }
        self.uuid <- map["uuid"]
        self.time <- (map["time"], TimeIntervalSince1970DateTransform())
        self.message <- map["message"]
        self.imageURL <- (map["image"], StringToURLTransform())
        self.type <- (map["typeId"], EnumTransform<MessageType>())
        self.status <- (map["status"], EnumTransform<MessageStatus>())
        self.agent <- map["agent"]
    }

    public static func == (lhs: Message, rhs: Message) -> Bool {
        if let uuid = rhs.uuid {
            return lhs.uuid == uuid
        } else {
            return lhs.id == rhs.id
        }
    }
}

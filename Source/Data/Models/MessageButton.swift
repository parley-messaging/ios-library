import ObjectMapper

public class MessageButton: Mappable, Equatable {
   
    var title: String!
    var payload: String!
    var type: MessageButtonType!
    
    public init() {
        //
    }

    public required init?(map: Map) {
        //
    }

    public func mapping(map: Map) {
        self.title      <- map["title"]
        self.payload    <- map["payload"]
        self.type       <- map["type"]
    }
    
    public static func == (lhs: MessageButton, rhs: MessageButton) -> Bool {
        if lhs.title == rhs.title, lhs.payload == rhs.payload, lhs.type == rhs.type {
            return true
        } else {
            return false
        }
    }
}

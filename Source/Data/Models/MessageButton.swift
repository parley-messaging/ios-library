import ObjectMapper

public class MessageButton: Mappable {
    
    var title: String!
    var payload: String!
    
    public init() {
        //
    }

    public required init?(map: Map) {
        //
    }

    public func mapping(map: Map) {
        self.title      <- map["title"]
        self.payload    <- map["payload"]
    }
}

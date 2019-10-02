import ObjectMapper

internal class MessageCollection: Mappable {
    
    internal class Paging: Mappable {
        
        var before: String!
        var after: String!
        
        required init?(map: Map) {
            //
        }
        
        func mapping(map: Map) {
            self.before <- map["before"]
            self.after <- map["after"]
        }
    }
    
    var messages: [Message]!
    var agent: Agent?
    var paging: Paging!
    var stickyMessage: String?
    var welcomeMessage: String?
    
    required init?(map: Map) {
        //
    }
    
    func mapping(map: Map) {
        self.messages <- map["data"]
        self.agent <- map["agent"]
        self.paging <- map["paging"]
        self.stickyMessage <- map["stickyMessage"]
        self.welcomeMessage <- map["welcomeMessage"]
    }
}

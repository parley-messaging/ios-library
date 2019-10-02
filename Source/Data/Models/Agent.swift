import ObjectMapper

class Agent: Mappable {
    
    var id: Int!
    var name: String!
    var avatar: String!
    
    init() {
        //
    }
    
    required init?(map: Map) {
        //
    }
    
    func mapping(map: Map) {
        self.id <- map["id"]
        self.name <- map["name"]
        self.avatar <- map["avatar"]
    }
}

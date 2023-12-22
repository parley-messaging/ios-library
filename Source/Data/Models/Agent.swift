import Foundation

struct Agent: Codable, Equatable {
    var id: Int?
    var name: String?
    var avatar: String?
    
    init(id: Int? = nil, name: String? = nil, avatar: String? = nil) {
        self.id = id
        self.name = name
        self.avatar = avatar
    }
}

import Foundation

struct Agent: Codable, Equatable {
    var id: Int
    var name: String?
    var avatar: String?
    
    init(id: Int, name: String?, avatar: String?) {
        self.id = id
        self.name = name
        self.avatar = avatar
    }
}

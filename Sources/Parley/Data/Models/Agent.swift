import Foundation

struct Agent: Equatable {
    let id: Int
    let name: String?
    let avatar: String?

    init(id: Int, name: String?, avatar: String?) {
        self.id = id
        self.name = name
        self.avatar = avatar
    }
}

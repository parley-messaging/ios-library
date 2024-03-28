import Foundation

struct RemoteImage: Identifiable {
    let id: String
    let type: ParleyImageType

    init(id: String, type: ParleyImageType) {
        self.id = id
        self.type = type
    }
}

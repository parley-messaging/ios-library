import Foundation

public struct RemoteImage: Identifiable {
    public let id: String
    let type: ParleyImageType
    
    init(id: String, type: ParleyImageType) {
        self.id = id
        self.type = type
    }
}

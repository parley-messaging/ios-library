import Foundation

struct ParleyErrorResponse: Error, Codable {
    let status: String
    let notifications: [Notification]
    let metadata: Metadata?
    
    struct Notification: Codable {
        let type: String
        let message: String
    }
    
    struct Metadata: Codable {
//        let values: [String: Any]
        let method: String
        let duration: Double
    }
}

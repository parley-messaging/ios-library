import Foundation

struct ParleyErrorResponse: Error, Codable {
    enum Status: String, Codable {
        case success = "SUCCESS"
        case error = "ERROR"
    }

    let status: Status
    let notifications: [Notification]
    let metadata: Metadata?

    struct Notification: Codable {
        let type: String
        let message: String
    }

    struct Metadata: Codable {
        let method: String
        let duration: Double
    }
}

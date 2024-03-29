import Foundation

struct ParleyResponse<C: Codable>: Codable {
    let data: C
}

enum ParleyResponseKeyPath {
    case data
}

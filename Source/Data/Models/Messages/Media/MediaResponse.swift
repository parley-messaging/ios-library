import UIKit

struct MediaResponse: Codable {
    let media: String
}

struct ParleyResponse<C: Codable>: Codable {
    let data: C
}



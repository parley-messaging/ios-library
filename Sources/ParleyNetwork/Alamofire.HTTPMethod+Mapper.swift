import Foundation
import Alamofire
import enum Parley.ParleyHTTPRequestMethod

extension Alamofire.HTTPMethod {
    init(_ httpMethod: ParleyHTTPRequestMethod) {
        switch httpMethod {
        case .delete:
            self = .delete
        case .get:
            self = .get
        case .head:
            self = .head
        case .post:
            self = .post
        case .put:
            self = .put
        }
    }
}

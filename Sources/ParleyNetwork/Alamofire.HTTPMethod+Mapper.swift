import Foundation
import Alamofire
import enum Parley.HTTPRequestMethod

extension Alamofire.HTTPMethod {
    init(_ httpMethod: HTTPRequestMethod) {
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

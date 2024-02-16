import Foundation
import Parley
import XCTest
import Alamofire
@testable import ParleyNetwork
import enum Parley.HTTPRequestMethod

final class AlamofireHTTPMethodTests: XCTestCase {
    func testMappings() {
        [
            (parleyMethod: HTTPRequestMethod.get, alamofireMethod: Alamofire.HTTPMethod.get),
            (parleyMethod: HTTPRequestMethod.post, alamofireMethod: Alamofire.HTTPMethod.post),
            (parleyMethod: HTTPRequestMethod.delete, alamofireMethod: Alamofire.HTTPMethod.delete),
            (parleyMethod: HTTPRequestMethod.head, alamofireMethod: Alamofire.HTTPMethod.head),
            (parleyMethod: HTTPRequestMethod.put, alamofireMethod: Alamofire.HTTPMethod.put),
        ].forEach {
            XCTAssertEqual(Alamofire.HTTPMethod($0.parleyMethod), $0.alamofireMethod)
        }
    }
}

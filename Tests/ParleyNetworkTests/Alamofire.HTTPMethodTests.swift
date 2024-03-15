import Foundation
import Parley
import XCTest
import Alamofire
@testable import ParleyNetwork
import enum Parley.ParleyHTTPRequestMethod

final class AlamofireHTTPMethodTests: XCTestCase {
    func testMappings() {
        [
            (parleyMethod: ParleyHTTPRequestMethod.get, alamofireMethod: Alamofire.HTTPMethod.get),
            (parleyMethod: ParleyHTTPRequestMethod.post, alamofireMethod: Alamofire.HTTPMethod.post),
            (parleyMethod: ParleyHTTPRequestMethod.delete, alamofireMethod: Alamofire.HTTPMethod.delete),
            (parleyMethod: ParleyHTTPRequestMethod.head, alamofireMethod: Alamofire.HTTPMethod.head),
            (parleyMethod: ParleyHTTPRequestMethod.put, alamofireMethod: Alamofire.HTTPMethod.put),
        ].forEach {
            XCTAssertEqual(Alamofire.HTTPMethod($0.parleyMethod), $0.alamofireMethod)
        }
    }
}

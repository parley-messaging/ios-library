import Alamofire
import Foundation
import Parley
import Testing
@testable import ParleyNetwork

@Suite
struct AlamofireHTTPMethodTests {
    
    @Test(arguments: [
        (parleyMethod: ParleyHTTPRequestMethod.get, alamofireMethod: Alamofire.HTTPMethod.get),
        (parleyMethod: ParleyHTTPRequestMethod.post, alamofireMethod: Alamofire.HTTPMethod.post),
        (parleyMethod: ParleyHTTPRequestMethod.delete, alamofireMethod: Alamofire.HTTPMethod.delete),
        (parleyMethod: ParleyHTTPRequestMethod.head, alamofireMethod: Alamofire.HTTPMethod.head),
        (parleyMethod: ParleyHTTPRequestMethod.put, alamofireMethod: Alamofire.HTTPMethod.put)
    ])
    func testMappings(mapping: (parleyMethod: ParleyHTTPRequestMethod, alamofireMethod: Alamofire.HTTPMethod)) {
        #expect(Alamofire.HTTPMethod(mapping.parleyMethod) == mapping.alamofireMethod)
    }
}

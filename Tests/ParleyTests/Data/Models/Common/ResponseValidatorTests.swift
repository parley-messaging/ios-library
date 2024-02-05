import Foundation
import XCTest
@testable import Parley

final class ResponseValidatorTests: XCTestCase {
    
    private struct ExampleValidator: ResponseValidator {
        let statusCode: Int
    }
    
    func testSuccessValidation() {
        let sut = ExampleValidator(statusCode: 200)
        XCTAssertNoThrow(try sut.validate(statusCode: 200...202))
    }
    
    func testErrorValidation() {
        let sut = ExampleValidator(statusCode: 200)
        XCTAssertThrowsError(try sut.validate(statusCode: 300...399)) { error in
            XCTAssertTrue(error is HTTPResponseError)
        }
    }
}

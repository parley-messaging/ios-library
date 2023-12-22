import Foundation
import XCTest
@testable import Parley

final class DateTimeIntlSince1970DateTests: XCTestCase {

    func testMaping() throws {
        [
            (input: nil, result: nil),
            (input: 0, result: nil),
            (input: -100, result: nil),
            (input: 10, result: Date(timeIntervalSince1970: 10)),
            (input: 1231, result: Date(timeIntervalSince1970: 1231)),
            (input: 81919, result: Date(timeIntervalSince1970: 81919)),
        ].forEach {
            XCTAssertEqual(Date(timeIntSince1970: $0.input), $0.result)
        }
    }
}

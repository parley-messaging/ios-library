import XCTest
@testable import Parley

final class DataAppendTests: XCTestCase {

    func testAppendEmptyString() {
        var sut = Data()
        sut.append("", encoding: .utf8)

        XCTAssertEqual(String(data: sut, encoding: .utf8), "")
    }

    func testAppendString() {
        var sut = Data()
        sut.append("Hello", encoding: .utf8)
        sut.append(" ", encoding: .utf8)
        sut.append("World!", encoding: .utf8)

        XCTAssertEqual(String(data: sut, encoding: .utf8), "Hello World!")
    }
}

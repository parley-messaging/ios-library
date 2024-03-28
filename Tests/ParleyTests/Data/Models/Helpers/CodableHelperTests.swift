import XCTest
@testable import Parley

final class CodableHelperTests: XCTestCase {

    private struct CodableObject: Codable, Equatable {
        let tasks: [String]
    }

    private var sut: CodableHelper!

    override func setUpWithError() throws {
        sut = CodableHelper(decoder: JSONDecoder(), encoder: JSONEncoder())
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    func testToJSONString() throws {
        let result = try sut.toJSONString(CodableObject(tasks: ["1", "2"]))

        XCTAssertEqual(result, "{\"tasks\":[\"1\",\"2\"]}")
    }

    func testEncodeDecode() throws {
        let object = CodableObject(tasks: ["1", "2"])
        let encoded = try sut.encode(object)
        let result = try sut.decode(CodableObject.self, from: encoded)

        XCTAssertEqual(object, result)
    }
}

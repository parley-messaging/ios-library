import Foundation
import Testing
@testable import Parley

@Suite("Data extenion test")
struct DataAppendTests {

    @Test()
    func appendEmptyString() {
        var sut = Data()
        sut.append("", encoding: .utf8)

        #expect(String(data: sut, encoding: .utf8) == "")
    }

    @Test()
    func appendString() {
        var sut = Data()
        sut.append("Hello", encoding: .utf8)
        sut.append(" ", encoding: .utf8)
        sut.append("World!", encoding: .utf8)

        #expect(String(data: sut, encoding: .utf8) == "Hello World!")
    }
}

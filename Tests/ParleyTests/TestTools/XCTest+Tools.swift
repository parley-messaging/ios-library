import XCTest

extension XCTestCase {
    public func wait(
        _ timeout: TimeInterval = 0.2,
        fileID: String = #fileID,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for \(timeout) seconds, \(fileID):\(line)")
        exp.isInverted = true
        wait(for: [exp], timeout: timeout)
    }
}

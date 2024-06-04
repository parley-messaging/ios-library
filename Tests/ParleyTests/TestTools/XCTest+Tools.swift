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

    public func wait(
        _ timeout: TimeInterval = 2.0,
        for expression: @escaping () -> Bool,
        fileID: String = #fileID,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let predicate = NSPredicate { _, _ -> Bool in
            expression()
        }
        let expectation = expectation(for: predicate, evaluatedWith: nil)
        expectation.expectationDescription = "\(fileID):\(line)"
        wait(for: [expectation], timeout: timeout)
    }
}

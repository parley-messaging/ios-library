import Foundation

protocol ResponseValidator {
    var statusCode: Int { get }
    func validate<S: Sequence>(statusCode acceptableStatusCodes: S) throws -> Self where S.Iterator.Element == Int
}

extension ResponseValidator {
    @discardableResult
    func validate<S: Sequence>(statusCode acceptableStatusCodes: S) throws -> Self where S.Iterator.Element == Int {
        if acceptableStatusCodes.contains(statusCode) {
            return self
        } else {
            throw HTTPResponseError.invalidStatusCode
        }
    }
}

import Foundation

public enum HTTPResponseError: Error {
    case dataMissing
    case invalidStatusCode
}

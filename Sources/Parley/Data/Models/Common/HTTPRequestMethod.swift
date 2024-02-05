import Foundation

/// Represents an HTTP request method.
public enum HTTPRequestMethod: String, Codable {
    case get = "GET"
    case head = "HEAD"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

import Foundation

/// Represents an HTTP request method.
public enum ParleyHTTPRequestMethod: String, Codable, Sendable {
    case get = "GET"
    case head = "HEAD"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

import Foundation
import UIKit

public struct HTTPImageResponse: ResponseValidator {
    public let statusCode: Int
    public let headers: [String: String]
    public let body: Data?
    public let image: UIImage

    public init(body: Data?, image: UIImage, statusCode: Int, headers: [String: String]) {
        self.body = body
        self.statusCode = statusCode
        self.headers = headers
        self.image = image
    }
}

import Foundation

/// Be able to make `multipart/form-data` to upload as data in a HTTP or HTTPS body.
/// This implementation supports only images. If you try upload a video
/// your app may run out of memory when trying to encode the dataset.
struct MultipartFormData {

    let boundary: String

    private let separator = "\r\n"
    private var data: Data

    init(boundary: String = UUID().uuidString) {
        self.boundary = boundary
        data = .init()
    }

    private mutating func appendBoundarySeparator() {
        data.append("--\(boundary)\(separator)")
    }

    private mutating func appendSeparator() {
        data.append(separator)
    }

    private func disposition(_ key: String) -> String {
        "Content-Disposition: form-data; name=\"\(key)\""
    }

    mutating func add(
        key: String,
        value: String
    ) {
        appendBoundarySeparator()
        data.append(disposition(key) + separator)
        appendSeparator()
        data.append(value + separator)
    }

    mutating func add(
        key: String,
        fileName: String,
        fileMimeType: String,
        fileData: Data
    ) {
        appendBoundarySeparator()
        data.append(disposition(key) + "; filename=\"\(fileName)\"" + separator)
        data.append("\(HTTPHeaders.contentType.rawValue): \(fileMimeType)" + separator + separator)
        data.append(fileData)
        appendSeparator()
    }

    var httpContentTypeHeaderValue: String {
        "multipart/form-data; boundary=\(boundary)"
    }

    var httpBody: Data {
        var bodyData = data
        bodyData.append("--\(boundary)--")
        return bodyData
    }
}

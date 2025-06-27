import UIKit
import UniformTypeIdentifiers

protocol ParleyComposeViewDelegate: AnyObject {

    @MainActor func didChange()

    @MainActor func send(_ message: String)
    @MainActor func send(image: UIImage, with data: Data, url: URL)
    @MainActor func send(file url: URL)

    @available(iOS 14.0, *)
    @MainActor func send(image: UIImage, data: Data, fileName: String, type: UTType)

    @MainActor func failedToSelectImage()
}

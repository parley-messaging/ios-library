import UIKit
import UniformTypeIdentifiers

protocol ParleyComposeViewDelegate: AnyObject {

    func didChange()

    func send(_ message: String)
    func send(image: UIImage, with data: Data, url: URL)

    @available(iOS 14.0, *)
    func send(image: UIImage, data: Data, fileName: String, type: UTType)

    func failedToSelectImage()
}

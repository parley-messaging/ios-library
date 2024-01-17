import UIKit

protocol ParleyComposeViewDelegate: AnyObject {
    
    func didChange()
    
    func send(_ message: String)
    func send(image: UIImage, with data: Data, url: URL, fileName: String)
}

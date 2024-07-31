import Foundation

protocol ParleyMessageViewDelegate: AnyObject {
    func didSelectMedia(_ media: MediaObject)
    func shareMedia(url: URL)
    func didSelect(_ button: MessageButton)
}

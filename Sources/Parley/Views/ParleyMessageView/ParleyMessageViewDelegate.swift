import Foundation

protocol ParleyMessageViewDelegate: AnyObject {
    @MainActor func didSelectMedia(_ media: MediaObject)
    @MainActor func shareMedia(url: URL)
    @MainActor func didSelect(_ button: MessageButton)
}

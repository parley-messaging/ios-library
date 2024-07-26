protocol ParleyMessageViewDelegate: AnyObject {
    func didSelectMedia(_ media: MediaObject)
    func didSelect(_ button: MessageButton)
}

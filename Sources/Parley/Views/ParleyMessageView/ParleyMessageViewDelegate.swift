protocol ParleyMessageViewDelegate: AnyObject {
    func didSelectImage(messageMediaIdentifier: String)
    func didSelect(_ button: MessageButton)
}

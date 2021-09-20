internal protocol ParleyMessageViewDelegate: AnyObject {
    func didSelectImage(from message: Message)
    func didSelect(_ button: MessageButton)
}

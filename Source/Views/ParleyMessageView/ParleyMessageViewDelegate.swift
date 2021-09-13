internal protocol ParleyMessageViewDelegate: AnyObject {
    
    func didSelectImage(from message: Message)
    func didSelectButton(open url: URL)
}

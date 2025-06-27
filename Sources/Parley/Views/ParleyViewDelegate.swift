public protocol ParleyViewDelegate: AnyObject {
    @MainActor func didSentMessage()
}

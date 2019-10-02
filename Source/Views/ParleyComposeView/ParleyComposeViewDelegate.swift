protocol ParleyComposeViewDelegate {
    
    func didChange()
    
    func send(_ message: String)
    func send(_ url: URL, _ image: UIImage, _ data: Data?)
}

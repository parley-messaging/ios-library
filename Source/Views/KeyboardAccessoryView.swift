protocol KeyboardAccessoryViewDelegate{
    
    func keyboardDidShow(_ frame: CGRect)
    func keyboardFrameChanged(_ frame: CGRect)
    func keyboardDidHide(_ frame: CGRect)
}

class KeyboardAccessoryView: UIView {
    
    var delegate:KeyboardAccessoryViewDelegate?
    private var kvoContext: UInt8 = 1
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardDidShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardDidHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardDidShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardDidHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(UIResponder.keyboardWillShowNotification)
        NotificationCenter.default.removeObserver(UIResponder.keyboardWillHideNotification)
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        if newSuperview == nil {
            self.superview?.removeObserver(self, forKeyPath: "center")
        } else{
            newSuperview?.addObserver(self, forKeyPath: "center", options: [NSKeyValueObservingOptions.new, NSKeyValueObservingOptions.initial], context: &kvoContext)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let theChange = change as [NSKeyValueChangeKey : AnyObject]?{
            if theChange[NSKeyValueChangeKey.newKey] != nil{
                if self.delegate != nil && self.superview?.frame != nil {
                    self.delegate?.keyboardFrameChanged((self.superview?.frame)!)
                }
            }
        }
    }
    
    @objc private func keyboardDidShow(notification: NSNotification) {
        if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            self.delegate?.keyboardDidShow(frame)
        }
    }
    
    @objc private func keyboardDidHide(notification: NSNotification) {
        if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            self.delegate?.keyboardDidHide(frame)
        }
    }
}

import UIKit

internal class AgentTypingTableViewCell: UITableViewCell {
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    @IBOutlet weak var contentTopLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentLeftLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentBottomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentRightLayoutConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var dot1View: UIView!
    @IBOutlet weak var dot2View: UIView!
    @IBOutlet weak var dot3View: UIView!
    
    private var startTimer: Timer?
    
    internal var appearance = AgentTypingTableViewCellAppearance() {
        didSet {
            self.apply(appearance)
        }
    }
    private var animating = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.dot1View.layer.cornerRadius = self.dot1View.bounds.width / 2
        self.dot2View.layer.cornerRadius = self.dot2View.bounds.width / 2
        self.dot3View.layer.cornerRadius = self.dot3View.bounds.width / 2
        
        self.apply(appearance)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.dot1View.transform = CGAffineTransform(scaleX: 1, y: 1)
        self.dot2View.transform = CGAffineTransform(scaleX: 1, y: 1)
        self.dot3View.transform = CGAffineTransform(scaleX: 1, y: 1)
    }
    
    internal func startAnimating() {
        self.stopAnimating()
        
        self.startTimer?.invalidate()
        self.startTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { _ in
            self.animating = true
            
            self.animation1()
        })
    }
    
    internal func stopAnimating() {
        self.animating = false
    }
    
    private func animation1() {
        if !self.animating { return }
        
        UIView.animate(withDuration: 0.2, delay: 0.3, animations: {
            self.dot1View.alpha = 1
            self.dot1View.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }) { (finished) in
            if !finished { return }
            
            self.animation2()
        }
    }
    
    private func animation2() {
        if !self.animating { return }
        
        UIView.animate(withDuration: 0.2, animations: {
            self.dot1View.alpha = 0.5
            self.dot1View.transform = CGAffineTransform(scaleX: 1, y: 1)
            
            self.dot2View.alpha = 1
            self.dot2View.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }) { (finished) in
            if !finished { return }
            
            self.animation3()
        }
    }
    
    private func animation3() {
        if !self.animating { return }
        
        UIView.animate(withDuration: 0.2, animations: {
            self.dot2View.alpha = 0.5
            self.dot2View.transform = CGAffineTransform(scaleX: 1, y: 1)
            
            self.dot3View.alpha = 1
            self.dot3View.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }) { (finished) in
            if !finished { return }
            
            self.animation4()
        }
    }
    
    private func animation4() {
        if !self.animating { return }
        
        UIView.animate(withDuration: 0.2, animations: {
            self.dot3View.alpha = 0.5
            self.dot3View.transform = CGAffineTransform(scaleX: 1, y: 1)
        }) { (finished) in
            if !finished { return }
            
            self.animation1()
        }
    }
    
    internal func apply(_ appearance: AgentTypingTableViewCellAppearance) {
        if let backgroundTintColor = appearance.backgroundTintColor {
            self.backgroundImageView.image = appearance.backgroundImage?.withRenderingMode(.alwaysTemplate)
            self.backgroundImageView.tintColor = backgroundTintColor
        } else {
            self.backgroundImageView.image = appearance.backgroundImage?.withRenderingMode(.alwaysOriginal)
        }
        
        self.contentTopLayoutConstraint.constant = appearance.contentInset?.top ?? 0
        self.contentLeftLayoutConstraint.constant = appearance.contentInset?.left ?? 0
        self.contentBottomLayoutConstraint.constant = appearance.contentInset?.bottom ?? 0
        self.contentRightLayoutConstraint.constant = appearance.contentInset?.right ?? 0
        
        self.dot1View.alpha = 0.5
        self.dot1View.backgroundColor = appearance.dotColor
        
        self.dot2View.alpha = 0.5
        self.dot2View.backgroundColor = appearance.dotColor
        
        self.dot3View.alpha = 0.5
        self.dot3View.backgroundColor = appearance.dotColor
    }
}

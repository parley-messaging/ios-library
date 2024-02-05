import UIKit

class LoadingTableViewCell: UITableViewCell {
    
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    @IBOutlet weak var topLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightLayoutConstraint: NSLayoutConstraint!
    
    var appearance = LoadingTableViewCellAppearance() {
        didSet {
            self.apply(self.appearance)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.apply(self.appearance)
    }
    
    func startAnimating() {
        self.activityIndicatorView.startAnimating()
    }
    
    func stopAnimating() {
        self.activityIndicatorView.stopAnimating()
    }
    
    private func apply(_ appearance: LoadingTableViewCellAppearance) {
        self.activityIndicatorView.color = appearance.loaderTintColor
        
        self.topLayoutConstraint.constant = appearance.contentInset?.top ?? 0
        self.leftLayoutConstraint.constant = appearance.contentInset?.left ?? 0
        self.bottomLayoutConstraint.constant = appearance.contentInset?.bottom ?? 0
        self.rightLayoutConstraint.constant = appearance.contentInset?.right ?? 0
    }
}

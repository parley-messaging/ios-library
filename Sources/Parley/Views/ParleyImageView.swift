import UIKit

final class ParleyImageView: UIImageView {
    
    var corners: UIRectCorner = [.allCorners] {
        didSet {
            if let radius = self.cornerRadius {
                self.roundCorners(corners: self.corners, radius: radius)
            }
        }
    }
    var cornerRadius: CGFloat? {
        didSet {
            if let radius = self.cornerRadius {
                self.roundCorners(corners: self.corners, radius: radius)
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let radius = self.cornerRadius {
            self.roundCorners(corners: self.corners, radius: radius)
        }
    }
    
    private func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}

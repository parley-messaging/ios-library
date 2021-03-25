public class ParleyImageView: UIImageView {
    
    public var corners: UIRectCorner = [.allCorners] {
        didSet {
            if let radius = self.cornerRadius {
                self.roundCorners(corners: self.corners, radius: radius)
            }
        }
    }
    public var cornerRadius: CGFloat? {
        didSet {
            if let radius = self.cornerRadius {
                self.roundCorners(corners: self.corners, radius: radius)
            }
        }
    }
    
    public override func layoutSubviews() {
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

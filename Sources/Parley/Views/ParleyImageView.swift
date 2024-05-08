import UIKit

final class ParleyImageView: UIImageView {

    var corners: UIRectCorner = [.allCorners] {
        didSet {
            if let cornerRadius {
                roundCorners(corners: corners, radius: cornerRadius)
            }
        }
    }

    var cornerRadius: CGFloat? {
        didSet {
            if let cornerRadius {
                roundCorners(corners: corners, radius: cornerRadius)
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if let cornerRadius {
            roundCorners(corners: corners, radius: cornerRadius)
        }
    }

    private func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(
            roundedRect: bounds,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}

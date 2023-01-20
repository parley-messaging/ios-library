import UIKit
import CoreGraphics
import Foundation

extension String {
    
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)

        return ceil(boundingBox.height)
    }
    
//    func height(withConstrainedWidth width: CGFloat, font: UIFont, lines: Int) -> CGFloat {
//        let label =  UILabel(frame: CGRect(x: 0, y: 0, width: width, height: .greatestFiniteMagnitude))
//        label.numberOfLines = lines
//        label.text = self
//        label.font = font
//        label.sizeToFit()
//
//        return label.frame.height
//    }
}

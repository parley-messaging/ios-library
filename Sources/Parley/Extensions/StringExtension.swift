import UIKit
import CoreGraphics
import Foundation

extension String {
    
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        @ParleyScaledFont(textStyle: .body) var scaledFont = font
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(
            with: constraintRect,
            options: .usesLineFragmentOrigin,
            attributes: [.font: scaledFont],
            context: nil
        )

        return ceil(boundingBox.height)
    }
    
    /// Appends a string to the current string while maintaining a maximum of a single space character between words.
    /// - Parameters:
    ///  - string: the string to be appended at the end of `self`.
    ///
    /// - Important: The input string **shouldn't** start with a space.
    mutating func appendWithCorrectSpacing(_ string: String) {
        guard !string.isEmpty else { return }
        guard !isEmpty else { self = string ; return }
        
        if let lastCharacter = self.last, lastCharacter != " " {
            self.append(" ")
        }
        
        self.append(string)
    }
}

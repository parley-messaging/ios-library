import UIKit

public struct InfoTableViewCellAppearance: Sendable {
    @MainActor public var textViewAppearance: ParleyTextViewAppearance
    public var contentInset: UIEdgeInsets?
    public var position: Position
    
    public enum Position: Sendable {
        case legacy
        case adaptive
    }
    
    @MainActor
    init(
        textViewAppearance: ParleyTextViewAppearance = ParleyTextViewAppearance(textColor: UIColor(red: 0.29, green: 0.37, blue: 0.51, alpha: 1.0)),
        contentInset: UIEdgeInsets? = UIEdgeInsets(top: 16, left: 32, bottom: 16, right: 32),
        position: Position = .adaptive
    ) {
        self.textViewAppearance = textViewAppearance
        self.contentInset = contentInset
        self.position = position
    }
}

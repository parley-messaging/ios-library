import UIKit

@propertyWrapper public struct ParleyScaledFont {
    private let textStyle: UIFont.TextStyle
    private var originalFont: UIFont
    private var scaledFont: UIFont!
    
    public var wrappedValue: UIFont {
        get {
            scaledFont
        } set {
            originalFont = UIFont(name: newValue.fontName, size: newValue.pointSize)!
            scaledFont = scaled()
        }
    }

    internal init(wrappedValue defaultValue: UIFont, textStyle: UIFont.TextStyle) {
        if let defaultFont = UIFont(name: defaultValue.fontName, size: defaultValue.pointSize) {
            self.originalFont = defaultFont
            self.textStyle = textStyle
            self.scaledFont = scaled()
        } else {
            fatalError("Could not construct font.")
        }
    }
    
    private func scaled() -> UIFont {
        UIFontMetrics(forTextStyle: textStyle).scaledFont(for: originalFont)
    }
}

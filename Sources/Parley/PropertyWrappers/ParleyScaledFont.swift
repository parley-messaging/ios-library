import UIKit

@propertyWrapper public struct ParleyScaledFont {
    private let textStyle: UIFont.TextStyle
    private var originalFont: UIFont
    private var scaledFont: UIFont
    
    public var wrappedValue: UIFont {
        get {
            scaledFont
        } set {
            originalFont = UIFont(name: newValue.fontName, size: newValue.pointSize)!
            self.scaledFont = Self.scaled(textStyle: textStyle, originalFont: originalFont)
        }
    }

    init(wrappedValue defaultValue: UIFont, textStyle: UIFont.TextStyle) {
        if let defaultFont = UIFont(name: defaultValue.fontName, size: defaultValue.pointSize) {
            self.originalFont = defaultFont
            self.textStyle = textStyle
            self.scaledFont = Self.scaled(textStyle: textStyle, originalFont: defaultFont)
        } else {
            fatalError("Could not construct font.")
        }
    }
    
    private static func scaled(textStyle: UIFont.TextStyle, originalFont: UIFont) -> UIFont {
        UIFontMetrics(forTextStyle: textStyle).scaledFont(for: originalFont)
    }
}

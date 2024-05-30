import UIKit

@propertyWrapper
public struct ParleyScaledFont {
    private let textStyle: UIFont.TextStyle
    private var scaledFont: UIFont

    public var wrappedValue: UIFont {
        get {
            scaledFont
        } set {
            scaledFont = Self.scaled(
                textStyle: textStyle,
                originalFontDescriptor: newValue.fontDescriptor
            )
        }
    }

    init(wrappedValue defaultValue: UIFont, textStyle: UIFont.TextStyle) {
        self.textStyle = textStyle

        scaledFont = Self.scaled(textStyle: textStyle, originalFontDescriptor: defaultValue.fontDescriptor)
    }

    private static func scaled(textStyle: UIFont.TextStyle, originalFontDescriptor: UIFontDescriptor) -> UIFont {
        UIFontMetrics(forTextStyle: textStyle).scaledFont(for: UIFont(
            descriptor: originalFontDescriptor,
            size: 0
        ))
    }
}

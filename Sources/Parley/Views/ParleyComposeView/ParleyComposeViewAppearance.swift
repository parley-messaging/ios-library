import UIKit

public struct ParleyComposeViewAppearance {

    public var backgroundColor = UIColor(white: 0.92, alpha: 1.0)

    public var inputBackgroundColor = UIColor.white
    public var inputBorderColor = UIColor(white: 0.87, alpha: 1.0)

    @available(*, deprecated, renamed: "mediaIcon", message: "Replace with `mediaIcon` instead.")
    public var cameraIcon: UIImage {
        get {
            mediaIcon
        }
        set {
            mediaIcon = cameraIcon
        }
    }

    @available(*, deprecated, renamed: "mediaTintColor", message: "Replace with `mediaTintColor` instead.")
    public var cameraTintColor: UIColor {
        get {
            mediaTintColor
        }
        set {
            mediaTintColor = cameraTintColor
        }
    }

    public var mediaIcon: UIImage
    public var mediaTintColor = UIColor(red: 0.29, green: 0.37, blue: 0.51, alpha: 1.0)

    public var sendIcon: UIImage
    public var sendBackgroundColor = UIColor(red: 0.29, green: 0.37, blue: 0.51, alpha: 1.0)
    public var sendTintColor: UIColor? = UIColor.white

    public var textColor = UIColor.black
    public var tintColor = UIColor(red: 0.29, green: 0.37, blue: 0.51, alpha: 1.0)
    public var placeholderColor = UIColor(red: 0.64, green: 0.67, blue: 0.68, alpha: 1.0)
    @ParleyScaledFont(textStyle: .headline) public var font = .systemFont(ofSize: 17, weight: .regular)

    init() {
        mediaIcon = UIImage(named: "ic_add", in: .module, compatibleWith: nil)!
        sendIcon = UIImage(named: "ic_send", in: .module, compatibleWith: nil)!
    }
}

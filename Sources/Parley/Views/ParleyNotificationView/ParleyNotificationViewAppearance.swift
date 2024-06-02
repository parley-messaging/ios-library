import UIKit

public class ParleyNotificationViewAppearance {

    public var show = true
    public var backgroundColor = UIColor(red: 0.81, green: 0.81, blue: 0.8, alpha: 1.0)
    public var icon: UIImage
    public var iconTintColor: UIColor? = UIColor.white

    public var textColor = UIColor.white
    @ParleyScaledFont(textStyle: .body) public var font = .systemFont(ofSize: 13, weight: .regular)

    init(icon: UIImage) {
        self.icon = icon
    }
}

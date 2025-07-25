import UIKit

@available(*, deprecated, renamed: "DateHeaderAppearance", message: "Please use DateHeaderAppearance instead")
public typealias DateTableViewCellAppearance = DateHeaderAppearance

public struct DateHeaderAppearance: Sendable {

    public var backgroundColor = UIColor(red: 0.29, green: 0.37, blue: 0.51, alpha: 0.5)
    public var cornerRadius: Float = 5

    @ParleyScaledFont(textStyle: .callout)
    public var textFont = .systemFont(ofSize: 10, weight: .bold)
    
    public var textColor = UIColor.white

    public var contentInset: UIEdgeInsets? = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
    
    public var style: DateFormatter.Style = .medium
}

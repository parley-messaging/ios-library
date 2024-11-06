import UIKit

public class AgentTypingTableViewCellAppearance {
    
    public struct DotsAppearance {
        
        public var color: UIColor
        public var spacing: CGFloat
        public var size: CGFloat
        public private(set) var transparency: (min: Double, max: Double)
        public var animationCurve: UIView.AnimationCurve
        public var animationScaleFactor: CGFloat
        public var animationInterval: TimeInterval
        
        /// Style the visual appearance of the three animated dots
        /// - Parameters:
        ///   - color: The color for all dots (at full opacity)
        ///   - spacing: The distance between the dots
        ///   - size: The size of each dot
        ///   - transparency: The minimum and maximum transparency levels
        ///   - animationCurve: The animation curve utilized during the color and size transformations
        ///   - animationScaleFactor: The scale factor applied to each dot
        ///   - animationInterval: The total duration it takes for all the dots to animate
        public init(
            color: UIColor = .black,
            spacing: CGFloat = 4,
            size: CGFloat = 8,
            transparency: (min: Double, max: Double) = (0.2, 1.0),
            animationCurve: UIView.AnimationCurve = .easeInOut,
            animationScaleFactor: CGFloat = 1.3,
            animationInterval: TimeInterval = 1.2
        ) {
            self.color = color
            self.spacing = spacing
            self.size = size
            self.transparency = (min: max(0, transparency.min), max: min(1, transparency.max))
            self.animationCurve = animationCurve
            self.animationScaleFactor = animationScaleFactor
            self.animationInterval = animationInterval
        }
        
        public mutating func setTransparency(minimum: Double, maximum: Double) {
            self.transparency = (min: max(0, minimum), max: min(1, maximum))
        }
    }

    public var backgroundImage: UIImage?
    public var backgroundTintColor: UIColor? = UIColor.white

    public var contentInset: UIEdgeInsets? = UIEdgeInsets(top: 3, left: 15, bottom: 3, right: 13)

    public var dots = DotsAppearance()
    
    @available(*, deprecated, message: "Use the dot property instead")
    public var dotColor: UIColor {
        get { dots.color }
        set { dots.color = newValue }
    }

    init() {
        let edgeInsets = UIEdgeInsets(top: 21, left: 23, bottom: 21, right: 21)
        backgroundImage = UIImage(named: "agent_balloon", in: .module, compatibleWith: nil)?
            .resizableImage(withCapInsets: edgeInsets)
    }
}

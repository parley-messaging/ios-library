import UIKit

final class AgentTypingTableViewCell: UITableViewCell {

    @IBOutlet weak var backgroundImageView: UIImageView!

    @IBOutlet weak var contentTopLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentLeftLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentBottomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentRightLayoutConstraint: NSLayoutConstraint!

    @IBOutlet weak var dotContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var dot1View: UIView!
    @IBOutlet weak var dot2View: UIView!
    @IBOutlet weak var dot3View: UIView!
    
    // Added options for changing the appearance of the agent typing indicator
    
    // Spacing Constrtaints
    @IBOutlet weak var firstDotToSecondDotConstraint: NSLayoutConstraint!
    @IBOutlet weak var secondDotToThirdDotConstraint: NSLayoutConstraint!
    
    @IBOutlet var dotSizeConstraints: [NSLayoutConstraint]!
    
    private var startTimer: Timer?

    var appearance = AgentTypingTableViewCellAppearance() {
        didSet {
            apply(appearance)
        }
    }
    
    private var affineTransform: CGAffineTransform {
        let scaleFactor = appearance.dots.animationScaleFactor
        return CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
    }
    
    private var animationOptions: UIView.AnimationOptions {
        switch appearance.dots.animationCurve {
        case .easeInOut: return .curveEaseInOut
        case .easeIn: return .curveEaseIn
        case .easeOut: return .curveEaseOut
        case .linear: return .curveLinear
        @unknown default: return .curveEaseInOut
        }
    }

    private var animating = false

    override func awakeFromNib() {
        super.awakeFromNib()
        MainActor.assumeIsolated {
            accessibilityLabel = ParleyLocalizationKey.voiceOverMessageAgentIsTyping.localized()
            apply(appearance)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        dot1View.transform = .identity
        dot2View.transform = .identity
        dot3View.transform = .identity
    }

    @MainActor
    func startAnimating() {
        stopAnimating()

        startTimer?.invalidate()
        startTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { [weak self] _ in
            MainActor.assumeIsolated {
                self?.animating = true
                self?.animation1()
            }
        })
    }

    func stopAnimating() {
        animating = false
    }

    private func animation1() {
        guard animating else { return }

        animate { [weak self] in
            guard let self else { return }
            dot1View.alpha = appearance.dots.transparency.max
            dot1View.transform = affineTransform
        } completion: { [weak self] finished in
            guard finished else { return }
            self?.animation2()
        }
    }

    private func animation2() {
        guard animating else { return }

        animate { [weak self] in
            guard let self else { return }
            dot1View.alpha = appearance.dots.transparency.min
            dot1View.transform = .identity

            dot2View.alpha = appearance.dots.transparency.max
            dot2View.transform = affineTransform
        } completion: { [weak self] finished in
            guard finished else { return }
            self?.animation3()
        }
    }

    private func animation3() {
        guard animating else { return }

        animate { [weak self] in
            guard let self else { return }
            dot2View.alpha = appearance.dots.transparency.min
            dot2View.transform = .identity

            dot3View.alpha = appearance.dots.transparency.max
            dot3View.transform = affineTransform
        } completion: { [weak self] finished in
            guard finished else { return }

            self?.animation4()
        }
    }

    private func animation4() {
        guard animating else { return }
        
        animate { [weak self] in
            guard let self else { return }
            dot3View.alpha = appearance.dots.transparency.min
            dot3View.transform = .identity
        } completion: { [weak self] finished in
            guard finished else { return }

            self?.animation1()
        }
    }
    
    private func animate(animations: @escaping () -> Void, completion:  @escaping (Bool) -> Void) {
        UIView.animate(
            withDuration: appearance.dots.animationInterval / 4,
            delay: .zero,
            options: animationOptions,
            animations: animations,
            completion: completion
        )
    }

    private func apply(_ appearance: AgentTypingTableViewCellAppearance) {
        if let backgroundTintColor = appearance.backgroundTintColor {
            backgroundImageView.image = appearance.backgroundImage?.withRenderingMode(.alwaysTemplate)
            backgroundImageView.tintColor = backgroundTintColor
        } else {
            backgroundImageView.image = appearance.backgroundImage?.withRenderingMode(.alwaysOriginal)
        }

        contentTopLayoutConstraint.constant = appearance.contentInset?.top ?? 0
        contentLeftLayoutConstraint.constant = appearance.contentInset?.left ?? 0
        contentBottomLayoutConstraint.constant = appearance.contentInset?.bottom ?? 0
        contentRightLayoutConstraint.constant = appearance.contentInset?.right ?? 0

        dot1View.alpha = appearance.dots.transparency.min
        dot1View.backgroundColor = appearance.dots.color

        dot2View.alpha = appearance.dots.transparency.min
        dot2View.backgroundColor = appearance.dots.color

        dot3View.alpha = appearance.dots.transparency.min
        dot3View.backgroundColor = appearance.dots.color
        
        firstDotToSecondDotConstraint.constant = appearance.dots.spacing
        secondDotToThirdDotConstraint.constant = appearance.dots.spacing
        
        for constraint in dotSizeConstraints {
            constraint.constant = appearance.dots.size
        }
        
        dot1View.layer.cornerRadius = appearance.dots.size / 2
        dot2View.layer.cornerRadius = appearance.dots.size / 2
        dot3View.layer.cornerRadius = appearance.dots.size / 2
        
        dotContainerHeightConstraint.constant = appearance.dots.size * appearance.dots.animationScaleFactor
    }
}

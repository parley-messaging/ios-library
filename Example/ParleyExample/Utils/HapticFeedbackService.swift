import UIKit

@MainActor
final class HapticFeedbackService {
    
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat = 1) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred(intensity: intensity)
    }
    
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    func impact(generator: UIImpactFeedbackGenerator, intensity: CGFloat = 1) {
        generator.impactOccurred(intensity: intensity)
    }

    func notification(generator: UINotificationFeedbackGenerator, type: UINotificationFeedbackGenerator.FeedbackType) {
        generator.notificationOccurred(type)
    }
}

// MARK: Feedback preparation
extension HapticFeedbackService {
    
    func prepareImpact(style: UIImpactFeedbackGenerator.FeedbackStyle) -> UIImpactFeedbackGenerator {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        return generator
    }
    
    func prepareNotification() -> UINotificationFeedbackGenerator {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        return generator
    }
}

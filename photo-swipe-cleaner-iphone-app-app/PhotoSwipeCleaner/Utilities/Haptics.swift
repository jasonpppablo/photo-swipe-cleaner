import UIKit

enum Haptics {
    static func impact(enabled: Bool, style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard enabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    static func notification(enabled: Bool, type: UINotificationFeedbackGenerator.FeedbackType) {
        guard enabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}

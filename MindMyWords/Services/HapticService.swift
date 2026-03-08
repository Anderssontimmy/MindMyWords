import UIKit

enum HapticIntensity: Int, CaseIterable, Codable {
    case light = 1
    case medium = 2
    case strong = 3

    var label: String {
        switch self {
        case .light: "Light"
        case .medium: "Medium"
        case .strong: "Strong"
        }
    }

    var feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle {
        switch self {
        case .light: .light
        case .medium: .medium
        case .strong: .heavy
        }
    }
}

final class HapticService {
    static let shared = HapticService()
    private init() {}

    func trigger(intensity: HapticIntensity) {
        let generator = UIImpactFeedbackGenerator(style: intensity.feedbackStyle)
        generator.prepare()
        generator.impactOccurred()
    }

    func notificationFeedback(_ type: UINotificationFeedbackGenerator.FeedbackType = .warning) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}

import AVFoundation

enum SoundEffect: String, CaseIterable, Codable {
    case ding = "ding"
    case buzzer = "buzzer"
    case pop = "pop"

    var label: String {
        switch self {
        case .ding: "Ding"
        case .buzzer: "Buzzer"
        case .pop: "Pop"
        }
    }

    /// System sound ID for built-in sounds (no custom audio files needed)
    var systemSoundID: SystemSoundID {
        switch self {
        case .ding: 1057    // Tink
        case .buzzer: 1073  // Alarm buzzer
        case .pop: 1104     // Key press click
        }
    }
}

final class SoundService {
    static let shared = SoundService()
    private init() {}

    func play(effect: SoundEffect) {
        AudioServicesPlaySystemSound(effect.systemSoundID)
    }
}

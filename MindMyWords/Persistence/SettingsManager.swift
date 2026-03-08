import Foundation

@MainActor
final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    private let defaults = UserDefaults.standard

    // MARK: - Keys
    private enum Keys {
        static let vibrationEnabled = "vibrationEnabled"
        static let vibrationIntensity = "vibrationIntensity"
        static let soundEnabled = "soundEnabled"
        static let soundEffect = "soundEffect"
        static let selectedLanguage = "selectedLanguage"
        static let streakCleanDays = "streakCleanDays"
        static let streakBest = "streakBest"
        static let lastDetectionDate = "lastDetectionDate"
        static let lastCleanCheckDate = "lastCleanCheckDate"
        static let onboardingComplete = "onboardingComplete"
    }

    // MARK: - Published Properties
    @Published var vibrationEnabled: Bool {
        didSet { defaults.set(vibrationEnabled, forKey: Keys.vibrationEnabled) }
    }
    @Published var vibrationIntensity: HapticIntensity {
        didSet { defaults.set(vibrationIntensity.rawValue, forKey: Keys.vibrationIntensity) }
    }
    @Published var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: Keys.soundEnabled) }
    }
    @Published var soundEffect: SoundEffect {
        didSet { defaults.set(soundEffect.rawValue, forKey: Keys.soundEffect) }
    }
    @Published var selectedLanguage: String {
        didSet { defaults.set(selectedLanguage, forKey: Keys.selectedLanguage) }
    }
    @Published var streakCleanDays: Int {
        didSet { defaults.set(streakCleanDays, forKey: Keys.streakCleanDays) }
    }
    @Published var streakBest: Int {
        didSet { defaults.set(streakBest, forKey: Keys.streakBest) }
    }
    @Published var onboardingComplete: Bool {
        didSet { defaults.set(onboardingComplete, forKey: Keys.onboardingComplete) }
    }

    private init() {
        // Register defaults
        defaults.register(defaults: [
            Keys.vibrationEnabled: true,
            Keys.vibrationIntensity: HapticIntensity.medium.rawValue,
            Keys.soundEnabled: true,
            Keys.soundEffect: SoundEffect.ding.rawValue,
            Keys.selectedLanguage: Locale.current.language.languageCode?.identifier ?? "en",
            Keys.streakCleanDays: 0,
            Keys.streakBest: 0,
            Keys.onboardingComplete: false,
        ])

        self.vibrationEnabled = defaults.bool(forKey: Keys.vibrationEnabled)
        self.vibrationIntensity = HapticIntensity(rawValue: defaults.integer(forKey: Keys.vibrationIntensity)) ?? .medium
        self.soundEnabled = defaults.bool(forKey: Keys.soundEnabled)
        self.soundEffect = SoundEffect(rawValue: defaults.string(forKey: Keys.soundEffect) ?? "") ?? .ding
        self.selectedLanguage = defaults.string(forKey: Keys.selectedLanguage) ?? "en"
        self.streakCleanDays = defaults.integer(forKey: Keys.streakCleanDays)
        self.streakBest = defaults.integer(forKey: Keys.streakBest)
        self.onboardingComplete = defaults.bool(forKey: Keys.onboardingComplete)
    }

    // MARK: - Streak Logic

    func breakStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastDate = defaults.object(forKey: Keys.lastDetectionDate) as? Date

        // Only break once per calendar day
        if let lastDate, Calendar.current.isDate(lastDate, inSameDayAs: today) {
            return
        }

        defaults.set(today, forKey: Keys.lastDetectionDate)
        streakCleanDays = 0
    }

    func checkAndIncrementStreak() {
        let todayString = dateString(from: Date())
        let lastCheck = defaults.string(forKey: Keys.lastCleanCheckDate) ?? ""

        guard lastCheck != todayString else { return }

        let lastDetection = defaults.object(forKey: Keys.lastDetectionDate) as? Date
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

        // If no detection yesterday, increment streak
        if lastDetection == nil || !Calendar.current.isDate(lastDetection!, inSameDayAs: yesterday) {
            streakCleanDays += 1
            if streakCleanDays > streakBest {
                streakBest = streakCleanDays
            }
        }

        defaults.set(todayString, forKey: Keys.lastCleanCheckDate)
    }

    func clearAllData() {
        let domain = Bundle.main.bundleIdentifier!
        defaults.removePersistentDomain(forName: domain)
    }

    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

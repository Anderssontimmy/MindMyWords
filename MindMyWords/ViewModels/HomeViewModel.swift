import Foundation
import SwiftData
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var isListening = false
    @Published var currentTranscript = ""
    @Published var flashDetection = false
    @Published var lastDetectedWord = ""
    @Published var todayCount = 0

    private let speechService: SpeechRecognitionService
    private let settings: SettingsManager
    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()

    init(settings: SettingsManager = .shared) {
        self.settings = settings
        self.speechService = SpeechRecognitionService(
            locale: Locale(identifier: settings.selectedLanguage)
        )
        setupBindings()
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        refreshTodayCount()
    }

    func requestPermissions() async -> Bool {
        await speechService.requestPermissions()
    }

    func toggleListening() {
        if isListening {
            speechService.stopListening()
            isListening = false
        } else {
            loadTriggerWords()
            speechService.startListening()
            isListening = true
        }
    }

    func stopListening() {
        speechService.stopListening()
        isListening = false
    }

    // MARK: - Private

    private func setupBindings() {
        speechService.$currentTranscript
            .receive(on: RunLoop.main)
            .assign(to: &$currentTranscript)

        speechService.$status
            .receive(on: RunLoop.main)
            .map { $0 == .listening }
            .assign(to: &$isListening)

        speechService.onDetection = { [weak self] detections in
            Task { @MainActor in
                self?.handleDetections(detections)
            }
        }
    }

    private func loadTriggerWords() {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<TriggerWord>(
            predicate: #Predicate { $0.isActive }
        )
        let words = (try? modelContext.fetch(descriptor)) ?? []
        speechService.triggerWords = words.map(\.phrase)
    }

    private func handleDetections(_ detections: [DetectionResult]) {
        guard let modelContext else { return }

        for detection in detections {
            // Log to database
            let log = DetectionLog(word: detection.word)
            modelContext.insert(log)

            // Feedback
            if settings.vibrationEnabled {
                HapticService.shared.trigger(intensity: settings.vibrationIntensity)
            }
            if settings.soundEnabled {
                SoundService.shared.play(effect: settings.soundEffect)
            }

            lastDetectedWord = detection.word
        }

        try? modelContext.save()

        // Break streak
        settings.breakStreak()

        // Flash animation
        flashDetection = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.flashDetection = false
        }

        refreshTodayCount()
    }

    private func refreshTodayCount() {
        guard let modelContext else { return }
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<DetectionLog>(
            predicate: #Predicate { $0.timestamp >= startOfDay }
        )
        todayCount = (try? modelContext.fetchCount(descriptor)) ?? 0
    }
}

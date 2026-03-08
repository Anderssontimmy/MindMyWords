import Foundation
import SwiftData

struct SupportedLanguage: Identifiable, Hashable {
    let id: String  // locale identifier
    let name: String
}

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var settings: SettingsManager

    let supportedLanguages: [SupportedLanguage] = [
        SupportedLanguage(id: "en-US", name: "English (US)"),
        SupportedLanguage(id: "en-GB", name: "English (UK)"),
        SupportedLanguage(id: "sv-SE", name: "Svenska"),
        SupportedLanguage(id: "de-DE", name: "Deutsch"),
        SupportedLanguage(id: "es-ES", name: "Español"),
        SupportedLanguage(id: "fr-FR", name: "Français"),
        SupportedLanguage(id: "it-IT", name: "Italiano"),
        SupportedLanguage(id: "pt-BR", name: "Português"),
        SupportedLanguage(id: "nl-NL", name: "Nederlands"),
        SupportedLanguage(id: "da-DK", name: "Dansk"),
        SupportedLanguage(id: "nb-NO", name: "Norsk"),
        SupportedLanguage(id: "fi-FI", name: "Suomi"),
        SupportedLanguage(id: "ja-JP", name: "日本語"),
        SupportedLanguage(id: "zh-CN", name: "中文"),
        SupportedLanguage(id: "ko-KR", name: "한국어"),
    ]

    private var modelContext: ModelContext?

    init(settings: SettingsManager = .shared) {
        self.settings = settings
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    func clearAllData() {
        guard let modelContext else { return }

        do {
            try modelContext.delete(model: DetectionLog.self)
            try modelContext.delete(model: TriggerWord.self)
            try modelContext.save()
        } catch {
            print("Failed to clear data: \(error)")
        }

        settings.clearAllData()
    }
}

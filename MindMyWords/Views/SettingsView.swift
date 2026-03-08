import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showClearConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                // Language
                Section("Language") {
                    Picker("Recognition Language", selection: $viewModel.settings.selectedLanguage) {
                        ForEach(viewModel.supportedLanguages) { lang in
                            Text(lang.name).tag(lang.id)
                        }
                    }
                }

                // Feedback
                Section("Feedback") {
                    Toggle("Vibration", isOn: $viewModel.settings.vibrationEnabled)

                    if viewModel.settings.vibrationEnabled {
                        Picker("Intensity", selection: $viewModel.settings.vibrationIntensity) {
                            ForEach(HapticIntensity.allCases, id: \.self) { intensity in
                                Text(intensity.label).tag(intensity)
                            }
                        }

                        Button("Test Vibration") {
                            HapticService.shared.trigger(intensity: viewModel.settings.vibrationIntensity)
                        }
                    }

                    Toggle("Sound", isOn: $viewModel.settings.soundEnabled)

                    if viewModel.settings.soundEnabled {
                        Picker("Sound Effect", selection: $viewModel.settings.soundEffect) {
                            ForEach(SoundEffect.allCases, id: \.self) { effect in
                                Text(effect.label).tag(effect)
                            }
                        }

                        Button("Test Sound") {
                            SoundService.shared.play(effect: viewModel.settings.soundEffect)
                        }
                    }
                }

                // Data
                Section("Data") {
                    Button("Clear All Data", role: .destructive) {
                        showClearConfirmation = true
                    }
                }

                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Speech Engine")
                        Spacer()
                        Text("Apple On-Device")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
            .confirmationDialog(
                "Clear All Data?",
                isPresented: $showClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear Everything", role: .destructive) {
                    viewModel.clearAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will delete all your trigger words, detection history, and settings. This cannot be undone.")
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [TriggerWord.self, DetectionLog.self], inMemory: true)
}

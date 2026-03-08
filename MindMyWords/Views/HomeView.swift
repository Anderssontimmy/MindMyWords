import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = HomeViewModel()
    @State private var showWordList = false
    @State private var permissionGranted = true
    @Query(filter: #Predicate<TriggerWord> { $0.isActive }) private var activeWords: [TriggerWord]

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: viewModel.flashDetection
                        ? [.red.opacity(0.3), .orange.opacity(0.2)]
                        : [Color(.systemBackground), Color(.systemGroupedBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.3), value: viewModel.flashDetection)

                VStack(spacing: 24) {
                    // Streak display
                    StreakBadge(days: SettingsManager.shared.streakCleanDays)

                    Spacer()

                    // Main listen button
                    ListenButton(
                        isListening: viewModel.isListening,
                        flashDetection: viewModel.flashDetection
                    ) {
                        viewModel.toggleListening()
                    }

                    // Status text
                    if viewModel.isListening {
                        VStack(spacing: 8) {
                            Text("Listening...")
                                .font(.headline)
                                .foregroundStyle(.secondary)

                            if !viewModel.currentTranscript.isEmpty {
                                Text(viewModel.currentTranscript.suffix(100))
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                    }

                    // Last detection
                    if !viewModel.lastDetectedWord.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("Detected: \"\(viewModel.lastDetectedWord)\"")
                                .font(.subheadline.bold())
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.orange.opacity(0.1), in: Capsule())
                    }

                    Spacer()

                    // Today counter
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Today")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(viewModel.todayCount)")
                                .font(.title.bold())
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text("Tracking")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(activeWords.count) words")
                                .font(.title3.bold())
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // Word list button
                    Button {
                        showWordList = true
                    } label: {
                        Label("Manage Words", systemImage: "list.bullet")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.indigo)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("MindMyWords")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showWordList) {
                WordListView()
            }
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
            .task {
                permissionGranted = await viewModel.requestPermissions()
            }
            .overlay {
                if !permissionGranted {
                    permissionDeniedOverlay
                }
            }
        }
    }

    private var permissionDeniedOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.slash.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)
            Text("Microphone & Speech Access Required")
                .font(.headline)
                .multilineTextAlignment(.center)
            Text("Please enable microphone and speech recognition in Settings to use MindMyWords.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(32)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
        .padding()
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [TriggerWord.self, DetectionLog.self], inMemory: true)
}

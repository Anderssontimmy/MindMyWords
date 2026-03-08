import SwiftUI
import SwiftData

@main
struct MindMyWordsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [TriggerWord.self, DetectionLog.self])
    }
}

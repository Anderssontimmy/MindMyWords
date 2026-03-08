import Foundation

struct DetectionResult: Identifiable {
    let id = UUID()
    let word: String
    let detectedAt: Date

    init(word: String) {
        self.word = word
        self.detectedAt = Date()
    }
}

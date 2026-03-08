import Foundation
import SwiftData

@Model
final class DetectionLog {
    var id: UUID
    var word: String
    var timestamp: Date
    var dayOfWeek: Int

    init(word: String) {
        self.id = UUID()
        self.word = word.lowercased()
        self.timestamp = Date()
        self.dayOfWeek = Calendar.current.component(.weekday, from: Date())
    }
}

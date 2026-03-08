import Foundation
import SwiftData

@Model
final class TriggerWord {
    var id: UUID
    var phrase: String
    var createdAt: Date
    var isActive: Bool

    init(phrase: String) {
        self.id = UUID()
        self.phrase = phrase.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        self.createdAt = Date()
        self.isActive = true
    }
}

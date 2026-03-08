import Foundation
import SwiftData

struct WordCount: Identifiable {
    let id = UUID()
    let word: String
    let count: Int
}

struct DayCount: Identifiable {
    let id = UUID()
    let dayOfWeek: Int
    let count: Int

    var dayName: String {
        let symbols = Calendar.current.shortWeekdaySymbols
        guard dayOfWeek >= 1, dayOfWeek <= 7 else { return "?" }
        return symbols[dayOfWeek - 1]
    }
}

@MainActor
final class StatsViewModel: ObservableObject {
    @Published var todayCount = 0
    @Published var weekCount = 0
    @Published var allTimeCount = 0
    @Published var topWords: [WordCount] = []
    @Published var dayDistribution: [DayCount] = []
    @Published var currentStreak = 0
    @Published var bestStreak = 0

    private var modelContext: ModelContext?

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        refresh()
    }

    func refresh() {
        guard let modelContext else { return }

        let settings = SettingsManager.shared
        settings.checkAndIncrementStreak()
        currentStreak = settings.streakCleanDays
        bestStreak = settings.streakBest

        // Today
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let todayDescriptor = FetchDescriptor<DetectionLog>(
            predicate: #Predicate { $0.timestamp >= startOfDay }
        )
        todayCount = (try? modelContext.fetchCount(todayDescriptor)) ?? 0

        // This week
        let startOfWeek = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        let weekDescriptor = FetchDescriptor<DetectionLog>(
            predicate: #Predicate { $0.timestamp >= startOfWeek }
        )
        weekCount = (try? modelContext.fetchCount(weekDescriptor)) ?? 0

        // All time
        let allDescriptor = FetchDescriptor<DetectionLog>()
        allTimeCount = (try? modelContext.fetchCount(allDescriptor)) ?? 0

        // Top words
        loadTopWords()

        // Day distribution
        loadDayDistribution()
    }

    private func loadTopWords() {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<DetectionLog>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        guard let logs = try? modelContext.fetch(descriptor) else { return }

        var counts: [String: Int] = [:]
        for log in logs {
            counts[log.word, default: 0] += 1
        }

        topWords = counts
            .sorted { $0.value > $1.value }
            .prefix(10)
            .map { WordCount(word: $0.key, count: $0.value) }
    }

    private func loadDayDistribution() {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<DetectionLog>()
        guard let logs = try? modelContext.fetch(descriptor) else { return }

        var counts: [Int: Int] = [:]
        for log in logs {
            counts[log.dayOfWeek, default: 0] += 1
        }

        dayDistribution = (1...7).map { day in
            DayCount(dayOfWeek: day, count: counts[day] ?? 0)
        }
    }
}

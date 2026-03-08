import SwiftUI
import SwiftData

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = StatsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Summary cards
                    HStack(spacing: 12) {
                        StatCard(title: "Today", value: "\(viewModel.todayCount)", color: .blue)
                        StatCard(title: "This Week", value: "\(viewModel.weekCount)", color: .indigo)
                        StatCard(title: "All Time", value: "\(viewModel.allTimeCount)", color: .purple)
                    }
                    .padding(.horizontal)

                    // Streak
                    HStack(spacing: 12) {
                        StreakCard(title: "Current Streak", days: viewModel.currentStreak, icon: "flame.fill", color: .orange)
                        StreakCard(title: "Best Streak", days: viewModel.bestStreak, icon: "trophy.fill", color: .yellow)
                    }
                    .padding(.horizontal)

                    // Day distribution
                    if viewModel.allTimeCount > 0 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("By Day of Week")
                                .font(.headline)

                            HStack(alignment: .bottom, spacing: 8) {
                                ForEach(viewModel.dayDistribution) { day in
                                    VStack(spacing: 4) {
                                        Text("\(day.count)")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)

                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.indigo.gradient)
                                            .frame(height: barHeight(for: day.count))

                                        Text(day.dayName)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .frame(height: 120)
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)

                        // Top words
                        if !viewModel.topWords.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Most Detected")
                                    .font(.headline)

                                ForEach(viewModel.topWords) { item in
                                    HStack {
                                        Text(item.word)
                                            .font(.body)
                                        Spacer()
                                        Text("\(item.count)")
                                            .font(.body.bold())
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                        }
                    } else {
                        ContentUnavailableView(
                            "No Data Yet",
                            systemImage: "chart.bar",
                            description: Text("Start listening to see your stats here.")
                        )
                        .padding(.top, 40)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Stats")
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
            .refreshable {
                viewModel.refresh()
            }
        }
    }

    private func barHeight(for count: Int) -> CGFloat {
        let maxCount = viewModel.dayDistribution.map(\.count).max() ?? 1
        guard maxCount > 0 else { return 4 }
        return max(4, CGFloat(count) / CGFloat(maxCount) * 80)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct StreakCard: View {
    let title: String
    let days: Int
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(days) days")
                    .font(.title3.bold())
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    StatsView()
        .modelContainer(for: [TriggerWord.self, DetectionLog.self], inMemory: true)
}

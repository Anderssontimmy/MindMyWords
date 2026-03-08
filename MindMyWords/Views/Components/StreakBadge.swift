import SwiftUI

struct StreakBadge: View {
    let days: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: days > 0 ? "flame.fill" : "flame")
                .foregroundStyle(days > 0 ? .orange : .secondary)
            Text(days > 0 ? "\(days) day streak" : "No streak")
                .font(.subheadline.bold())
                .foregroundStyle(days > 0 ? .primary : .secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

#Preview {
    VStack {
        StreakBadge(days: 0)
        StreakBadge(days: 5)
        StreakBadge(days: 30)
    }
}

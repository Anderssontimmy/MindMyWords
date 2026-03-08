import SwiftUI

struct ListenButton: View {
    let isListening: Bool
    let flashDetection: Bool
    let action: () -> Void

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        Button(action: action) {
            ZStack {
                // Pulse rings when listening
                if isListening {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(Color.indigo.opacity(0.3 - Double(i) * 0.1), lineWidth: 2)
                            .frame(width: 160 + CGFloat(i) * 30, height: 160 + CGFloat(i) * 30)
                            .scaleEffect(pulseScale)
                            .animation(
                                .easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.3),
                                value: pulseScale
                            )
                    }
                }

                // Main button circle
                Circle()
                    .fill(
                        isListening
                            ? (flashDetection ? Color.red : Color.indigo)
                            : Color.indigo.opacity(0.8)
                    )
                    .frame(width: 140, height: 140)
                    .shadow(color: .indigo.opacity(0.4), radius: isListening ? 20 : 10)
                    .animation(.easeInOut(duration: 0.2), value: flashDetection)

                // Icon
                Image(systemName: isListening ? "ear.fill" : "mic.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(.white)
                    .scaleEffect(flashDetection ? 1.3 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: flashDetection)
            }
        }
        .onAppear {
            pulseScale = 1.1
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        ListenButton(isListening: false, flashDetection: false) {}
        ListenButton(isListening: true, flashDetection: false) {}
    }
}

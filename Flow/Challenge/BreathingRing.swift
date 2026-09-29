import SwiftUI

/// Calm progress ring around a slowly "breathing" circle.
/// With Reduce Motion enabled the circle stays still.
struct BreathingRing<Content: View>: View {
    /// 0...1, drawn as the ring.
    var progress: Double
    @ViewBuilder var content: Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var inhale = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.12))
                .scaleEffect(reduceMotion ? 0.9 : (inhale ? 0.96 : 0.80))
                .animation(reduceMotion ? nil : .easeInOut(duration: 4).repeatForever(autoreverses: true), value: inhale)

            Circle()
                .stroke(Color.secondary.opacity(0.15), lineWidth: 6)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .linear(duration: 0.25), value: progress)

            content
        }
        .onAppear { inhale = true }
    }
}

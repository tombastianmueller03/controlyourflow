import SwiftUI

/// The math pause screen.
struct ChallengeView: View {
    let session: ChallengeSession
    var onPassed: () -> Void
    var onCancel: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var reportedCompletion = false

    private static let letters = ["A", "B", "C", "D"]

    var body: some View {
        VStack(spacing: 24) {
            header
            if verticalSizeClass == .compact {
                // Landscape on iPhone: ring and task side by side.
                HStack(spacing: 32) {
                    progressRing
                    mainContent
                }
                .frame(maxHeight: .infinity)
            } else {
                progressRing
                Spacer(minLength: 0)
                mainContent
                Spacer(minLength: 0)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .sensoryFeedback(.success, trigger: session.correctCount)
        .sensoryFeedback(.error, trigger: session.wrongCount)
        .task(id: session.id) {
            while !Task.isCancelled {
                session.tick()
                try? await Task.sleep(for: .milliseconds(200))
            }
        }
        .onChange(of: session.phase) { _, phase in
            announce(phase)
            if phase == .completed && !reportedCompletion {
                reportedCompletion = true
                onPassed()
            }
        }
    }

    // MARK: - Parts

    private var progressRing: some View {
        BreathingRing(progress: session.timeProgress) {
            VStack(spacing: 4) {
                Text("\(min(session.correctCount, session.settings.taskCount))/\(session.settings.taskCount)")
                    .font(.title2.weight(.semibold))
                    .monospacedDigit()
                Text(Self.format(session.remainingTime))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(progressLabel)
        }
        .frame(maxWidth: 170, maxHeight: 170)
    }

    private var header: some View {
        HStack {
            Text("Pause vor \(session.ruleName)")
                .font(.headline)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Nicht jetzt", action: onCancel)
                .buttonStyle(.bordered)
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        switch session.phase {
        case .waitingForTime:
            statusMessage(
                title: "Alle Aufgaben gelöst",
                detail: "Noch kurz durchatmen …"
            )
        case .completed:
            statusMessage(
                title: "Geschafft",
                detail: "\(session.ruleName) wird geöffnet."
            )
        case .solving, .correctFeedback, .penalty:
            VStack(spacing: 20) {
                Text(session.problem.question)
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .accessibilityLabel(session.problem.spokenQuestion)
                    .accessibilityAddTraits(.isHeader)

                answerGrid

                Text(penaltyText)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .opacity(session.phase == .penalty ? 1 : 0)
                    .accessibilityHidden(session.phase != .penalty)
            }
        }
    }

    private var answerGrid: some View {
        let columns = dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Array(session.problem.options.enumerated()), id: \.offset) { index, value in
                Button {
                    session.answer(index)
                } label: {
                    HStack(spacing: 12) {
                        Text(Self.letters[index])
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("\(value)")
                            .font(.title2.weight(.semibold))
                            .monospacedDigit()
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        if let symbol = feedbackSymbol(for: index) {
                            Image(systemName: symbol)
                                .font(.title3.weight(.semibold))
                                .accessibilityHidden(true)
                        }
                    }
                    .padding(.horizontal, 18)
                    .frame(maxWidth: .infinity, minHeight: 64)
                    .background(background(for: index), in: .rect(cornerRadius: 16))
                    .contentShape(.rect(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .disabled(!session.canAnswer)
                .accessibilityLabel("Antwort \(Self.letters[index]): \(value)")
            }
        }
    }

    private func statusMessage(title: LocalizedStringKey, detail: LocalizedStringKey) -> some View {
        VStack(spacing: 8) {
            Text(title).font(.title.weight(.semibold))
            Text(detail).font(.body).foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .combine)
    }

    private func background(for index: Int) -> Color {
        switch session.feedback {
        case .correct(let correct) where correct == index:
            .green.opacity(0.35)
        case .wrong(let chosen, _) where chosen == index:
            .red.opacity(0.35)
        case .wrong(_, let correct) where correct == index:
            .green.opacity(0.25)
        default:
            Color(.secondarySystemBackground)
        }
    }

    /// Shape cue in addition to color (Differentiate Without Color).
    private func feedbackSymbol(for index: Int) -> String? {
        switch session.feedback {
        case .correct(let correct) where correct == index: "checkmark"
        case .wrong(let chosen, _) where chosen == index: "xmark"
        case .wrong(_, let correct) where correct == index: "checkmark"
        default: nil
        }
    }

    // MARK: - Text helpers

    private var penaltyText: String {
        let seconds = Int(session.penaltyRemaining.rounded(.up))
        return String(localized: "Falsch – neue Aufgabe in \(seconds) s")
    }

    private var progressLabel: String {
        let done = min(session.correctCount, session.settings.taskCount)
        let remaining = Int(session.remainingTime.rounded(.up))
        return String(localized: "\(done) von \(session.settings.taskCount) Aufgaben gelöst, noch \(remaining) Sekunden")
    }

    private func announce(_ phase: ChallengeSession.Phase) {
        let message: String? = switch phase {
        case .correctFeedback: String(localized: "Richtig")
        case .penalty: String(localized: "Falsch")
        case .waitingForTime: String(localized: "Alle Aufgaben gelöst. Noch kurz durchatmen.")
        case .completed, .solving: nil
        }
        if let message {
            AccessibilityNotification.Announcement(message).post()
        }
    }

    static func format(_ interval: TimeInterval) -> String {
        let total = Int(interval.rounded(.up))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

import Foundation
import Observation

/// State of one math pause, independent of the UI.
///
/// The pause is passed only when both conditions hold:
/// all tasks answered correctly AND the minimum duration has elapsed.
/// Time is measured from dates (not timer ticks), so it stays correct
/// if the app is briefly in the background.
@MainActor
@Observable
final class ChallengeSession: Identifiable {
    enum Phase: Equatable {
        case solving
        /// Short confirmation after a correct answer.
        case correctFeedback
        /// Locked after a wrong answer; a new task follows.
        case penalty
        /// All tasks done, minimum duration not reached yet.
        case waitingForTime
        case completed
    }

    enum Feedback: Equatable {
        case correct(index: Int)
        case wrong(chosen: Int, correct: Int)
    }

    /// How long the green confirmation stays before the next task.
    static let correctFeedbackDuration: TimeInterval = 0.6
    /// Shortest time a wrong answer stays visible, even with a penalty of 0 s.
    static let minimumWrongFeedbackDuration: TimeInterval = 1.0

    let id = UUID()
    let ruleID: UUID
    let ruleName: String
    let settings: ChallengeSettings
    let startedAt: Date

    private(set) var problem: MathProblem
    private(set) var correctCount = 0
    private(set) var wrongCount = 0
    private(set) var feedback: Feedback?
    /// Current time as of the last `tick()` / answer; drives the UI.
    private(set) var now: Date

    @ObservationIgnored private var lockedUntil: Date?
    @ObservationIgnored private var usedKeys: Set<String> = []
    @ObservationIgnored private let generator: MathProblemGenerator
    @ObservationIgnored private var rng: SplitMix64
    @ObservationIgnored private let clock: () -> Date

    init(
        ruleID: UUID,
        ruleName: String,
        settings: ChallengeSettings,
        seed: UInt64 = UInt64.random(in: .min ... .max),
        clock: @escaping () -> Date = Date.init
    ) {
        self.ruleID = ruleID
        self.ruleName = ruleName
        self.settings = settings
        self.clock = clock
        let generator = MathProblemGenerator(difficulty: settings.difficulty)
        var rng = SplitMix64(seed: seed)
        let first = generator.makeProblem(using: &rng)
        self.generator = generator
        self.rng = rng
        problem = first
        usedKeys = [first.key]
        startedAt = clock()
        now = startedAt
    }

    // MARK: - Derived state

    var phase: Phase {
        if correctCount >= settings.taskCount {
            return elapsed >= Double(settings.minimumDuration) ? .completed : .waitingForTime
        }
        if let lockedUntil, now < lockedUntil {
            if case .wrong = feedback { return .penalty }
            return .correctFeedback
        }
        return .solving
    }

    var elapsed: TimeInterval { now.timeIntervalSince(startedAt) }

    var remainingTime: TimeInterval { max(0, Double(settings.minimumDuration) - elapsed) }

    var timeProgress: Double {
        settings.minimumDuration == 0 ? 1 : min(1, elapsed / Double(settings.minimumDuration))
    }

    /// Seconds until a new task appears after a wrong answer.
    var penaltyRemaining: TimeInterval {
        guard phase == .penalty, let lockedUntil else { return 0 }
        return max(0, lockedUntil.timeIntervalSince(now))
    }

    var canAnswer: Bool { phase == .solving }

    // MARK: - Actions

    func answer(_ index: Int) {
        tick()
        guard canAnswer, problem.options.indices.contains(index) else { return }

        if index == problem.correctIndex {
            correctCount += 1
            feedback = .correct(index: index)
            lockedUntil = now.addingTimeInterval(Self.correctFeedbackDuration)
        } else {
            wrongCount += 1
            feedback = .wrong(chosen: index, correct: problem.correctIndex)
            let lock = max(Double(settings.penaltySeconds), Self.minimumWrongFeedbackDuration)
            lockedUntil = now.addingTimeInterval(lock)
        }
    }

    /// Advances time; moves on to the next task once feedback/penalty is over.
    func tick() {
        now = clock()
        guard let lockedUntil, now >= lockedUntil else { return }
        self.lockedUntil = nil
        feedback = nil
        if correctCount < settings.taskCount {
            problem = generator.makeProblem(avoiding: usedKeys, using: &rng)
            usedKeys.insert(problem.key)
        }
    }
}

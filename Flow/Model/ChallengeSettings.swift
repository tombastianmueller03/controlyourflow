import Foundation

/// How hard the math pause is.
enum Difficulty: Int, Codable, CaseIterable, Identifiable, Sendable {
    case level1 = 1
    case level2 = 2
    case level3 = 3
    case level4 = 4

    var id: Int { rawValue }
}

/// Per-app configuration of the math pause.
///
/// Decoding tolerates missing keys so that fields added later
/// (e.g. in phase 2) do not break data saved by older versions.
struct ChallengeSettings: Codable, Hashable, Sendable {
    var taskCount: Int = 10
    /// Minimum time the pause lasts, in seconds.
    var minimumDuration: Int = 60
    var difficulty: Difficulty = .level1
    /// Lock time after a wrong answer, in seconds.
    var penaltySeconds: Int = 5
    /// How long a passed pause lets the target app open without a new pause.
    var graceMinutes: Int = 5

    static let taskCountRange = 1...50
    static let minimumDurationRange = 0...600
    static let penaltyRange = 0...60
    /// Must be at least 1 minute: right after a passed pause, opening the target
    /// app re-triggers the automation, and only a valid pass lets it through.
    static let graceRange = 1...240

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fallback = ChallengeSettings()
        taskCount = try container.decodeIfPresent(Int.self, forKey: .taskCount) ?? fallback.taskCount
        minimumDuration = try container.decodeIfPresent(Int.self, forKey: .minimumDuration) ?? fallback.minimumDuration
        difficulty = try container.decodeIfPresent(Difficulty.self, forKey: .difficulty) ?? fallback.difficulty
        penaltySeconds = try container.decodeIfPresent(Int.self, forKey: .penaltySeconds) ?? fallback.penaltySeconds
        graceMinutes = try container.decodeIfPresent(Int.self, forKey: .graceMinutes) ?? fallback.graceMinutes
        self = clamped()
    }

    /// Returns a copy with every value inside its allowed range.
    func clamped() -> ChallengeSettings {
        var copy = self
        copy.taskCount = taskCount.clamped(to: Self.taskCountRange)
        copy.minimumDuration = minimumDuration.clamped(to: Self.minimumDurationRange)
        copy.penaltySeconds = penaltySeconds.clamped(to: Self.penaltyRange)
        copy.graceMinutes = graceMinutes.clamped(to: Self.graceRange)
        return copy
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

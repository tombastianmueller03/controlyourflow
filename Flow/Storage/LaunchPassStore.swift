import Foundation
import Observation

/// Time-limited permission to open a target app without a new pause.
///
/// A pass is granted after a passed pause and is NOT used up when checked:
/// it simply expires. This matters because opening the target app from Flow
/// re-triggers the "App is opened" automation, and every app switch within
/// the grace period triggers it again. Each of those runs must see the pass.
@MainActor
@Observable
final class LaunchPassStore {
    static let shared = LaunchPassStore()

    /// Expiry date per rule ID.
    private(set) var expiries: [UUID: Date] = [:]

    @ObservationIgnored private let defaults: UserDefaults
    private static let key = "launchPasses.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.key),
           let stored = try? JSONDecoder().decode([String: Date].self, from: data) {
            expiries = Dictionary(uniqueKeysWithValues: stored.compactMap { key, date in
                UUID(uuidString: key).map { ($0, date) }
            })
        }
    }

    func isValid(for ruleID: UUID, at now: Date = .now) -> Bool {
        guard let expiry = expiries[ruleID] else { return false }
        return now < expiry
    }

    /// Expiry of a still valid pass, otherwise nil.
    func validUntil(for ruleID: UUID, at now: Date = .now) -> Date? {
        isValid(for: ruleID, at: now) ? expiries[ruleID] : nil
    }

    func grant(for ruleID: UUID, minutes: Int, at now: Date = .now) {
        let minutes = minutes.clamped(to: ChallengeSettings.graceRange)
        expiries = expiries.filter { $0.value > now }
        expiries[ruleID] = now.addingTimeInterval(TimeInterval(minutes * 60))
        persist()
    }

    func revoke(for ruleID: UUID) {
        expiries[ruleID] = nil
        persist()
    }

    private func persist() {
        let stored = Dictionary(uniqueKeysWithValues: expiries.map { ($0.key.uuidString, $0.value) })
        if let data = try? JSONEncoder().encode(stored) {
            defaults.set(data, forKey: Self.key)
        }
    }
}

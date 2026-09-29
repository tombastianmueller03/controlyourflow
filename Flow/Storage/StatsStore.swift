import Foundation
import Observation

/// Local statistics: pauses started / passed / cancelled per rule and day,
/// plus when the automation last ran for each rule. Never leaves the device.
@MainActor
@Observable
final class StatsStore {
    static let shared = StatsStore()

    struct Counts: Codable, Hashable, Sendable {
        var started = 0
        var passed = 0
        var cancelled = 0

        static func + (lhs: Counts, rhs: Counts) -> Counts {
            Counts(started: lhs.started + rhs.started, passed: lhs.passed + rhs.passed, cancelled: lhs.cancelled + rhs.cancelled)
        }
    }

    enum Event {
        case started, passed, cancelled
    }

    private struct Snapshot: Codable {
        /// "yyyy-MM-dd" → rule ID string → counts
        var days: [String: [String: Counts]] = [:]
        var lastTriggered: [String: Date] = [:]
    }

    private var snapshot = Snapshot()

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let calendar: Calendar
    private static let key = "stats.v1"

    init(defaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.defaults = defaults
        self.calendar = calendar
        if let data = defaults.data(forKey: Self.key),
           let stored = try? JSONDecoder().decode(Snapshot.self, from: data) {
            snapshot = stored
        }
    }

    // MARK: - Recording

    func record(_ event: Event, ruleID: UUID, at date: Date = .now) {
        let day = dayKey(for: date)
        var counts = snapshot.days[day]?[ruleID.uuidString] ?? Counts()
        switch event {
        case .started: counts.started += 1
        case .passed: counts.passed += 1
        case .cancelled: counts.cancelled += 1
        }
        snapshot.days[day, default: [:]][ruleID.uuidString] = counts
        persist()
    }

    /// Every run of the intent, including ones that let the app through.
    func recordTrigger(ruleID: UUID, at date: Date = .now) {
        snapshot.lastTriggered[ruleID.uuidString] = date
        persist()
    }

    // MARK: - Queries

    func lastTriggered(ruleID: UUID) -> Date? {
        snapshot.lastTriggered[ruleID.uuidString]
    }

    /// Counts for one day, optionally limited to one rule.
    func counts(on date: Date, ruleID: UUID? = nil) -> Counts {
        let perRule = snapshot.days[dayKey(for: date)] ?? [:]
        if let ruleID { return perRule[ruleID.uuidString] ?? Counts() }
        return perRule.values.reduce(Counts(), +)
    }

    /// All-time counts, optionally limited to one rule.
    func totals(ruleID: UUID? = nil) -> Counts {
        snapshot.days.values.reduce(Counts()) { sum, perRule in
            if let ruleID { return sum + (perRule[ruleID.uuidString] ?? Counts()) }
            return perRule.values.reduce(sum, +)
        }
    }

    /// Days with any activity, newest first, as (date key, counts per rule ID).
    func recentDays(limit: Int = 14) -> [(day: String, perRule: [UUID: Counts])] {
        snapshot.days.keys.sorted(by: >).prefix(limit).map { day in
            let perRule = (snapshot.days[day] ?? [:]).reduce(into: [UUID: Counts]()) { result, entry in
                if let id = UUID(uuidString: entry.key) { result[id] = entry.value }
            }
            return (day, perRule)
        }
    }

    func reset() {
        snapshot = Snapshot()
        persist()
    }

    // MARK: - Helpers

    func dayKey(for date: Date) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: Self.key)
        }
    }
}

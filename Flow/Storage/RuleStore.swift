import Foundation
import Observation
import SwiftUI

/// Persists the app rules and the global defaults as JSON in UserDefaults.
///
/// UserDefaults.standard is enough (no App Group): the App Intent lives in the
/// app target and runs in the app's own process.
/// UNVERIFIED on device: that background intent runs share this process.
@MainActor
@Observable
final class RuleStore {
    static let shared = RuleStore()

    private(set) var rules: [AppRule] = []

    /// Starting values for newly added rules.
    var defaultSettings = ChallengeSettings() {
        didSet { save(defaultSettings.clamped(), forKey: Keys.defaultSettings) }
    }

    @ObservationIgnored private let defaults: UserDefaults

    private enum Keys {
        static let rules = "rules.v1"
        static let defaultSettings = "defaultSettings.v1"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        rules = load([AppRule].self, forKey: Keys.rules) ?? []
        defaultSettings = load(ChallengeSettings.self, forKey: Keys.defaultSettings) ?? ChallengeSettings()
    }

    func rule(id: UUID) -> AppRule? {
        rules.first { $0.id == id }
    }

    /// Creates a new rule with the global defaults.
    @discardableResult
    func addRule(name: String, urlScheme: String) -> AppRule {
        let rule = AppRule(name: name, urlScheme: urlScheme, settings: defaultSettings)
        rules.append(rule)
        persistRules()
        return rule
    }

    func update(_ rule: AppRule) {
        guard let index = rules.firstIndex(where: { $0.id == rule.id }) else { return }
        var copy = rule
        copy.settings = rule.settings.clamped()
        rules[index] = copy
        persistRules()
    }

    func delete(id: UUID) {
        rules.removeAll { $0.id == id }
        persistRules()
    }

    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        rules.move(fromOffsets: source, toOffset: destination)
        persistRules()
    }

    private func persistRules() {
        save(rules, forKey: Keys.rules)
    }

    private func save<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private func load<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}

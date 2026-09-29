import Foundation
import Testing
@testable import Flow

@MainActor
struct RuleStoreTests {
    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "RuleStoreTests.\(UUID().uuidString)")!
    }

    @Test func addedRulesPersistAcrossInstances() {
        let defaults = makeDefaults()
        let store = RuleStore(defaults: defaults)
        store.addRule(name: "Instagram", urlScheme: "instagram://")
        store.addRule(name: "YouTube", urlScheme: "youtube://")

        let reloaded = RuleStore(defaults: defaults)
        #expect(reloaded.rules.map(\.name) == ["Instagram", "YouTube"])
    }

    @Test func newRulesUseGlobalDefaults() {
        let store = RuleStore(defaults: makeDefaults())
        var defaults = ChallengeSettings()
        defaults.taskCount = 20
        defaults.difficulty = .level3
        store.defaultSettings = defaults

        let rule = store.addRule(name: "TikTok", urlScheme: "snssdk1233://")
        #expect(rule.settings.taskCount == 20)
        #expect(rule.settings.difficulty == .level3)
    }

    @Test func updateClampsAndDeleteRemoves() throws {
        let defaults = makeDefaults()
        let store = RuleStore(defaults: defaults)
        var rule = store.addRule(name: "Reddit", urlScheme: "reddit://")
        rule.settings.graceMinutes = 0
        rule.settings.taskCount = 500
        store.update(rule)

        let stored = try #require(store.rule(id: rule.id))
        #expect(stored.settings.graceMinutes == 1)
        #expect(stored.settings.taskCount == 50)

        store.delete(id: rule.id)
        #expect(RuleStore(defaults: defaults).rules.isEmpty)
    }

    @Test func decodingToleratesMissingFields() throws {
        let json = #"[{"id":"7C9B2D7E-2F40-4C1B-9F6A-0A8C3E1B5D11","name":"Instagram","settings":{"taskCount":3}}]"#
        let rules = try JSONDecoder().decode([AppRule].self, from: Data(json.utf8))
        #expect(rules.count == 1)
        #expect(rules[0].urlScheme == "")
        #expect(rules[0].settings.taskCount == 3)
        #expect(rules[0].settings.minimumDuration == 60)
        #expect(rules[0].settings.graceMinutes == 5)
    }

    @Test(arguments: [
        ("instagram://", "instagram://"),
        ("instagram", "instagram://"),
        ("  fb://  ", "fb://"),
        ("youtube://watch", "youtube://watch"),
    ])
    func launchURLNormalizesScheme(input: String, expected: String) {
        #expect(AppRule.launchURL(for: input)?.absoluteString == expected)
    }

    @Test func launchURLRejectsEmptyInput() {
        #expect(AppRule.launchURL(for: "   ") == nil)
    }

    @Test func effectiveSettingsDefaultToBaseSettings() {
        var settings = ChallengeSettings()
        settings.taskCount = 7
        let rule = AppRule(name: "X", urlScheme: "twitter://", settings: settings)
        #expect(rule.effectiveSettings(at: .now) == settings)
    }
}

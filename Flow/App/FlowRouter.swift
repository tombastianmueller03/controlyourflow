import Foundation
import Observation
import UIKit

/// Decides what happens when the automation runs and what Flow shows.
///
/// Shared between the App Intent (via AppDependencyManager) and the UI;
/// both run in the app process on the main actor.
@MainActor
@Observable
final class FlowRouter {
    enum TriggerDecision: Equatable {
        /// Valid pass: the intent ends silently and the target app stays open.
        case letThrough
        case startChallenge
        /// Double trigger while a pause for the same app is running.
        case resumeChallenge
        case unknownRule
        /// The automation has no "Ziel-App" set: show a hint instead of letting the app through.
        case showSetupHint
    }

    enum Notice: Equatable {
        /// Calm screen after "Nicht jetzt".
        case notNow(ruleName: String)
        /// The target app could not be opened after a passed pause.
        case openFailed(ruleName: String, urlScheme: String)
        /// The automation ran without a "Ziel-App".
        case automationIncomplete
    }

    private(set) var activeSession: ChallengeSession?
    var notice: Notice?

    @ObservationIgnored let rules: RuleStore
    @ObservationIgnored let passes: LaunchPassStore
    @ObservationIgnored let stats: StatsStore
    @ObservationIgnored private let openURL: @MainActor (URL) async -> Bool
    @ObservationIgnored private let clock: () -> Date

    init(
        rules: RuleStore = .shared,
        passes: LaunchPassStore = .shared,
        stats: StatsStore = .shared,
        openURL: @escaping @MainActor (URL) async -> Bool = { await UIApplication.shared.open($0) },
        clock: @escaping () -> Date = Date.init
    ) {
        self.rules = rules
        self.passes = passes
        self.stats = stats
        self.openURL = openURL
        self.clock = clock
    }

    /// Called by the App Intent each time the automation fires. Must return quickly.
    func handleTrigger(ruleID: UUID) -> TriggerDecision {
        let now = clock()
        stats.recordTrigger(ruleID: ruleID, at: now)

        guard let rule = rules.rule(id: ruleID) else { return .unknownRule }

        // Checked first and never consumed: this is what prevents a loop when
        // Flow itself opens the target app and the automation fires again.
        if passes.isValid(for: ruleID, at: now) { return .letThrough }

        if let activeSession, activeSession.ruleID == ruleID, activeSession.phase != .completed {
            return .resumeChallenge
        }

        startChallenge(for: rule, at: now)
        return .startChallenge
    }

    /// Called when the automation runs without a "Ziel-App". Flow cannot know
    /// which app was opened, so it asks the user to finish the setup.
    func handleUnconfiguredTrigger() -> TriggerDecision {
        if activeSession != nil { return .resumeChallenge }
        notice = .automationIncomplete
        return .showSetupHint
    }

    func startChallenge(for rule: AppRule, at now: Date? = nil) {
        let now = now ?? clock()
        stats.record(.started, ruleID: rule.id, at: now)
        notice = nil
        activeSession = ChallengeSession(
            ruleID: rule.id,
            ruleName: rule.name,
            settings: rule.effectiveSettings(at: now),
            clock: clock
        )
    }

    /// Stores the pass, then opens the target app.
    func challengePassed() async {
        guard let session = activeSession, session.phase == .completed else { return }
        let now = clock()
        passes.grant(for: session.ruleID, minutes: session.settings.graceMinutes, at: now)
        stats.record(.passed, ruleID: session.ruleID, at: now)
        activeSession = nil

        let rule = rules.rule(id: session.ruleID)
        let scheme = rule?.urlScheme ?? ""
        guard let url = rule?.launchURL, await openURL(url) else {
            notice = .openFailed(ruleName: session.ruleName, urlScheme: scheme)
            return
        }
    }

    func cancelChallenge() {
        guard let session = activeSession else { return }
        stats.record(.cancelled, ruleID: session.ruleID, at: clock())
        activeSession = nil
        notice = .notNow(ruleName: session.ruleName)
    }

    /// Setup test: removes the pass and opens the target app, so the
    /// automation should bring Flow back with a pause.
    func testAutomation(for rule: AppRule) async -> Bool {
        passes.revoke(for: rule.id)
        guard let url = rule.launchURL else { return false }
        return await openURL(url)
    }
}

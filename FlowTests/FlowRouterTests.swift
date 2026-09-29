import Foundation
import Testing
@testable import Flow

@MainActor
struct FlowRouterTests {
    private let clock = TestClock()
    private let defaults = UserDefaults(suiteName: "FlowRouterTests.\(UUID().uuidString)")!
    private let opened = OpenedURLs()

    @MainActor
    final class OpenedURLs {
        var urls: [URL] = []
        var succeeds = true
    }

    private func makeRouter() -> (FlowRouter, AppRule) {
        let rules = RuleStore(defaults: defaults)
        var settings = ChallengeSettings()
        settings.taskCount = 2
        settings.minimumDuration = 10
        settings.graceMinutes = 5
        rules.defaultSettings = settings
        let rule = rules.addRule(name: "Instagram", urlScheme: "instagram://")
        let router = FlowRouter(
            rules: rules,
            passes: LaunchPassStore(defaults: defaults),
            stats: StatsStore(defaults: defaults),
            openURL: { [opened] url in
                opened.urls.append(url)
                return opened.succeeds
            },
            clock: { [clock] in clock.now }
        )
        return (router, rule)
    }

    /// Answers every task correctly and waits out the minimum duration.
    private func pass(_ session: ChallengeSession) {
        while session.correctCount < session.settings.taskCount {
            session.answer(session.problem.correctIndex)
            clock.advance(ChallengeSession.correctFeedbackDuration)
            session.tick()
        }
        clock.advance(TimeInterval(session.settings.minimumDuration))
        session.tick()
    }

    @Test func fullFlowWithoutLoop() async throws {
        let (router, rule) = makeRouter()

        // 1. User opens Instagram → automation → no pass → pause.
        #expect(router.handleTrigger(ruleID: rule.id) == .startChallenge)
        let session = try #require(router.activeSession)

        // 2. Pause passed → pass stored → Instagram opened by Flow.
        pass(session)
        #expect(session.phase == .completed)
        await router.challengePassed()
        #expect(opened.urls == [URL(string: "instagram://")!])
        #expect(router.activeSession == nil)
        #expect(router.notice == nil)

        // 3. Opening Instagram re-triggers the automation → let through, no loop.
        clock.advance(1)
        #expect(router.handleTrigger(ruleID: rule.id) == .letThrough)
        #expect(router.activeSession == nil)

        // 4. App switches within the grace period → still let through.
        clock.advance(4 * 60)
        #expect(router.handleTrigger(ruleID: rule.id) == .letThrough)

        // 5. After the grace period → new pause.
        clock.advance(60)
        #expect(router.handleTrigger(ruleID: rule.id) == .startChallenge)
        #expect(opened.urls.count == 1)
    }

    @Test func doubleTriggerKeepsRunningSession() throws {
        let (router, rule) = makeRouter()
        #expect(router.handleTrigger(ruleID: rule.id) == .startChallenge)
        let session = try #require(router.activeSession)
        session.answer(session.problem.correctIndex)

        #expect(router.handleTrigger(ruleID: rule.id) == .resumeChallenge)
        #expect(router.activeSession?.id == session.id)
        #expect(router.activeSession?.correctCount == 1)
    }

    @Test func cancelShowsNotNowAndGrantsNoPass() {
        let (router, rule) = makeRouter()
        _ = router.handleTrigger(ruleID: rule.id)
        router.cancelChallenge()

        #expect(router.activeSession == nil)
        #expect(router.notice == .notNow(ruleName: "Instagram"))
        #expect(!router.passes.isValid(for: rule.id, at: clock.now))
        #expect(router.handleTrigger(ruleID: rule.id) == .startChallenge)
        #expect(opened.urls.isEmpty)
    }

    @Test func passedPauseCannotBeReportedEarly() async {
        let (router, rule) = makeRouter()
        _ = router.handleTrigger(ruleID: rule.id)
        await router.challengePassed()
        #expect(router.activeSession != nil)
        #expect(!router.passes.isValid(for: rule.id, at: clock.now))
        #expect(opened.urls.isEmpty)
    }

    @Test func failedOpenShowsFallbackButKeepsPass() async throws {
        let (router, rule) = makeRouter()
        opened.succeeds = false
        _ = router.handleTrigger(ruleID: rule.id)
        pass(try #require(router.activeSession))
        await router.challengePassed()

        #expect(router.notice == .openFailed(ruleName: "Instagram", urlScheme: "instagram://"))
        #expect(router.passes.isValid(for: rule.id, at: clock.now))
    }

    @Test func missingTargetShowsSetupHintInsteadOfLettingThrough() throws {
        let (router, rule) = makeRouter()
        #expect(router.handleUnconfiguredTrigger() == .showSetupHint)
        #expect(router.notice == .automationIncomplete)
        #expect(router.activeSession == nil)

        // A running pause is not replaced by the hint.
        router.notice = nil
        _ = router.handleTrigger(ruleID: rule.id)
        let session = try #require(router.activeSession)
        #expect(router.handleUnconfiguredTrigger() == .resumeChallenge)
        #expect(router.activeSession?.id == session.id)
        #expect(router.notice == nil)
    }

    @Test func unknownRule() {
        let (router, _) = makeRouter()
        #expect(router.handleTrigger(ruleID: UUID()) == .unknownRule)
        #expect(router.activeSession == nil)
    }

    @Test func statsCountStartedPassedCancelled() async throws {
        let (router, rule) = makeRouter()
        _ = router.handleTrigger(ruleID: rule.id)
        router.cancelChallenge()
        _ = router.handleTrigger(ruleID: rule.id)
        pass(try #require(router.activeSession))
        await router.challengePassed()
        clock.advance(1)
        _ = router.handleTrigger(ruleID: rule.id) // let through, not counted as a pause

        let counts = router.stats.counts(on: clock.now, ruleID: rule.id)
        #expect(counts == StatsStore.Counts(started: 2, passed: 1, cancelled: 1))
        #expect(router.stats.lastTriggered(ruleID: rule.id) == clock.now)
    }

    @Test func automationTestRevokesPassAndOpensApp() async throws {
        let (router, rule) = makeRouter()
        router.passes.grant(for: rule.id, minutes: 5, at: clock.now)
        #expect(await router.testAutomation(for: rule))
        #expect(!router.passes.isValid(for: rule.id, at: clock.now))
        #expect(opened.urls == [URL(string: "instagram://")!])
    }
}

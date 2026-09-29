import Foundation
import Testing
@testable import Flow

/// Manually advanced clock for time-dependent tests.
@MainActor
final class TestClock {
    var now = Date(timeIntervalSince1970: 1_000_000)
    func advance(_ seconds: TimeInterval) { now = now.addingTimeInterval(seconds) }
}

@MainActor
struct ChallengeSessionTests {
    private func makeSession(taskCount: Int = 3, minimumDuration: Int = 60, penalty: Int = 5, clock: TestClock) -> ChallengeSession {
        var settings = ChallengeSettings()
        settings.taskCount = taskCount
        settings.minimumDuration = minimumDuration
        settings.penaltySeconds = penalty
        return ChallengeSession(
            ruleID: UUID(), ruleName: "Test", settings: settings,
            seed: 3, clock: { clock.now }
        )
    }

    private func answerCorrectly(_ session: ChallengeSession, clock: TestClock) {
        session.answer(session.problem.correctIndex)
        clock.advance(ChallengeSession.correctFeedbackDuration)
        session.tick()
    }

    private func wrongIndex(_ session: ChallengeSession) -> Int {
        (session.problem.correctIndex + 1) % 4
    }

    @Test func tasksDoneEarlyStillWaitsForMinimumDuration() {
        let clock = TestClock()
        let session = makeSession(clock: clock)
        for _ in 0..<3 { answerCorrectly(session, clock: clock) }

        #expect(session.correctCount == 3)
        #expect(session.phase == .waitingForTime)

        clock.advance(58)
        session.tick()
        #expect(session.phase == .waitingForTime)

        clock.advance(1)
        session.tick()
        #expect(session.phase == .completed)
    }

    @Test func timeOverButTasksMissingIsNotCompleted() {
        let clock = TestClock()
        let session = makeSession(clock: clock)
        answerCorrectly(session, clock: clock)
        clock.advance(300)
        session.tick()
        #expect(session.phase == .solving)
        #expect(session.correctCount == 1)
    }

    @Test func wrongAnswerLocksForPenaltyThenShowsNewTask() {
        let clock = TestClock()
        let session = makeSession(penalty: 5, clock: clock)
        let firstProblem = session.problem

        session.answer(wrongIndex(session))
        #expect(session.phase == .penalty)
        #expect(session.wrongCount == 1)
        #expect(session.correctCount == 0)

        // Answers during the penalty are ignored.
        clock.advance(4)
        session.answer(session.problem.correctIndex)
        #expect(session.correctCount == 0)
        #expect(session.phase == .penalty)
        #expect(session.penaltyRemaining == 1)

        clock.advance(1)
        session.tick()
        #expect(session.phase == .solving)
        #expect(session.problem != firstProblem)
    }

    @Test func zeroPenaltyStillShowsFeedbackBriefly() {
        let clock = TestClock()
        let session = makeSession(penalty: 0, clock: clock)
        session.answer(wrongIndex(session))
        #expect(session.phase == .penalty)
        clock.advance(ChallengeSession.minimumWrongFeedbackDuration)
        session.tick()
        #expect(session.phase == .solving)
    }

    @Test func zeroMinimumDurationCompletesRightAfterLastTask() {
        let clock = TestClock()
        let session = makeSession(taskCount: 1, minimumDuration: 0, clock: clock)
        session.answer(session.problem.correctIndex)
        #expect(session.phase == .completed)
    }

    @Test func noTaskRepeatsWithinASession() {
        let clock = TestClock()
        let session = makeSession(taskCount: 30, minimumDuration: 0, penalty: 0, clock: clock)
        var seen: Set<String> = [session.problem.key]
        for step in 0..<29 {
            if step.isMultiple(of: 3) {
                session.answer(wrongIndex(session))
                clock.advance(ChallengeSession.minimumWrongFeedbackDuration)
                session.tick()
                #expect(seen.insert(session.problem.key).inserted)
            }
            answerCorrectly(session, clock: clock)
            #expect(seen.insert(session.problem.key).inserted)
        }
    }
}

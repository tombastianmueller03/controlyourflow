import Foundation
import Testing
@testable import Flow

@MainActor
struct LaunchPassStoreTests {
    private let start = Date(timeIntervalSince1970: 2_000_000)

    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "LaunchPassStoreTests.\(UUID().uuidString)")!
    }

    @Test func noPassByDefault() {
        let store = LaunchPassStore(defaults: makeDefaults())
        #expect(!store.isValid(for: UUID(), at: start))
    }

    @Test func passIsValidDuringGracePeriodAndExpiresExactlyAtEnd() {
        let store = LaunchPassStore(defaults: makeDefaults())
        let rule = UUID()
        store.grant(for: rule, minutes: 5, at: start)

        #expect(store.isValid(for: rule, at: start))
        #expect(store.isValid(for: rule, at: start.addingTimeInterval(299)))
        #expect(!store.isValid(for: rule, at: start.addingTimeInterval(300)))
        #expect(!store.isValid(for: rule, at: start.addingTimeInterval(3600)))
    }

    @Test func checkingDoesNotConsumeThePass() {
        let store = LaunchPassStore(defaults: makeDefaults())
        let rule = UUID()
        store.grant(for: rule, minutes: 5, at: start)
        // Re-trigger right after opening the target app, then several app switches.
        for second in [1, 2, 30, 60, 120, 240] {
            #expect(store.isValid(for: rule, at: start.addingTimeInterval(TimeInterval(second))))
        }
    }

    @Test func passesAreIndependentPerRule() {
        let store = LaunchPassStore(defaults: makeDefaults())
        let instagram = UUID()
        let youtube = UUID()
        store.grant(for: instagram, minutes: 5, at: start)
        #expect(store.isValid(for: instagram, at: start))
        #expect(!store.isValid(for: youtube, at: start))
    }

    @Test func zeroGraceIsRaisedToOneMinuteToAvoidALoop() {
        let store = LaunchPassStore(defaults: makeDefaults())
        let rule = UUID()
        store.grant(for: rule, minutes: 0, at: start)
        // The automation fires again within seconds after Flow opens the app.
        #expect(store.isValid(for: rule, at: start.addingTimeInterval(5)))
        #expect(!store.isValid(for: rule, at: start.addingTimeInterval(60)))
    }

    @Test func passSurvivesAppRestart() {
        let defaults = makeDefaults()
        let rule = UUID()
        LaunchPassStore(defaults: defaults).grant(for: rule, minutes: 10, at: start)
        let reloaded = LaunchPassStore(defaults: defaults)
        #expect(reloaded.isValid(for: rule, at: start.addingTimeInterval(500)))
        #expect(reloaded.validUntil(for: rule, at: start) == start.addingTimeInterval(600))
    }

    @Test func revokeRemovesPass() {
        let store = LaunchPassStore(defaults: makeDefaults())
        let rule = UUID()
        store.grant(for: rule, minutes: 5, at: start)
        store.revoke(for: rule)
        #expect(!store.isValid(for: rule, at: start))
    }

    @Test func grantingPrunesExpiredPasses() {
        let store = LaunchPassStore(defaults: makeDefaults())
        let old = UUID()
        store.grant(for: old, minutes: 1, at: start)
        store.grant(for: UUID(), minutes: 1, at: start.addingTimeInterval(3600))
        #expect(store.expiries[old] == nil)
    }
}

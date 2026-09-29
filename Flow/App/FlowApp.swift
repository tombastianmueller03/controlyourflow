import SwiftUI

@main
struct FlowApp: App {
    @State private var ruleStore = RuleStore.shared
    @State private var demoSession: ChallengeSession?

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                List {
                    ForEach(ruleStore.rules) { rule in
                        Text(rule.name)
                    }
                    Button("Pause ausprobieren") {
                        var settings = ChallengeSettings()
                        settings.taskCount = 3
                        settings.minimumDuration = 15
                        demoSession = ChallengeSession(ruleID: UUID(), ruleName: "Demo", settings: settings)
                    }
                }
                .navigationTitle("Control your Flow")
            }
            .fullScreenCover(item: $demoSession) { session in
                ChallengeView(session: session, onPassed: { demoSession = nil }, onCancel: { demoSession = nil })
            }
        }
    }
}

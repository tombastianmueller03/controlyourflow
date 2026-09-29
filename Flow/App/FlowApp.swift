import SwiftUI

@main
struct FlowApp: App {
    @State private var ruleStore = RuleStore.shared

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                List(ruleStore.rules) { rule in
                    Text(rule.name)
                }
                .navigationTitle("Control your Flow")
            }
        }
    }
}

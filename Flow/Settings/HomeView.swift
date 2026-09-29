import SwiftUI

/// Start screen. Replaced by the full rule management in the next milestone.
struct HomeView: View {
    @Environment(FlowRouter.self) private var router
    @Environment(RuleStore.self) private var ruleStore

    var body: some View {
        NavigationStack {
            List {
                ForEach(ruleStore.rules) { rule in
                    Button(rule.name) { router.startChallenge(for: rule) }
                }
                Button("Beispiel-Regel für Instagram anlegen") {
                    ruleStore.addRule(name: "Instagram", urlScheme: "instagram://")
                }
            }
            .navigationTitle("Control your Flow")
        }
    }
}

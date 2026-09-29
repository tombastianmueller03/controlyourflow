import SwiftUI

/// Global starting values for newly added apps.
struct DefaultsView: View {
    @Environment(RuleStore.self) private var ruleStore

    var body: some View {
        @Bindable var ruleStore = ruleStore
        Form {
            Section {
                Text("Diese Werte bekommen neu hinzugefügte Apps. Bestehende Apps änderst du einzeln.")
                    .foregroundStyle(.secondary)
            }
            ChallengeSettingsSection(settings: $ruleStore.defaultSettings)
        }
        .navigationTitle("Standardwerte")
        .navigationBarTitleDisplayMode(.inline)
    }
}

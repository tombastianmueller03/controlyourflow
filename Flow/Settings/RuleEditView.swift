import SwiftUI
import UIKit

/// Edit one app rule. Changes are saved immediately.
struct RuleEditView: View {
    @Environment(RuleStore.self) private var ruleStore
    @Environment(FlowRouter.self) private var router
    @Environment(\.dismiss) private var dismiss

    @State private var rule: AppRule
    @State private var confirmDelete = false

    init(rule: AppRule) {
        _rule = State(initialValue: rule)
    }

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $rule.name)
                TextField("Adresse zum Öffnen, z. B. instagram://", text: $rule.urlScheme)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                installStatus
            } header: {
                Text("App")
            } footer: {
                Text("Mit dieser Adresse (URL-Scheme) öffnet Flow die App nach der Pause.")
            }

            ChallengeSettingsSection(settings: $rule.settings)

            Section {
                NavigationLink {
                    SetupGuideView(ruleID: rule.id)
                } label: {
                    Label("Automation einrichten", systemImage: "wand.and.stars")
                }
                Button("Pause jetzt ausprobieren") {
                    router.startChallenge(for: rule)
                }
            } footer: {
                Text("Nach bestandener Pause öffnet sich \(rule.name) wie bei der echten Automation.")
            }

            Section {
                Button("App entfernen", role: .destructive) { confirmDelete = true }
            }
        }
        .navigationTitle(rule.name.isEmpty ? String(localized: "App") : rule.name)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: rule) { _, newValue in ruleStore.update(newValue) }
        .confirmationDialog("\(rule.name) entfernen?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Entfernen", role: .destructive) {
                ruleStore.delete(id: rule.id)
                dismiss()
            }
        } message: {
            Text("Lösche danach auch die passende Automation in der Kurzbefehle-App.")
        }
    }

    @ViewBuilder
    private var installStatus: some View {
        if let url = rule.launchURL {
            // canOpenURL only answers for schemes listed in LSApplicationQueriesSchemes.
            if UIApplication.shared.canOpenURL(url) {
                Label("App gefunden", systemImage: "checkmark.circle")
                    .foregroundStyle(.green)
            } else {
                Label("App nicht gefunden – oder Flow kann diese Adresse nicht prüfen", systemImage: "questionmark.circle")
                    .foregroundStyle(.secondary)
            }
        } else {
            Label("Bitte eine Adresse eingeben", systemImage: "exclamationmark.circle")
                .foregroundStyle(.orange)
        }
    }
}

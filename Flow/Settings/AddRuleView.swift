import SwiftUI

/// Pick a template or enter a custom app.
struct AddRuleView: View {
    @Environment(RuleStore.self) private var ruleStore
    @Environment(\.dismiss) private var dismiss

    @State private var customName = ""
    @State private var customScheme = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Vorlagen") {
                    ForEach(availableTemplates) { template in
                        Button {
                            ruleStore.addRule(name: template.name, urlScheme: template.urlScheme)
                            dismiss()
                        } label: {
                            LabeledContent(template.name, value: template.urlScheme)
                        }
                        .tint(.primary)
                    }
                    if availableTemplates.isEmpty {
                        Text("Alle Vorlagen sind schon angelegt.")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    TextField("Name, z. B. Pinterest", text: $customName)
                    TextField("Adresse, z. B. pinterest://", text: $customScheme)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("Hinzufügen") {
                        ruleStore.addRule(
                            name: customName.trimmingCharacters(in: .whitespaces),
                            urlScheme: customScheme.trimmingCharacters(in: .whitespaces)
                        )
                        dismiss()
                    }
                    .disabled(customName.trimmingCharacters(in: .whitespaces).isEmpty || AppRule.launchURL(for: customScheme) == nil)
                } header: {
                    Text("Eigene App")
                } footer: {
                    Text("Die Adresse (URL-Scheme) findest du meist mit einer Websuche nach „<App-Name> URL scheme“.")
                }
            }
            .navigationTitle("App hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
    }

    private var availableTemplates: [AppTemplate] {
        let existing = Set(ruleStore.rules.map { $0.name.lowercased() })
        return AppTemplate.all.filter { !existing.contains($0.name.lowercased()) }
    }
}

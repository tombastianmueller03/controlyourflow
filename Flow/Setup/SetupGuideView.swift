import SwiftUI

/// Step-by-step guide for creating the Shortcuts automation for one app,
/// plus a test that checks whether the automation fires.
///
/// iOS 26 has no API for an app to create or import an automation, so the
/// user sets it up manually. The labels below follow the Shortcuts app and
/// may differ slightly between iOS versions (UNVERIFIED wording on iOS 26).
struct SetupGuideView: View {
    @Environment(RuleStore.self) private var ruleStore
    @Environment(StatsStore.self) private var stats
    @Environment(FlowRouter.self) private var router
    @Environment(\.openURL) private var openURL

    @State private var selectedRuleID: UUID?
    @State private var testFailed = false

    init(ruleID: UUID? = nil) {
        _selectedRuleID = State(initialValue: ruleID)
    }

    var body: some View {
        Form {
            Section {
                Text("Flow merkt nicht von selbst, wann du eine App öffnest. Das übernimmt eine Automation in der Kurzbefehle-App: Sie startet Flow jedes Mal, wenn die gewählte App geöffnet wird. Du richtest sie einmal pro App ein.")
            }

            if ruleStore.rules.isEmpty {
                Section {
                    Text("Füge zuerst auf dem Startbildschirm eine App hinzu.")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section {
                    Picker("App", selection: $selectedRuleID) {
                        ForEach(ruleStore.rules) { rule in
                            Text(rule.name).tag(Optional(rule.id))
                        }
                    }
                }

                if let rule = selectedRule {
                    stepsSection(for: rule)
                    testSection(for: rule)
                }
            }
        }
        .navigationTitle("Automation einrichten")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if selectedRule == nil { selectedRuleID = ruleStore.rules.first?.id }
        }
    }

    private var selectedRule: AppRule? {
        selectedRuleID.flatMap { ruleStore.rule(id: $0) }
    }

    private func stepsSection(for rule: AppRule) -> some View {
        Section {
            SetupStep(number: 1, text: "Öffne die Kurzbefehle-App und tippe unten auf „Automation“.")
            SetupStep(number: 2, text: "Tippe auf „+“ bzw. „Neue Automation“.")
            SetupStep(number: 3, text: "Scrolle zu „App“ und tippe darauf.")
            SetupStep(number: 4, text: "Tippe bei „App“ auf „Auswählen“, wähle \(rule.name) und tippe auf „Fertig“. Nur „Wird geöffnet“ soll markiert sein.")
            SetupStep(number: 5, text: "Wähle „Sofort ausführen“ und schalte „Bei Ausführung mitteilen“ aus. Tippe auf „Weiter“.")
            SetupStep(number: 6, text: "Tippe auf „Neuer leerer Kurzbefehl“, dann auf „Aktion hinzufügen“. Suche nach „Flow“ und wähle „Flow starten für \(rule.name)“. Gibt es den Eintrag nicht, nimm „Flow starten“.")
            SetupStep(number: 7, text: "Kontrolle: In der Automation muss „Flow starten für \(rule.name)“ stehen. Steht dort nur „Flow starten“, tippe darauf und wähle bei „Ziel-App“ \(rule.name). Sonst zeigt Flow nur einen Einrichtungs-Hinweis.")
            SetupStep(number: 8, text: "Tippe auf „Fertig“. Das war’s.")

            Button {
                if let url = URL(string: "shortcuts://") { openURL(url) }
            } label: {
                Label("Kurzbefehle öffnen", systemImage: "arrow.up.forward.app")
            }
        } header: {
            Text("Schritte für \(rule.name)")
        } footer: {
            Text("Die Bezeichnungen können je nach iOS-Version leicht abweichen.")
        }
    }

    private func testSection(for rule: AppRule) -> some View {
        Section {
            Button {
                Task { testFailed = !(await router.testAutomation(for: rule)) }
            } label: {
                Label("Automation testen", systemImage: "checkmark.seal")
            }
            if testFailed {
                Text("\(rule.name) ließ sich nicht öffnen. Prüfe, ob die App installiert ist und ob die Adresse „\(rule.urlScheme)“ stimmt.")
                    .font(.callout)
                    .foregroundStyle(.orange)
            }
            if let last = stats.lastTriggered(ruleID: rule.id) {
                LabeledContent("Zuletzt ausgelöst", value: last.formatted(.relative(presentation: .named)))
            } else {
                LabeledContent("Zuletzt ausgelöst", value: String(localized: "noch nie"))
            }
        } header: {
            Text("Test")
        } footer: {
            Text("Beim Test öffnet Flow \(rule.name). Funktioniert die Automation, erscheint kurz danach die Mathe-Pause. Bleibt \(rule.name) einfach offen, prüfe die Schritte oben, besonders Schritt 5 und 7.")
        }
    }
}

private struct SetupStep: View {
    let number: Int
    let text: String

    init(number: Int, text: LocalizedStringResource) {
        self.number = number
        self.text = String(localized: text)
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .foregroundStyle(Color.accentColor)
                .frame(minWidth: 20)
                .accessibilityHidden(true)
            Text(text)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "Schritt \(number): \(text)"))
    }
}

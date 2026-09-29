import SwiftUI

/// Start screen: list of apps with a pause, plus setup, statistics and defaults.
struct HomeView: View {
    @Environment(RuleStore.self) private var ruleStore
    @Environment(LaunchPassStore.self) private var passes
    @Environment(StatsStore.self) private var stats

    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            List {
                if ruleStore.rules.isEmpty {
                    ContentUnavailableView {
                        Label("Noch keine Apps", systemImage: "hourglass")
                    } description: {
                        Text("Füge eine App hinzu, vor der Flow eine kurze Mathe-Pause zeigen soll.")
                    } actions: {
                        Button("App hinzufügen") { showingAdd = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    Section("Apps") {
                        ForEach(ruleStore.rules) { rule in
                            NavigationLink(value: rule.id) {
                                RuleRow(
                                    rule: rule,
                                    passValidUntil: passes.validUntil(for: rule.id),
                                    lastTriggered: stats.lastTriggered(ruleID: rule.id)
                                )
                            }
                        }
                        .onDelete { offsets in
                            for index in offsets { ruleStore.delete(id: ruleStore.rules[index].id) }
                        }
                        .onMove { ruleStore.move(fromOffsets: $0, toOffset: $1) }
                    }
                }

                Section {
                    NavigationLink(value: Destination.stats) {
                        Label("Statistik", systemImage: "chart.bar")
                    }
                    NavigationLink(value: Destination.defaults) {
                        Label("Standardwerte", systemImage: "slider.horizontal.3")
                    }
                }
            }
            .navigationTitle("Control your Flow")
            .navigationDestination(for: UUID.self) { id in
                if let rule = ruleStore.rule(id: id) {
                    RuleEditView(rule: rule)
                }
            }
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .stats: StatsView()
                case .defaults: DefaultsView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !ruleStore.rules.isEmpty { EditButton() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAdd = true } label: {
                        Label("App hinzufügen", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) { AddRuleView() }
        }
    }

    enum Destination: Hashable {
        case stats
        case defaults
    }
}

private struct RuleRow: View {
    let rule: AppRule
    let passValidUntil: Date?
    let lastTriggered: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(rule.name).font(.headline)
            Text(summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let passValidUntil {
                Label {
                    Text("Frei bis \(passValidUntil, style: .time)")
                } icon: {
                    Image(systemName: "lock.open")
                }
                .font(.caption)
                .foregroundStyle(.green)
            } else if let lastTriggered {
                Text("Zuletzt ausgelöst \(lastTriggered.formatted(.relative(presentation: .named)))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Noch nie ausgelöst – Automation eingerichtet?")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 2)
    }

    private var summary: String {
        let s = rule.settings
        return String(localized: "\(s.taskCount) Aufgaben · \(ChallengeSettingsSection.formatSeconds(s.minimumDuration)) · Stufe \(s.difficulty.rawValue)")
    }
}

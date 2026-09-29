import SwiftUI

/// Local statistics per app and day.
struct StatsView: View {
    @Environment(StatsStore.self) private var stats
    @Environment(RuleStore.self) private var ruleStore
    @State private var confirmReset = false

    var body: some View {
        List {
            Section {
                CountsRow(title: String(localized: "Alle Apps"), counts: stats.totals())
                ForEach(ruleStore.rules) { rule in
                    CountsRow(title: rule.name, counts: stats.totals(ruleID: rule.id))
                }
            } header: {
                Text("Gesamt")
            } footer: {
                Text("„Nicht jetzt“ zählt als abgebrochen – und ist oft die beste Entscheidung.")
            }

            let days = stats.recentDays()
            if days.isEmpty {
                Section {
                    Text("Noch keine Pausen.").foregroundStyle(.secondary)
                }
            }
            ForEach(days, id: \.day) { entry in
                Section(Self.title(forDayKey: entry.day)) {
                    ForEach(entry.perRule.sorted(by: { name(for: $0.key) < name(for: $1.key) }), id: \.key) { ruleID, counts in
                        CountsRow(title: name(for: ruleID), counts: counts)
                    }
                }
            }

            Section {
                Button("Statistik zurücksetzen", role: .destructive) { confirmReset = true }
            } footer: {
                Text("Alle Daten bleiben auf diesem iPhone.")
            }
        }
        .navigationTitle("Statistik")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Statistik zurücksetzen?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Zurücksetzen", role: .destructive) { stats.reset() }
        }
    }

    private func name(for ruleID: UUID) -> String {
        ruleStore.rule(id: ruleID)?.name ?? String(localized: "Gelöschte App")
    }

    static func title(forDayKey key: String) -> String {
        let parser = DateFormatter()
        parser.calendar = Calendar(identifier: .gregorian)
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: key) else { return key }
        if Calendar.current.isDateInToday(date) { return String(localized: "Heute") }
        if Calendar.current.isDateInYesterday(date) { return String(localized: "Gestern") }
        return date.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }
}

private struct CountsRow: View {
    let title: String
    let counts: StatsStore.Counts

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            HStack(spacing: 16) {
                Label("\(counts.started)", systemImage: "play.circle")
                    .accessibilityLabel("\(counts.started) gestartet")
                Label("\(counts.passed)", systemImage: "checkmark.circle")
                    .accessibilityLabel("\(counts.passed) bestanden")
                Label("\(counts.cancelled)", systemImage: "leaf")
                    .accessibilityLabel("\(counts.cancelled) abgebrochen")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}

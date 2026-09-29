import SwiftUI

/// Form rows for editing the pause settings; used per app and for the defaults.
struct ChallengeSettingsSection: View {
    @Binding var settings: ChallengeSettings

    var body: some View {
        Section {
            Stepper(value: $settings.taskCount, in: ChallengeSettings.taskCountRange) {
                LabeledContent("Aufgaben", value: "\(settings.taskCount)")
            }
            Stepper(value: $settings.minimumDuration, in: ChallengeSettings.minimumDurationRange, step: 10) {
                LabeledContent("Mindestdauer", value: Self.formatSeconds(settings.minimumDuration))
            }
            Stepper(value: $settings.penaltySeconds, in: ChallengeSettings.penaltyRange) {
                LabeledContent("Strafzeit bei Fehler", value: Self.formatSeconds(settings.penaltySeconds))
            }
            Stepper(value: $settings.graceMinutes, in: ChallengeSettings.graceRange) {
                LabeledContent("Schonfrist", value: Self.formatMinutes(settings.graceMinutes))
            }
        } header: {
            Text("Pause")
        } footer: {
            Text("Die Pause endet erst, wenn alle Aufgaben richtig gelöst sind und die Mindestdauer vorbei ist. Nach einer bestandenen Pause öffnet sich die App während der Schonfrist ohne neue Pause.")
        }

        Section {
            Picker("Schwierigkeit", selection: $settings.difficulty) {
                ForEach(Difficulty.allCases) { level in
                    Text("\(level.rawValue)").tag(level)
                }
            }
            .pickerStyle(.segmented)
            Text(settings.difficulty.summary)
                .font(.callout)
                .foregroundStyle(.secondary)
        } header: {
            Text("Schwierigkeit")
        }
    }

    static func formatSeconds(_ seconds: Int) -> String {
        Duration.seconds(seconds).formatted(.units(allowed: [.minutes, .seconds], width: .abbreviated))
    }

    static func formatMinutes(_ minutes: Int) -> String {
        Duration.seconds(minutes * 60).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
    }
}

extension Difficulty {
    var summary: String {
        switch self {
        case .level1: String(localized: "Zweistellig plus und minus, z. B. 47 + 38")
        case .level2: String(localized: "Zweistellig mal einstellig, dreistellig plus und minus, z. B. 64 × 7")
        case .level3: String(localized: "Zweistellig mal zweistellig, Prozentrechnen, z. B. 25 % von 360")
        case .level4: String(localized: "Dreistellig mal zweistellig, Quadratzahlen bis 30², Division, z. B. 912 ÷ 12")
        }
    }
}

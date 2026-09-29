import SwiftUI

/// Calm full-screen message after "Nicht jetzt" or when the target app
/// could not be opened.
struct NoticeView: View {
    let notice: FlowRouter.Notice
    var onDone: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: symbol)
                .font(.system(size: 56))
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)
            Text(title)
                .font(.title.weight(.semibold))
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
            Spacer()
            Button(action: onDone) {
                Text("Fertig").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .multilineTextAlignment(.center)
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    private var symbol: String {
        switch notice {
        case .notNow: "leaf"
        case .openFailed: "exclamationmark.triangle"
        case .automationIncomplete: "wand.and.stars"
        }
    }

    private var title: String {
        switch notice {
        case .notNow: String(localized: "Nicht jetzt")
        case .openFailed(let name, _): String(localized: "\(name) ließ sich nicht öffnen")
        case .automationIncomplete: String(localized: "Automation nicht fertig eingerichtet")
        }
    }

    private var message: String {
        switch notice {
        case .notNow(let name):
            String(localized: "Gute Entscheidung. \(name) bleibt zu. Du kannst Flow jetzt einfach schließen.")
        case .openFailed(let name, let scheme):
            String(localized: "Die Pause zählt trotzdem. Vermutlich ist \(name) nicht installiert oder die Adresse „\(scheme)“ stimmt nicht. Du kannst sie in den Einstellungen der App-Regel ändern oder \(name) jetzt selbst öffnen.")
        case .automationIncomplete:
            String(localized: "In der Automation fehlt die Ziel-App. Öffne Kurzbefehle → Automation, tippe auf die Aktion „Flow starten“ und wähle bei „Ziel-App“ die passende App. Die Aktion heißt dann z. B. „Flow starten für YouTube“.")
        }
    }
}

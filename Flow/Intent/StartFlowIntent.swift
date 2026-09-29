import AppIntents
import Foundation

/// "Flow starten": run by the Shortcuts automation "App → Is Opened".
///
/// Starts in the background. With a valid launch pass it ends silently, so
/// the target app just stays open. Otherwise it asks to continue in the
/// foreground and Flow shows the math pause.
struct StartFlowIntent: AppIntent {
    static let title: LocalizedStringResource = "Flow starten"
    static let description = IntentDescription(
        "Zeigt eine Mathe-Pause, bevor die gewählte App geöffnet wird. Gedacht für die Automation „App wird geöffnet“."
    )

    // Prefer background; only come to the foreground when we call
    // continueInForeground (iOS 26 API, replaces openAppWhenRun).
    static let supportedModes: IntentModes = [.background, .foreground(.dynamic)]

    @Parameter(title: "Ziel-App")
    var target: RuleEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Flow starten für \(\.$target)")
    }

    @Dependency private var router: FlowRouter

    init() {}

    init(target: RuleEntity) {
        self.target = target
    }

    // Keep this fast: background intents have a limited time budget
    // (about 30 s). The pause itself runs in the UI after we return.
    @MainActor
    func perform() async throws -> some IntentResult {
        switch router.handleTrigger(ruleID: target.id) {
        case .letThrough:
            return .result()
        case .unknownRule:
            throw FlowIntentError.ruleNotFound
        case .startChallenge, .resumeChallenge:
            if systemContext.currentMode == .background {
                // UNVERIFIED on device: whether the system allows switching to the
                // foreground while the target app is opening under an automation.
                guard systemContext.currentMode.canContinueInForeground else {
                    throw FlowIntentError.cannotShowPause
                }
                try await continueInForeground(alwaysConfirm: false)
            }
            return .result()
        }
    }
}

enum FlowIntentError: Error, CustomLocalizedStringResourceConvertible {
    case ruleNotFound
    case cannotShowPause

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .ruleNotFound:
            "Diese Ziel-App gibt es in Flow nicht mehr. Bitte die Automation neu einrichten."
        case .cannotShowPause:
            "Flow konnte die Pause nicht anzeigen. Öffne Flow, um sie zu starten."
        }
    }
}

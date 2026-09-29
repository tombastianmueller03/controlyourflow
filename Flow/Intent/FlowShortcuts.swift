import AppIntents

/// Registers "Flow starten" as an App Shortcut.
///
/// Calling `updateAppShortcutParameters()` at launch asks the system to
/// (re)read the app's intents. On the first device test (SideStore install)
/// the action only appeared in Shortcuts after this and the German
/// localization were added (v0.1.1).
struct FlowShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartFlowIntent(),
            phrases: [
                // Parameterized phrases make Shortcuts offer one ready-made
                // entry per app rule, with "Ziel-App" already filled in.
                "\(.applicationName) starten für \(\.$target)",
                "Pause vor \(\.$target) mit \(.applicationName)",
                "\(.applicationName) starten",
            ],
            shortTitle: "Flow starten",
            systemImageName: "hourglass"
        )
    }

    static let shortcutTileColor: ShortcutTileColor = .teal
}

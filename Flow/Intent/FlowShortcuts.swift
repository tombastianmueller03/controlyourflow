import AppIntents

/// Registers "Flow starten" as an App Shortcut.
///
/// Not strictly needed for the action to appear in Shortcuts, but calling
/// `updateAppShortcutParameters()` at launch asks the system to (re)read the
/// app's intents. UNVERIFIED: whether this makes the action appear for apps
/// installed via SideStore, where it was missing in the first device test.
struct FlowShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartFlowIntent(),
            phrases: [
                "\(.applicationName) starten",
                "Pause mit \(.applicationName)",
            ],
            shortTitle: "Flow starten",
            systemImageName: "hourglass"
        )
    }

    static let shortcutTileColor: ShortcutTileColor = .teal
}

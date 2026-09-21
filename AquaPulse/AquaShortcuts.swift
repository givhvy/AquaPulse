import AppIntents

struct AquaShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogGlassIntent(),
            phrases: [
                "Log a glass in \(.applicationName)",
                "Log water with \(.applicationName)"
            ],
            shortTitle: "Log glass",
            systemImageName: "drop.fill"
        )
        AppShortcut(
            intent: CheckInRitualIntent(),
            phrases: [
                "Check in a ritual in \(.applicationName)"
            ],
            shortTitle: "Check in",
            systemImageName: "checkmark"
        )
    }
}

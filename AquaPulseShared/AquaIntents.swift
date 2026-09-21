import AppIntents
import WidgetKit

struct LogGlassIntent: AppIntent {
    static var title: LocalizedStringResource = "Log a glass"
    static var description = IntentDescription("Add one glass of water to today’s AquaPulse total.")
    static var openAppWhenRun = false
    static var authenticationPolicy = IntentAuthenticationPolicy.alwaysAllowed

    func perform() async throws -> some IntentResult {
        let snap = AquaPulseData.mutate { $0.logGlass() }
        WidgetCenter.shared.reloadAllTimelines()
        await AquaNotifications.refresh(snap)
        return .result()
    }
}

struct CheckInRitualIntent: AppIntent {
    static var title: LocalizedStringResource = "Check in ritual"
    static var description = IntentDescription("Mark the next open AquaPulse ritual as done.")
    static var openAppWhenRun = false
    static var authenticationPolicy = IntentAuthenticationPolicy.alwaysAllowed

    func perform() async throws -> some IntentResult {
        let snap = AquaPulseData.mutate { $0.checkInNextRitual() }
        WidgetCenter.shared.reloadAllTimelines()
        await AquaNotifications.refresh(snap)
        return .result()
    }
}

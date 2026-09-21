import Foundation
import UserNotifications
import WidgetKit

enum AquaNotifications {
    static let waterCategory = "AQUA_WATER"
    static let logAction = "LOG_GLASS"
    static let youtubeSeedKey = "aqua.seeded.youtube.v1"

    static func refresh(_ snap: AquaSnapshot) async {
        let center = UNUserNotificationCenter.current()
        registerCategories(center)

        let delivered = await center.deliveredNotifications()
        let stale = delivered
            .map(\.request.identifier)
            .filter { $0.hasPrefix("water.") || $0.hasPrefix("ritual.") }
        if !stale.isEmpty {
            center.removeDeliveredNotifications(withIdentifiers: stale)
        }
        center.removeAllPendingNotificationRequests()

        let settings = await center.notificationSettings()
        let allowed = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
        guard allowed, snap.notificationsOn != false else {
            try? await center.setBadgeCount(0)
            return
        }

        let cal = Calendar.current
        let now = Date()
        let step = max(snap.reminderHours, 1)
        let hours = Array(stride(from: 8, through: 21, by: step))

        if snap.remainingML > 0 {
            for hour in hours {
                guard let fire = today(hour: hour, now: now, calendar: cal) else { continue }
                await add(
                    id: "water.0.\(hour)",
                    title: "Time to hydrate",
                    body: snap.waterNotificationBody,
                    date: fire,
                    category: waterCategory,
                    center: center
                )
            }
        }

        if let tomorrow = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: now)) {
            var nextDay = snap
            nextDay.drunkML = 0
            nextDay.rituals = nextDay.rituals.map { ritual in
                var copy = ritual
                copy.doneToday = 0
                return copy
            }
            nextDay.syncWaterRitual()
            for hour in hours {
                guard let fire = cal.date(bySettingHour: hour, minute: 0, second: 0, of: tomorrow) else { continue }
                await add(
                    id: "water.1.\(hour)",
                    title: "Time to hydrate",
                    body: nextDay.waterNotificationBody,
                    date: fire,
                    category: waterCategory,
                    center: center
                )
            }
            for ritual in nextDay.rituals where !ritual.isWater {
                guard let fire = cal.date(bySettingHour: ritual.remindHour, minute: 0, second: 0, of: tomorrow) else { continue }
                await add(
                    id: "ritual.1.\(ritual.id.uuidString)",
                    title: ritual.reminderTitle,
                    body: ritual.reminderBody,
                    date: fire,
                    category: nil,
                    center: center
                )
            }
        }

        for ritual in snap.rituals where !ritual.isWater && !ritual.isComplete {
            guard let fire = today(hour: ritual.remindHour, now: now, calendar: cal) else { continue }
            await add(
                id: "ritual.0.\(ritual.id.uuidString)",
                title: ritual.reminderTitle,
                body: ritual.reminderBody,
                date: fire,
                category: nil,
                center: center
            )
        }

        try? await center.setBadgeCount(snap.glassesLeft)
    }

    @discardableResult
    static func seedYouTubeIfNeeded(_ snap: inout AquaSnapshot) -> Bool {
        let defaults = AquaPulseData.suite
        guard defaults.bool(forKey: youtubeSeedKey) == false else { return false }
        guard snap.didOnboard == true else { return false }
        defaults.set(true, forKey: youtubeSeedKey)
        guard !snap.rituals.contains(where: \.isYouTube) else { return false }
        guard let item = Ritual.catalog.first(where: { $0.kind == "youtube" }) else { return false }
        snap.rituals.append(Ritual.fromCatalog(item))
        return true
    }

    static func handleResponse(_ response: UNNotificationResponse) async {
        let id = response.actionIdentifier
        if id == logAction || (id == UNNotificationDefaultActionIdentifier && response.notification.request.identifier.hasPrefix("water.")) {
            if id == logAction {
                let snap = AquaPulseData.mutate { $0.logGlass() }
                WidgetCenter.shared.reloadAllTimelines()
                await refresh(snap)
            }
        }
    }

    static func shouldPresent(_ notification: UNNotification) -> UNNotificationPresentationOptions {
        let snap = AquaPulseData.load()
        let id = notification.request.identifier
        if id.hasPrefix("water."), snap.remainingML <= 0 {
            return []
        }
        if id.hasPrefix("ritual.") {
            let uuid = id.split(separator: ".").last.map(String.init) ?? ""
            if let ritual = snap.rituals.first(where: { $0.id.uuidString == uuid }), ritual.isComplete {
                return []
            }
        }
        return [.banner, .sound, .badge, .list]
    }

    private static func today(hour: Int, now: Date, calendar: Calendar) -> Date? {
        guard let fire = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: now) else { return nil }
        return fire > now ? fire : nil
    }

    private static func registerCategories(_ center: UNUserNotificationCenter) {
        let log = UNNotificationAction(identifier: logAction, title: "Log a glass", options: [])
        let water = UNNotificationCategory(identifier: waterCategory, actions: [log], intentIdentifiers: [])
        center.setNotificationCategories([water])
    }

    private static func add(
        id: String,
        title: String,
        body: String,
        date: Date,
        category: String?,
        center: UNUserNotificationCenter
    ) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        if let category {
            content.categoryIdentifier = category
        }
        let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
        try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}

final class AquaNotifyCenter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = AquaNotifyCenter()

    static func bootstrap() {
        UNUserNotificationCenter.current().delegate = shared
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        AquaNotifications.shouldPresent(notification)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        await AquaNotifications.handleResponse(response)
    }
}

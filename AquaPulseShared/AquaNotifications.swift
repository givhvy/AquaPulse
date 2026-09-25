import Foundation
import UserNotifications
import WidgetKit

enum AquaNotificationGate {
    private static let lock = NSLock()
    private static var quietUntil = Date.distantPast

    static func noteResponse() {
        lock.lock()
        quietUntil = Date().addingTimeInterval(2.5)
        lock.unlock()
    }

    static var remainingQuiet: TimeInterval {
        lock.lock()
        defer { lock.unlock() }
        return max(0, quietUntil.timeIntervalSinceNow)
    }
}

enum AquaNotifications {
    static let waterCategory = "AQUA_WATER"
    static let logAction = "LOG_GLASS"
    static let creatorSeedKey = "aqua.seeded.creator.v2"

    static func refresh(_ snap: AquaSnapshot, clearDelivered: Bool = false) async {
        await AquaReminderQueue.shared.enqueue(snap, clearDelivered: clearDelivered)
    }

    static func performRefresh(_ snap: AquaSnapshot, clearDelivered: Bool) async {
        let center = UNUserNotificationCenter.current()
        registerCategories(center)

        if clearDelivered {
            let delivered = await center.deliveredNotifications()
            let stale = delivered
                .map(\.request.identifier)
                .filter { $0.hasPrefix("water.") || $0.hasPrefix("ritual.") }
            if !stale.isEmpty {
                center.removeDeliveredNotifications(withIdentifiers: stale)
            }
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
    static func seedCreatorRitualsIfNeeded(_ snap: inout AquaSnapshot) -> Bool {
        let defaults = AquaPulseData.suite
        guard defaults.bool(forKey: creatorSeedKey) == false else { return false }
        guard snap.didOnboard == true else { return false }
        defaults.set(true, forKey: creatorSeedKey)
        var added = false
        for kind in Ritual.creatorKinds {
            guard !snap.rituals.contains(where: { $0.kind == kind }) else { continue }
            guard let item = Ritual.catalog.first(where: { $0.kind == kind }) else { continue }
            snap.rituals.append(Ritual.fromCatalog(item))
            added = true
        }
        return added
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

    static func registerCategories(_ center: UNUserNotificationCenter = .current()) {
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

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler(AquaNotifications.shouldPresent(notification))
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        AquaNotificationGate.noteResponse()
        let shouldLog = response.actionIdentifier == AquaNotifications.logAction
        completionHandler()
        guard shouldLog else { return }
        Task {
            let snap = AquaPulseData.mutate { $0.logGlass() }
            WidgetCenter.shared.reloadAllTimelines()
            await AquaNotifications.refresh(snap, clearDelivered: true)
        }
    }
}

private actor AquaReminderQueue {
    static let shared = AquaReminderQueue()

    private var latest: AquaSnapshot?
    private var clearDelivered = false
    private var waiting: Task<Void, Never>?

    func enqueue(_ snap: AquaSnapshot, clearDelivered: Bool) {
        latest = snap
        self.clearDelivered = self.clearDelivered || clearDelivered
        guard waiting == nil else { return }
        waiting = Task {
            try? await Task.sleep(for: .milliseconds(750))
            await self.drain()
        }
    }

    private func drain() async {
        let quiet = AquaNotificationGate.remainingQuiet
        if quiet > 0 {
            try? await Task.sleep(nanoseconds: UInt64(quiet * 1_000_000_000))
        }
        waiting = nil
        guard let snap = latest else { return }
        let shouldClear = clearDelivered
        latest = nil
        clearDelivered = false
        await AquaNotifications.performRefresh(snap, clearDelivered: shouldClear)
        if latest != nil {
            waiting = Task {
                try? await Task.sleep(for: .milliseconds(300))
                await self.drain()
            }
        }
    }
}

import Foundation
import Observation
@preconcurrency import UserNotifications
import UIKit

struct Ritual: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var symbol: String
    var logo: String
    var kind: String
    var timesPerDay: Int
    var doneToday: Int
    var streak: Int
    var remindHour: Int
    var accent: String

    var isWater: Bool { kind == "water" }
    var remaining: Int { max(timesPerDay - doneToday, 0) }
    var isComplete: Bool { doneToday >= timesPerDay }

    static let empty = Ritual(
        id: UUID(uuidString: "00000000-0000-4000-8000-000000000000")!,
        name: "Drink water",
        symbol: "drop.fill",
        logo: "H2O",
        kind: "water",
        timesPerDay: 10,
        doneToday: 0,
        streak: 0,
        remindHour: 8,
        accent: "teal"
    )

    static let catalog: [(id: UUID, name: String, symbol: String, logo: String, kind: String, times: Int, hour: Int, accent: String, streak: Int, done: Int)] = [
        (UUID(uuidString: "11111111-1111-4111-8111-111111111111")!, "Drink water", "drop.fill", "H2O", "water", 10, 8, "teal", 12, 5),
        (UUID(uuidString: "11111111-1111-4111-8111-111111111112")!, "Morning stretch", "figure.flexibility", "STR", "stretch", 1, 7, "blue", 8, 1),
        (UUID(uuidString: "11111111-1111-4111-8111-111111111113")!, "Read 20 min", "book.fill", "READ", "read", 1, 21, "orange", 6, 0),
        (UUID(uuidString: "11111111-1111-4111-8111-111111111114")!, "Walk 8k", "figure.walk", "WALK", "walk", 1, 18, "teal", 21, 0),
        (UUID(uuidString: "11111111-1111-4111-8111-111111111115")!, "Vitamins", "pills.fill", "VIT", "vitamins", 1, 9, "red", 14, 1),
        (UUID(uuidString: "11111111-1111-4111-8111-111111111116")!, "Sleep by 11", "moon.fill", "REST", "sleep", 1, 22, "purple", 4, 0),
        (UUID(uuidString: "11111111-1111-4111-8111-111111111117")!, "Journal", "book.closed.fill", "INK", "journal", 1, 22, "orange", 3, 0),
        (UUID(uuidString: "11111111-1111-4111-8111-111111111118")!, "No late caffeine", "cup.and.saucer.fill", "CAF", "caffeine", 1, 14, "red", 9, 1)
    ]

    static func defaults() -> [Ritual] {
        catalog.map {
            Ritual(
                id: $0.id,
                name: $0.name,
                symbol: $0.symbol,
                logo: $0.logo,
                kind: $0.kind,
                timesPerDay: $0.times,
                doneToday: $0.done,
                streak: $0.streak,
                remindHour: $0.hour,
                accent: $0.accent
            )
        }
    }
}

struct AquaSnapshot: Codable {
    var name: String
    var goalML: Int
    var glassML: Int
    var drunkML: Int
    var reminderHours: Int
    var lastDay: Date
    var rituals: [Ritual]
    var weekMarks: [String: [Bool]]
    var notificationsOn: Bool?
}

@MainActor
@Observable
final class AquaStore {
    var name = "Maya Chen"
    var goalML = 2500
    var glassML = 250
    var drunkML = 1250
    var reminderHours = 2
    var lastDay = Date()
    var rituals: [Ritual] = Ritual.defaults()
    var weekMarks: [String: [Bool]] = [:]
    var notificationsOn = false

    var glassesGoal: Int { max(goalML / max(glassML, 1), 1) }
    var glassesDrunk: Int { min(drunkML / max(glassML, 1), 16) }
    var litersDrunk: String { String(format: "%.2f", Double(drunkML) / 1000).replacingOccurrences(of: ".00", with: "") }
    var litersGoal: String { String(format: "%.1f", Double(goalML) / 1000) }
    var remainingML: Int { max(goalML - drunkML, 0) }
    var doneCount: Int { rituals.filter(\.isComplete).count }
    var bestStreak: Ritual { rituals.max(by: { $0.streak < $1.streak }) ?? .empty }
    var waterRitual: Ritual? { rituals.first(where: \.isWater) }

    func ritual(id: UUID) -> Ritual {
        rituals.first { $0.id == id } ?? waterRitual ?? .empty
    }

    init() {
        load()
        rollDayIfNeeded()
        seedWeekIfNeeded()
        syncWaterRitual()
    }

    func setGlassSize(_ ml: Int) {
        glassML = ml
        syncWaterRitual()
        persist()
    }

    func logGlass() {
        drunkML = min(drunkML + glassML, goalML * 2)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        syncWaterRitual()
        persist()
    }

    func setGlasses(_ count: Int) {
        drunkML = max(count, 0) * glassML
        syncWaterRitual()
        persist()
    }

    func setDone(_ id: UUID, count: Int) {
        guard let i = rituals.firstIndex(where: { $0.id == id }) else { return }
        let wasComplete = rituals[i].isComplete
        rituals[i].doneToday = min(max(count, 0), max(rituals[i].timesPerDay, 1))
        if rituals[i].isWater {
            drunkML = rituals[i].doneToday * glassML
        } else if rituals[i].isComplete && !wasComplete {
            rituals[i].streak += 1
        }
        markToday(rituals[i])
        persist()
    }

    func addRitual(name: String, symbol: String, times: Int, hour: Int) {
        let logo = String(name.uppercased().filter(\.isLetter).prefix(4))
        rituals.append(
            Ritual(
                id: UUID(),
                name: name,
                symbol: symbol,
                logo: logo.isEmpty ? "NEW" : logo,
                kind: "custom",
                timesPerDay: max(times, 1),
                doneToday: 0,
                streak: 0,
                remindHour: hour,
                accent: ["teal", "blue", "orange", "red", "purple"].randomElement()!
            )
        )
        persist()
        scheduleReminders()
    }

    func requestReminders() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] ok, _ in
            Task { @MainActor in
                guard let self else { return }
                self.notificationsOn = ok
                self.persist()
                if ok { self.scheduleReminders() }
            }
        }
    }

    func scheduleReminders() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { [weak self] settings in
            Task { @MainActor in
                guard let self else { return }
                let allowed = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
                self.notificationsOn = allowed
                self.persist()
                guard allowed else { return }
                center.removeAllPendingNotificationRequests()
                let step = max(self.reminderHours, 1)
                for hour in stride(from: 8, through: 21, by: step) {
                    var components = DateComponents()
                    components.hour = hour
                    components.minute = 0
                    let content = UNMutableNotificationContent()
                    content.title = "Time to hydrate"
                    content.body = "\(self.remainingML) ml left to hit \(self.litersGoal) L today."
                    content.sound = .default
                    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                    try? await center.add(UNNotificationRequest(identifier: "water.\(hour)", content: content, trigger: trigger))
                }
                for ritual in self.rituals where !ritual.isWater {
                    var components = DateComponents()
                    components.hour = ritual.remindHour
                    components.minute = 0
                    let content = UNMutableNotificationContent()
                    content.title = ritual.name
                    content.body = ritual.isComplete ? "Already done — keep the \(ritual.streak) day streak." : "One check-in keeps this ritual alive."
                    content.sound = .default
                    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                    try? await center.add(UNNotificationRequest(identifier: "ritual.\(ritual.id.uuidString)", content: content, trigger: trigger))
                }
            }
        }
    }

    private func syncWaterRitual() {
        guard let i = rituals.firstIndex(where: \.isWater) else { return }
        rituals[i].timesPerDay = glassesGoal
        rituals[i].doneToday = min(glassesDrunk, glassesGoal)
        markToday(rituals[i])
    }

    private func markToday(_ ritual: Ritual) {
        var days = weekMarks[ritual.id.uuidString] ?? Array(repeating: false, count: 7)
        let weekday = Calendar.current.component(.weekday, from: Date())
        let index = (weekday + 5) % 7
        days[index] = ritual.isComplete
        weekMarks[ritual.id.uuidString] = days
    }

    private func seedWeekIfNeeded() {
        let weekday = Calendar.current.component(.weekday, from: Date())
        let today = (weekday + 5) % 7
        for ritual in rituals {
            if weekMarks[ritual.id.uuidString] == nil {
                let days = (0..<7).map { day -> Bool in
                    if day > today { return false }
                    if day == today { return ritual.isComplete }
                    return ritual.streak >= (today - day)
                }
                weekMarks[ritual.id.uuidString] = days
            }
        }
    }

    private func rollDayIfNeeded() {
        let cal = Calendar.current
        guard !cal.isDateInToday(lastDay) else { return }
        if cal.isDateInYesterday(lastDay) {
            for i in rituals.indices {
                if !rituals[i].isComplete {
                    rituals[i].streak = 0
                }
                rituals[i].doneToday = 0
            }
        } else {
            for i in rituals.indices {
                rituals[i].streak = 0
                rituals[i].doneToday = 0
            }
        }
        drunkML = 0
        lastDay = Date()
        persist()
    }

    private func persist() {
        let snap = AquaSnapshot(
            name: name,
            goalML: goalML,
            glassML: glassML,
            drunkML: drunkML,
            reminderHours: reminderHours,
            lastDay: lastDay,
            rituals: rituals,
            weekMarks: weekMarks,
            notificationsOn: notificationsOn
        )
        if let data = try? JSONEncoder().encode(snap) {
            UserDefaults.standard.set(data, forKey: "aqua.pulse.v3")
        }
    }

    private func load() {
        let data = UserDefaults.standard.data(forKey: "aqua.pulse.v3")
            ?? UserDefaults.standard.data(forKey: "aqua.pulse.v2")
        guard let data,
              let snap = try? JSONDecoder().decode(AquaSnapshot.self, from: data) else { return }
        name = snap.name
        goalML = snap.goalML
        glassML = snap.glassML
        drunkML = snap.drunkML
        reminderHours = snap.reminderHours
        lastDay = snap.lastDay
        rituals = snap.rituals
        weekMarks = snap.weekMarks
        notificationsOn = snap.notificationsOn ?? false
    }
}

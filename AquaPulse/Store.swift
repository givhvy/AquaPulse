import AuthenticationServices
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
        timesPerDay: 8,
        doneToday: 0,
        streak: 0,
        remindHour: 8,
        accent: "teal"
    )

    static let catalog: [(id: UUID, name: String, symbol: String, logo: String, kind: String, times: Int, hour: Int, accent: String)] = [
        (UUID(uuidString: "11111111-1111-4111-8111-111111111111")!, "Drink water", "drop.fill", "H2O", "water", 8, 8, "teal"),
        (UUID(uuidString: "11111111-1111-4111-8111-111111111112")!, "Morning stretch", "figure.flexibility", "STR", "stretch", 1, 7, "blue"),
        (UUID(uuidString: "11111111-1111-4111-8111-111111111113")!, "Read 20 min", "book.fill", "READ", "read", 1, 21, "orange"),
        (UUID(uuidString: "11111111-1111-4111-8111-111111111114")!, "Walk", "figure.walk", "WALK", "walk", 1, 18, "teal"),
        (UUID(uuidString: "11111111-1111-4111-8111-111111111115")!, "Vitamins", "pills.fill", "VIT", "vitamins", 1, 9, "red"),
        (UUID(uuidString: "11111111-1111-4111-8111-111111111116")!, "Sleep by 11", "moon.fill", "REST", "sleep", 1, 22, "purple"),
        (UUID(uuidString: "11111111-1111-4111-8111-111111111117")!, "Journal", "book.closed.fill", "INK", "journal", 1, 22, "orange"),
        (UUID(uuidString: "11111111-1111-4111-8111-111111111118")!, "No late caffeine", "cup.and.saucer.fill", "CAF", "caffeine", 1, 14, "red")
    ]

    static func fromCatalog(_ item: (id: UUID, name: String, symbol: String, logo: String, kind: String, times: Int, hour: Int, accent: String)) -> Ritual {
        Ritual(
            id: item.id,
            name: item.name,
            symbol: item.symbol,
            logo: item.logo,
            kind: item.kind,
            timesPerDay: item.times,
            doneToday: 0,
            streak: 0,
            remindHour: item.hour,
            accent: item.accent
        )
    }

    static var extraTemplates: [Ritual] {
        catalog.filter { $0.kind != "water" }.map(fromCatalog)
    }

    static func water(times: Int) -> Ritual {
        var ritual = fromCatalog(catalog[0])
        ritual.timesPerDay = max(times, 1)
        return ritual
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
    var appleUserID: String?
    var appleEmail: String?
    var didOnboard: Bool?
}

@MainActor
@Observable
final class AquaStore {
    static let persistKey = "aqua.pulse.v4"

    var name = ""
    var goalML = 2000
    var glassML = 250
    var drunkML = 0
    var reminderHours = 2
    var lastDay = Date()
    var rituals: [Ritual] = [Ritual.water(times: 8)]
    var weekMarks: [String: [Bool]] = [:]
    var notificationsOn = false
    var appleUserID: String?
    var appleEmail: String?
    var avatarImage: UIImage?
    var didOnboard = false

    var isSignedIn: Bool { appleUserID != nil }
    var displayName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "You" : trimmed
    }
    var firstName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "there" }
        return trimmed.split(whereSeparator: \.isWhitespace).first.map(String.init) ?? trimmed
    }

    var glassesGoal: Int { max(goalML / max(glassML, 1), 1) }
    var glassesDrunk: Int { min(drunkML / max(glassML, 1), 16) }
    var litersDrunk: String { String(format: "%.2f", Double(drunkML) / 1000).replacingOccurrences(of: ".00", with: "") }
    var litersGoal: String { String(format: "%.1f", Double(goalML) / 1000) }
    var remainingML: Int { max(goalML - drunkML, 0) }
    var doneCount: Int { rituals.filter(\.isComplete).count }
    var bestStreak: Ritual { rituals.max(by: { $0.streak < $1.streak }) ?? .empty }
    var waterRitual: Ritual? { rituals.first(where: \.isWater) }
    var hasAnyStreak: Bool { rituals.contains { $0.streak > 0 } }

    func ritual(id: UUID) -> Ritual {
        rituals.first { $0.id == id } ?? waterRitual ?? .empty
    }

    init() {
        load()
        loadAvatar()
        if rituals.isEmpty { rituals = [Ritual.water(times: glassesGoal)] }
        rollDayIfNeeded()
        seedWeekIfNeeded()
        syncWaterRitual()
        checkAppleCredential()
    }

    func finishOnboarding(name: String, goalML: Int, glassML: Int, extraKinds: Set<String>) {
        setName(name)
        self.goalML = goalML
        self.glassML = glassML
        drunkML = 0
        var next = [Ritual.water(times: max(goalML / max(glassML, 1), 1))]
        for item in Ritual.catalog where extraKinds.contains(item.kind) && item.kind != "water" {
            next.append(Ritual.fromCatalog(item))
        }
        rituals = next
        weekMarks = [:]
        seedWeekIfNeeded()
        didOnboard = true
        persist()
    }

    func setName(_ value: String) {
        name = value.trimmingCharacters(in: .whitespacesAndNewlines)
        persist()
    }

    func setGoalML(_ ml: Int) {
        goalML = min(max(ml, 500), 5000)
        syncWaterRitual()
        persist()
    }

    func setGlassSize(_ ml: Int) {
        glassML = ml
        syncWaterRitual()
        persist()
    }

    func setAvatar(_ image: UIImage) {
        let sized = image.aquaSquared(max: 512)
        avatarImage = sized
        if let data = sized.jpegData(compressionQuality: 0.86) {
            try? data.write(to: Self.avatarURL, options: .atomic)
        }
    }

    func clearAvatar() {
        avatarImage = nil
        try? FileManager.default.removeItem(at: Self.avatarURL)
    }

    func applyApple(_ credential: ASAuthorizationAppleIDCredential) {
        appleUserID = credential.user
        if let email = credential.email, !email.isEmpty {
            appleEmail = email
        }
        let appleName = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !appleName.isEmpty {
            name = appleName
        }
        persist()
    }

    func signOutApple() {
        appleUserID = nil
        appleEmail = nil
        persist()
    }

    func checkAppleCredential() {
        guard let id = appleUserID else { return }
        ASAuthorizationAppleIDProvider().getCredentialState(forUserID: id) { [weak self] state, _ in
            Task { @MainActor in
                if state == .revoked || state == .notFound {
                    self?.signOutApple()
                }
            }
        }
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
        seedWeekIfNeeded()
        persist()
        scheduleReminders()
    }

    func addCatalogRitual(_ ritual: Ritual) {
        guard !rituals.contains(where: { $0.id == ritual.id }) else { return }
        rituals.append(ritual)
        seedWeekIfNeeded()
        persist()
        scheduleReminders()
    }

    func deleteRitual(_ id: UUID) {
        guard let ritual = rituals.first(where: { $0.id == id }), !ritual.isWater else { return }
        rituals.removeAll { $0.id == id }
        weekMarks.removeValue(forKey: id.uuidString)
        persist()
        scheduleReminders()
    }

    func resetAllData() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UserDefaults.standard.removeObject(forKey: Self.persistKey)
        try? FileManager.default.removeItem(at: Self.avatarURL)
        name = ""
        goalML = 2000
        glassML = 250
        drunkML = 0
        reminderHours = 2
        lastDay = Date()
        rituals = [Ritual.water(times: 8)]
        weekMarks = [:]
        notificationsOn = false
        appleUserID = nil
        appleEmail = nil
        avatarImage = nil
        didOnboard = false
        seedWeekIfNeeded()
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
        for ritual in rituals where weekMarks[ritual.id.uuidString] == nil {
            weekMarks[ritual.id.uuidString] = Array(repeating: false, count: 7)
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
            notificationsOn: notificationsOn,
            appleUserID: appleUserID,
            appleEmail: appleEmail,
            didOnboard: didOnboard
        )
        if let data = try? JSONEncoder().encode(snap) {
            UserDefaults.standard.set(data, forKey: Self.persistKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.persistKey),
              let snap = try? JSONDecoder().decode(AquaSnapshot.self, from: data) else { return }
        name = snap.name
        goalML = snap.goalML
        glassML = snap.glassML
        drunkML = snap.drunkML
        reminderHours = snap.reminderHours
        lastDay = snap.lastDay
        rituals = snap.rituals.isEmpty ? [Ritual.water(times: 8)] : snap.rituals
        weekMarks = snap.weekMarks
        notificationsOn = snap.notificationsOn ?? false
        appleUserID = snap.appleUserID
        appleEmail = snap.appleEmail
        didOnboard = snap.didOnboard ?? false
    }

    private func loadAvatar() {
        guard let data = try? Data(contentsOf: Self.avatarURL),
              let image = UIImage(data: data) else { return }
        avatarImage = image
    }

    private static var avatarURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("aqua.avatar.jpg")
    }
}

private extension UIImage {
    func aquaSquared(max maxSide: CGFloat) -> UIImage {
        let side = min(min(size.width, size.height), maxSide)
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side))
        return renderer.image { _ in
            let scale = max(side / size.width, side / size.height)
            let fitted = CGSize(width: size.width * scale, height: size.height * scale)
            let origin = CGPoint(x: (side - fitted.width) / 2, y: (side - fitted.height) / 2)
            draw(in: CGRect(origin: origin, size: fitted))
        }
    }
}

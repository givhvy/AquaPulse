import Foundation

struct Ritual: Identifiable, Codable, Equatable, Hashable, Sendable {
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
    var isYouTube: Bool { kind == "youtube" }
    var remaining: Int { max(timesPerDay - doneToday, 0) }
    var isComplete: Bool { doneToday >= timesPerDay }

    var reminderTitle: String { isYouTube ? "YouTube upload" : name }
    var reminderBody: String {
        if isYouTube {
            return isComplete
                ? "Uploaded today — \(streak) day streak."
                : "Upload today to keep your YouTube streak going."
        }
        return isComplete
            ? "Already done — keep the \(streak) day streak."
            : "One check-in keeps this ritual alive."
    }

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
        (UUID(uuidString: "11111111-1111-4111-8111-111111111118")!, "No late caffeine", "cup.and.saucer.fill", "CAF", "caffeine", 1, 14, "red"),
        (UUID(uuidString: "11111111-1111-4111-8111-111111111119")!, "Upload to YouTube", "play.rectangle.fill", "YT", "youtube", 1, 17, "red")
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

struct AquaSnapshot: Codable, Equatable, Sendable {
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

    static var empty: AquaSnapshot {
        AquaSnapshot(
            name: "",
            goalML: 2000,
            glassML: 250,
            drunkML: 0,
            reminderHours: 2,
            lastDay: Date(),
            rituals: [Ritual.water(times: 8)],
            weekMarks: [:],
            notificationsOn: false,
            appleUserID: nil,
            appleEmail: nil,
            didOnboard: false
        )
    }

    static var preview: AquaSnapshot {
        var snap = empty
        snap.name = "Huy"
        snap.didOnboard = true
        snap.drunkML = 750
        snap.rituals = [
            {
                var water = Ritual.water(times: 8)
                water.doneToday = 3
                water.streak = 4
                return water
            }(),
            {
                var stretch = Ritual.fromCatalog(Ritual.catalog[1])
                stretch.doneToday = 0
                stretch.streak = 2
                return stretch
            }()
        ]
        return snap
    }

    var glassesGoal: Int { max(goalML / max(glassML, 1), 1) }
    var glassesDrunk: Int { min(drunkML / max(glassML, 1), 16) }
    var litersDrunk: String { String(format: "%.2f", Double(drunkML) / 1000).replacingOccurrences(of: ".00", with: "") }
    var litersGoal: String { String(format: "%.1f", Double(goalML) / 1000) }
    var remainingML: Int { max(goalML - drunkML, 0) }
    var glassesLeft: Int { max(glassesGoal - glassesDrunk, 0) }
    var waterNotificationBody: String {
        if remainingML <= 0 {
            return "Goal hit — \(litersGoal) L is done for today."
        }
        return "\(remainingML) ml left to hit \(litersGoal) L (\(glassesDrunk)/\(glassesGoal) glasses)."
    }
    var remainingLabel: String {
        if remainingML == 0 { return "Nice work today" }
        if remainingML >= 1000 {
            let liters = String(format: "%.2f", Double(remainingML) / 1000).replacingOccurrences(of: ".00", with: "")
            return "\(liters) L left"
        }
        return "\(remainingML) ml left"
    }
    var progress: Double { min(Double(drunkML) / Double(max(goalML, 1)), 1) }
    var isGoalMet: Bool { drunkML >= goalML }
    var waterRitual: Ritual? { rituals.first(where: \.isWater) }
    var nextOpenRitual: Ritual? { rituals.first { !$0.isWater && !$0.isComplete } }
    var firstName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "there" }
        return trimmed.split(whereSeparator: \.isWhitespace).first.map(String.init) ?? trimmed
    }

    mutating func rollDayIfNeeded(now: Date = Date()) {
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
        lastDay = now
        syncWaterRitual()
    }

    mutating func logGlass() {
        rollDayIfNeeded()
        drunkML = min(drunkML + glassML, goalML * 2)
        syncWaterRitual()
    }

    mutating func checkInRitual(id: UUID) {
        rollDayIfNeeded()
        guard let i = rituals.firstIndex(where: { $0.id == id }) else { return }
        let wasComplete = rituals[i].isComplete
        rituals[i].doneToday = min(rituals[i].doneToday + 1, max(rituals[i].timesPerDay, 1))
        if rituals[i].isWater {
            drunkML = rituals[i].doneToday * glassML
        } else if rituals[i].isComplete && !wasComplete {
            rituals[i].streak += 1
        }
        markToday(rituals[i])
    }

    mutating func checkInNextRitual() {
        if let next = nextOpenRitual {
            checkInRitual(id: next.id)
        } else {
            logGlass()
        }
    }

    mutating func syncWaterRitual() {
        guard let i = rituals.firstIndex(where: \.isWater) else { return }
        rituals[i].timesPerDay = glassesGoal
        rituals[i].doneToday = min(glassesDrunk, glassesGoal)
        markToday(rituals[i])
    }

    mutating func markToday(_ ritual: Ritual) {
        var days = weekMarks[ritual.id.uuidString] ?? Array(repeating: false, count: 7)
        let weekday = Calendar.current.component(.weekday, from: Date())
        let index = (weekday + 5) % 7
        days[index] = ritual.isComplete
        weekMarks[ritual.id.uuidString] = days
    }
}

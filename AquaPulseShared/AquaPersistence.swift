import Foundation
import Security

enum AquaPulseData {
    static let persistKey = "aqua.pulse.v4"
    static let darwinName = "global.huy.AquaPulse.storeDidChange"
    static let keychainService = "global.huy.AquaPulse"
    static let accessGroup = "337LP258Y2.global.huy.AquaPulse"

    private static let lock = NSLock()

    static var suite: UserDefaults { .standard }

    static func load() -> AquaSnapshot {
        lock.lock()
        var snap = loadUnlocked()
        let previousDay = snap.lastDay
        snap.rollDayIfNeeded()
        let rolled = !Calendar.current.isDate(previousDay, inSameDayAs: snap.lastDay)
        let seeded = AquaNotifications.seedCreatorRitualsIfNeeded(&snap)
        if rolled || seeded {
            saveUnlocked(snap)
        }
        lock.unlock()
        if rolled || seeded {
            postChangeUnlocked()
        }
        if rolled {
            Task { await AquaNotifications.refresh(snap) }
        }
        return snap
    }

    static func save(_ snap: AquaSnapshot) {
        lock.lock()
        defer { lock.unlock() }
        saveUnlocked(snap)
    }

    @discardableResult
    static func mutate(_ body: (inout AquaSnapshot) -> Void) -> AquaSnapshot {
        lock.lock()
        defer { lock.unlock() }
        var snap = loadUnlocked()
        snap.rollDayIfNeeded()
        body(&snap)
        saveUnlocked(snap)
        postChangeUnlocked()
        return snap
    }

    static func clear() {
        lock.lock()
        defer { lock.unlock() }
        UserDefaults.standard.removeObject(forKey: persistKey)
        UserDefaults.standard.removeObject(forKey: AquaNotifications.creatorSeedKey)
        deleteKeychain()
        postChangeUnlocked()
    }

    private static func loadUnlocked() -> AquaSnapshot {
        if let data = loadKeychain(), let snap = decode(data) {
            return snap
        }
        if let data = UserDefaults.standard.data(forKey: persistKey), let snap = decode(data) {
            saveKeychain(data)
            return snap
        }
        return .empty
    }

    private static func saveUnlocked(_ snap: AquaSnapshot) {
        guard let data = try? JSONEncoder().encode(snap) else { return }
        UserDefaults.standard.set(data, forKey: persistKey)
        saveKeychain(data)
    }

    private static func decode(_ data: Data) -> AquaSnapshot? {
        try? JSONDecoder().decode(AquaSnapshot.self, from: data)
    }

    private static func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: persistKey,
            kSecAttrAccessGroup as String: accessGroup
        ]
    }

    private static func loadKeychain() -> Data? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else { return nil }
        return item as? Data
    }

    @discardableResult
    private static func saveKeychain(_ data: Data) -> Bool {
        deleteKeychain()
        var query = baseQuery()
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    private static func deleteKeychain() {
        SecItemDelete(baseQuery() as CFDictionary)
    }

    private static func postChangeUnlocked() {
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(darwinName as CFString),
            nil,
            nil,
            true
        )
    }
}

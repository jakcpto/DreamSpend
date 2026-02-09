import Foundation

struct DraftBucket: Codable {
    var dayIndex: Int
    var items: [SpendItem]
}

struct GameSnapshot: Codable {
    var settings: Settings
    var days: [DayEntry]
    var achievements: [Achievement]
    var currentStreak: Int
    var nextDayAmountMinor: Int64
    var nextDayCurrencyCode: String
    var pendingConversionRateUsed: Decimal?
    var isPausedAfterMaximum: Bool
    var draftBuckets: [DraftBucket]?
    var customCategories: [String]?
}

protocol PersistenceControllerProtocol {
    func loadSnapshot() -> GameSnapshot?
    func saveSnapshot(_ snapshot: GameSnapshot)
}

final class PersistenceController: PersistenceControllerProtocol {
    private let defaults: UserDefaults
    private let storageKey = "dreamspend.snapshot.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadSnapshot() -> GameSnapshot? {
        guard let data = defaults.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(GameSnapshot.self, from: data)
    }

    func saveSnapshot(_ snapshot: GameSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: storageKey)
    }
}

import Foundation

struct Achievement: Identifiable, Codable, Hashable, Sendable {
    var id: AchievementKind { kind }
    var kind: AchievementKind
    var earnedAt: Date?

    var isEarned: Bool {
        earnedAt != nil
    }
}

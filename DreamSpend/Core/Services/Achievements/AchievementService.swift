import Foundation

struct AchievementService {
    func bootstrap() -> [Achievement] {
        AchievementKind.allCases.map { Achievement(kind: $0, earnedAt: nil) }
    }

    func evaluate(
        achievements: [Achievement],
        streak: Int,
        day: DayEntry,
        reachedMaximum: Bool,
        now: Date = Date()
    ) -> [Achievement] {
        var map = Dictionary(uniqueKeysWithValues: achievements.map { ($0.kind, $0) })

        for kind in AchievementKind.allCases {
            guard map[kind]?.earnedAt == nil else { continue }

            if let required = kind.requiredStreak, streak >= required {
                map[kind]?.earnedAt = now
                continue
            }

            if kind == .perfectFill, day.isPerfectFill {
                map[kind]?.earnedAt = now
                continue
            }

            if kind == .reachedMaximum, reachedMaximum {
                map[kind]?.earnedAt = now
            }
        }

        return AchievementKind.allCases.compactMap { map[$0] }
    }
}

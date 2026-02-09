import Foundation

struct StreakService {
    func nextStreak(current: Int, didFillToday: Bool) -> Int {
        didFillToday ? current + 1 : current
    }

    func shouldResetAfterMissed(days: [DayEntry]) -> Bool {
        let tail = days.sorted { $0.dayIndex < $1.dayIndex }.suffix(2)
        guard tail.count == 2 else { return false }
        return tail.allSatisfy { $0.status == .missed }
    }
}

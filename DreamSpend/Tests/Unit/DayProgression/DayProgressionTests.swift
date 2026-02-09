import XCTest
@testable import DreamSpend

final class DayProgressionTests: XCTestCase {
    @MainActor
    func testDailyLimitDoublesOnNextDay() {
        let persistence = InMemoryPersistenceController()
        let store = GameStateStore(persistence: persistence)

        let day0 = Date(timeIntervalSince1970: 1_700_000_000)
        store.ensureTodayEntry(now: day0)

        let firstLimit = store.todayEntry?.dailyLimitMinor
        store.ensureTodayEntry(now: day0.addingDays(1))

        let secondDay = store.days.last

        XCTAssertEqual(secondDay?.dailyLimitMinor, (firstLimit ?? 0) * 2)
    }
}

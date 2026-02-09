import XCTest
@testable import DreamSpend

final class StreakResetTests: XCTestCase {
    func testStreakResetsAfterTwoMissedDays() {
        let service = StreakService()

        let days: [DayEntry] = [
            DayEntry(dayIndex: 1, date: .now, currencyCode: "USD", dailyLimitMinor: 1000, status: .filled),
            DayEntry(dayIndex: 2, date: .now.addingTimeInterval(86_400), currencyCode: "USD", dailyLimitMinor: 2000, status: .missed),
            DayEntry(dayIndex: 3, date: .now.addingTimeInterval(172_800), currencyCode: "USD", dailyLimitMinor: 4000, status: .missed)
        ]

        XCTAssertTrue(service.shouldResetAfterMissed(days: days))
    }
}

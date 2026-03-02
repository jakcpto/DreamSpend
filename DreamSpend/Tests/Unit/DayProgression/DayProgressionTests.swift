import XCTest
@testable import DreamSpend

final class DayProgressionTests: XCTestCase {
    @MainActor
    func testDailyLimitDoublesOnNextDayWhenYesterdayFilled() {
        let persistence = InMemoryPersistenceController()
        let store = GameStateStore(persistence: persistence)

        let day0 = store.days.last?.date ?? Date()
        let day0Limit = store.days.last?.dailyLimitMinor ?? 0
        XCTAssertTrue(
            store.saveToday(items: [SpendItem(title: "Meal", amountMinor: day0Limit)], now: day0)
        )

        let firstLimit = store.todayEntry?.dailyLimitMinor
        store.ensureTodayEntry(now: day0.addingDays(1))

        let secondDay = store.days.last

        XCTAssertEqual(secondDay?.dailyLimitMinor, (firstLimit ?? 0) * 2)
    }

    @MainActor
    func testDailyLimitStaysSameWhenYesterdayMissed() {
        let persistence = InMemoryPersistenceController()
        let store = GameStateStore(persistence: persistence)

        let day0 = store.days.last?.date ?? Date()
        store.ensureTodayEntry(now: day0.addingDays(1))

        let day1Limit = store.days.last?.dailyLimitMinor

        store.ensureTodayEntry(now: day0.addingDays(2))
        let day2 = store.days.last

        XCTAssertEqual(day2?.dailyLimitMinor, day1Limit)
    }

    @MainActor
    func testLanguageSwitchRoundTripDoesNotChangeNextDayBudget() {
        let persistence = InMemoryPersistenceController()
        let store = GameStateStore(persistence: persistence)

        store.updateStartAmount(50_000, language: .ru)
        store.updateMaxAmount(500_000, language: .ru)
        store.updateLanguage(.ru)
        store.restartGame()
        let day0 = store.days.last?.date ?? Date()
        let day0Limit = store.todayEntry?.dailyLimitMinor ?? 0

        XCTAssertTrue(
            store.saveToday(items: [SpendItem(title: "Coffee", amountMinor: day0Limit)], now: day0)
        )

        let expectedNext = (store.todayEntry?.dailyLimitMinor ?? 0) * 2

        store.updateLanguage(.en)
        store.updateLanguage(.ru)
        store.ensureTodayEntry(now: day0.addingDays(1))

        XCTAssertEqual(store.days.last?.dailyLimitMinor, expectedNext)
    }

    @MainActor
    func testRenamingCustomCategoryUpdatesSavedAndDraftItems() {
        let persistence = InMemoryPersistenceController()
        let store = GameStateStore(persistence: persistence)

        let today = store.days.last?.date ?? Date()
        XCTAssertTrue(
            store.saveToday(items: [SpendItem(title: "Lunch", amountMinor: 100, category: "Foodie")], now: today)
        )

        store.updateDraftItems([SpendItem(title: "Coffee", amountMinor: 50, category: "Foodie")], for: store.todayEntry?.dayIndex ?? 1)
        store.renameCustomCategory("Foodie", to: "Cafe")

        XCTAssertTrue(store.customCategories.contains("Cafe"))
        XCTAssertFalse(store.customCategories.contains("Foodie"))
        XCTAssertEqual(store.days.first?.items.first?.category, "Cafe")
        XCTAssertEqual(store.draftItems(for: store.todayEntry?.dayIndex ?? 1).first?.category, "Cafe")
    }
}

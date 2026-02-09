import XCTest
@testable import DreamSpend

final class RestartGameTests: XCTestCase {
    @MainActor
    func testRestartKeepsSettingsAndUsesConfiguredStartAmount() {
        let persistence = InMemoryPersistenceController()
        let store = GameStateStore(persistence: persistence)

        store.updateStartAmount(12_345, language: .en)
        store.updateMaxAmount(99_999, language: .en)
        store.updateFX(source: "USD", target: "EUR", rate: Decimal(string: "0.91") ?? 0.91)
        store.updateReminder(hour: 9, minute: 45, enabled: true)
        store.updateMaxBehavior(.ceiling)
        store.updateLanguage(.en)

        store.restartGame()

        XCTAssertEqual(store.settings.languageCode, .en)
        XCTAssertEqual(store.settings.startAmountMinor(for: .en), 12_345)
        XCTAssertEqual(store.settings.maxAmountMinor(for: .en), 99_999)
        XCTAssertEqual(store.settings.maxBehavior, .ceiling)
        XCTAssertEqual(store.settings.reminderHour, 9)
        XCTAssertEqual(store.settings.reminderMinute, 45)
        XCTAssertTrue(store.settings.notificationsEnabled)

        XCTAssertEqual(store.todayEntry?.dailyLimitMinor, 12_345)
        XCTAssertEqual(store.nextDayAmountMinor, min(12_345 * 2, 99_999))
    }
}

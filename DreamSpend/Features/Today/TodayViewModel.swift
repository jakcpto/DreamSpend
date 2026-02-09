import Foundation

@MainActor
final class TodayViewModel {
    let store: GameStateStore

    init(store: GameStateStore) {
        self.store = store
        store.ensureTodayEntry()
    }

    var dayLabel: String {
        L10n.day(store.todayEntry?.dayIndex ?? 1, store.settings.languageCode)
    }

    var amountLabel: String {
        guard let today = store.todayEntry else { return "-" }
        let locale = store.settings.languageCode.localeIdentifier
        return CurrencyFormatter.format(minor: today.dailyLimitMinor, currencyCode: today.currencyCode, localeIdentifier: locale)
    }

    var progressToMax: Double {
        guard let today = store.todayEntry else { return 0 }
        let max = max(store.settings.maxAmountMinor(for: store.settings.languageCode), 1)
        return min(Double(today.dailyLimitMinor) / Double(max), 1)
    }

    var isDayFilled: Bool {
        store.todayEntry?.status == .filled
    }

    var todayItems: [SpendItem] {
        store.todayEntry?.items ?? []
    }
}

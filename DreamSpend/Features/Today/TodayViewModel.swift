import Foundation

@MainActor
final class TodayViewModel {
    let store: GameStateStore

    init(store: GameStateStore) {
        self.store = store
    }

    var availableDays: [DayEntry] {
        let today = Calendar.current.startOfDay(for: Date())
        return store.days
            .filter { $0.dailyLimitMinor > 0 && $0.date <= today }
            .sorted { $0.date < $1.date }
    }

    var todayDayIndex: Int? {
        store.todayEntry?.dayIndex
    }

    func day(for dayIndex: Int?) -> DayEntry? {
        guard let dayIndex else { return store.todayEntry }
        return store.days.first(where: { $0.dayIndex == dayIndex })
    }

    func monthAndYear(for day: DayEntry?) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: store.settings.languageCode.localeIdentifier)
        formatter.dateFormat = "LLLL yyyy"
        let title = formatter.string(from: day?.date ?? Date())
        guard let first = title.first else { return title }
        return first.uppercased() + title.dropFirst()
    }

    func amountLabel(for day: DayEntry) -> String {
        let locale = store.settings.languageCode.localeIdentifier
        return CurrencyFormatter.format(minor: day.dailyLimitMinor, currencyCode: day.currencyCode, localeIdentifier: locale)
    }

    func spends(for day: DayEntry?) -> [SpendItem] {
        day?.items ?? []
    }

    func isFilled(day: DayEntry?) -> Bool {
        day?.status == .filled
    }
}

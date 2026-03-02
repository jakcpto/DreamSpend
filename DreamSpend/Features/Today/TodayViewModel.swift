import Foundation

@MainActor
final class TodayViewModel {
    struct MonthSection: Identifiable {
        let monthStart: Date
        let days: [DayEntry]

        var id: Date { monthStart }
    }

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

    var monthSections: [MonthSection] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: availableDays) { day in
            calendar.date(from: calendar.dateComponents([.year, .month], from: day.date)) ?? day.date
        }

        return grouped.keys.sorted().map { monthStart in
            let days = (grouped[monthStart] ?? []).sorted { $0.date < $1.date }
            return MonthSection(monthStart: monthStart, days: days)
        }
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

    func monthLabel(for monthStart: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: store.settings.languageCode.localeIdentifier)
        formatter.dateFormat = "LLL"
        let title = formatter.string(from: monthStart)
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

    func fillProgress(for day: DayEntry) -> Double {
        guard day.status == .filled else { return 0 }
        guard day.dailyLimitMinor > 0 else { return 0 }
        let progress = Double(day.totalSpentMinor) / Double(day.dailyLimitMinor)
        return min(max(progress, 0), 1)
    }

    func isNearlyFull(day: DayEntry) -> Bool {
        fillProgress(for: day) >= 0.95
    }

    func isOverLimit(day: DayEntry) -> Bool {
        day.status == .filled && day.totalSpentMinor > day.dailyLimitMinor
    }
}

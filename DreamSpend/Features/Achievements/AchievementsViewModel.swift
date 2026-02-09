import Foundation
import Combine

@MainActor
final class AchievementsViewModel: ObservableObject {
    let store: GameStateStore
    private var cancellables: Set<AnyCancellable> = []

    init(store: GameStateStore) {
        self.store = store

        store.objectWillChange
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    var achievements: [Achievement] {
        store.achievements
    }

    struct CategorySlice: Identifiable {
        let id: String
        let name: String
        let totalMinor: Int64
        let share: Double
    }

    var categorySlices: [CategorySlice] {
        let language = store.settings.languageCode
        let fallback = L10n.text("achievements.analytics.uncategorized", language)
        let relevantDays = filledDaysRange
        guard !relevantDays.isEmpty else { return [] }

        var totals: [String: Int64] = [:]
        for day in relevantDays {
            for item in day.items {
                let rawName = item.category?.trimmingCharacters(in: .whitespacesAndNewlines)
                let category = (rawName?.isEmpty == false ? rawName ?? fallback : fallback)
                totals[category, default: 0] += item.amountMinor
            }
        }

        let grandTotal = totals.values.reduce(0, +)
        guard grandTotal > 0 else { return [] }

        return totals
            .map { entry in
                CategorySlice(
                    id: entry.key,
                    name: entry.key,
                    totalMinor: entry.value,
                    share: Double(entry.value) / Double(grandTotal)
                )
            }
            .sorted { $0.totalMinor > $1.totalMinor }
    }

    var analyticsDateRangeText: String? {
        guard let first = filledDaysRange.first?.date,
              let last = filledDaysRange.last?.date else {
            return nil
        }

        let locale = Locale(identifier: store.settings.languageCode.localeIdentifier)
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return "\(formatter.string(from: first)) - \(formatter.string(from: last))"
    }

    func categoryAmountText(_ slice: CategorySlice) -> String {
        let locale = store.settings.languageCode.localeIdentifier
        let currencyCode = store.settings.currencyCode(for: store.settings.languageCode)
        return CurrencyFormatter.format(minor: slice.totalMinor, currencyCode: currencyCode, localeIdentifier: locale)
    }

    func categoryPercentText(_ slice: CategorySlice) -> String {
        String(format: "%.1f%%", slice.share * 100)
    }

    func colorIndex(for slice: CategorySlice) -> Int {
        Int(UInt(bitPattern: slice.id.hashValue) % 12)
    }

    private var filledDaysRange: [DayEntry] {
        let filled = store.days.filter { $0.status == .filled }
        guard let firstDate = filled.map(\.date).min(),
              let lastDate = filled.map(\.date).max() else {
            return []
        }
        return store.days
            .filter { $0.date >= firstDate && $0.date <= lastDate && $0.status == .filled }
            .sorted { $0.date < $1.date }
    }
}

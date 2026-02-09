import Foundation
import Combine

@MainActor
final class GameStateStore: ObservableObject {
    private let persistence: PersistenceControllerProtocol
    private let calendarService: CalendarService
    private let fxService: ApproxFXService
    private let streakService: StreakService
    private let achievementService: AchievementService
    private let languageService: LanguageService

    @Published var settings: Settings
    @Published var days: [DayEntry]
    @Published var achievements: [Achievement]
    @Published var currentStreak: Int
    @Published var nextDayAmountMinor: Int64
    @Published var nextDayCurrencyCode: String
    @Published var pendingConversionRateUsed: Decimal?
    @Published var isPausedAfterMaximum: Bool
    @Published var showCelebration: Bool
    @Published var draftItemsByDayIndex: [Int: [SpendItem]]
    @Published var customCategories: [String]

    static let defaultCategoriesByLanguage: [SupportedLanguage: [String]] = [
        .ru: ["Еда", "Транспорт", "Дом", "Одежда", "Развлечения", "Подарки", "Здоровье", "Путешествия"],
        .en: ["Food", "Transport", "Home", "Clothes", "Entertainment", "Gifts", "Health", "Travel"],
        .de: ["Essen", "Transport", "Haushalt", "Kleidung", "Unterhaltung", "Geschenke", "Gesundheit", "Reisen"]
    ]

    init(
        persistence: PersistenceControllerProtocol = PersistenceController(),
        calendarService: CalendarService = CalendarService(),
        fxService: ApproxFXService = ApproxFXService(),
        streakService: StreakService = StreakService(),
        achievementService: AchievementService = AchievementService(),
        languageService: LanguageService = LanguageService()
    ) {
        self.persistence = persistence
        self.calendarService = calendarService
        self.fxService = fxService
        self.streakService = streakService
        self.achievementService = achievementService
        self.languageService = languageService

        if let snapshot = persistence.loadSnapshot() {
            self.settings = snapshot.settings
            self.days = snapshot.days.sorted { $0.dayIndex < $1.dayIndex }
            self.achievements = snapshot.achievements
            self.currentStreak = snapshot.currentStreak
            self.nextDayAmountMinor = snapshot.nextDayAmountMinor
            self.nextDayCurrencyCode = snapshot.nextDayCurrencyCode
            self.pendingConversionRateUsed = snapshot.pendingConversionRateUsed
            self.isPausedAfterMaximum = snapshot.isPausedAfterMaximum
            self.draftItemsByDayIndex = Dictionary(uniqueKeysWithValues: (snapshot.draftBuckets ?? []).map { ($0.dayIndex, $0.items) })
            self.customCategories = snapshot.customCategories ?? []
        } else {
            let defaultSettings = Settings.default
            self.settings = defaultSettings
            self.days = []
            self.achievements = achievementService.bootstrap()
            self.currentStreak = 0
            self.nextDayAmountMinor = defaultSettings.startAmountMinor(for: defaultSettings.languageCode)
            self.nextDayCurrencyCode = defaultSettings.currencyCode(for: defaultSettings.languageCode)
            self.pendingConversionRateUsed = nil
            self.isPausedAfterMaximum = false
            self.draftItemsByDayIndex = [:]
            self.customCategories = []
        }

        self.showCelebration = false
        if settings.maxBehavior == .celebrationAndStop {
            settings.maxBehavior = .resetAndRestart
        }
        ensureTodayEntry()
    }

    var todayEntry: DayEntry? {
        let today = calendarService.today()
        return days.last(where: { calendarService.isSameLocalDay($0.date, today) })
    }

    var categorySuggestions: [String] {
        Self.uniqueCategories(defaultCategories + customCategories)
    }

    var defaultCategories: [String] {
        Self.defaultCategoriesByLanguage[settings.languageCode] ?? Self.defaultCategoriesByLanguage[.en] ?? []
    }

    func ensureTodayEntry(now: Date = Date()) {
        guard !isPausedAfterMaximum else { return }

        let today = calendarService.startOfDay(now)
        days.sort { $0.dayIndex < $1.dayIndex }

        if days.isEmpty {
            addDay(for: today, status: .open)
            persist()
            return
        }

        for index in days.indices where days[index].status == .open && days[index].date < today {
            days[index].status = .missed
        }

        guard let lastDay = days.last else {
            persist()
            return
        }

        let distance = calendarService.dayDistance(from: lastDay.date, to: today)
        if distance > 0 {
            for step in 1...distance {
                let date = calendarService.addDays(step, to: lastDay.date)
                let status: DayStatus = calendarService.isSameLocalDay(date, today) ? .open : .missed
                addDay(for: date, status: status)
            }
        }

        if streakService.shouldResetAfterMissed(days: days) {
            currentStreak = 0
        }

        cleanupDrafts()
        persist()
    }

    func saveToday(items: [SpendItem], now: Date = Date()) -> Bool {
        ensureTodayEntry(now: now)
        let today = calendarService.startOfDay(now)

        guard let index = days.firstIndex(where: { calendarService.isSameLocalDay($0.date, today) }) else {
            return false
        }

        let total = items.reduce(0) { $0 + $1.amountMinor }
        let allowed = maxAllowedTotal(for: days[index].dailyLimitMinor)
        guard total <= allowed else {
            return false
        }

        let wasFilledBeforeSave = days[index].status == .filled
        days[index].items = items
        days[index].status = .filled
        draftItemsByDayIndex.removeValue(forKey: days[index].dayIndex)
        mergeCategories(from: items)
        if !wasFilledBeforeSave {
            currentStreak = streakService.nextStreak(current: currentStreak, didFillToday: true)
        }

        let maxForCurrency = maximumAmount(for: days[index].currencyCode)
        let reachedMaximum = days[index].dailyLimitMinor >= maxForCurrency
        achievements = achievementService.evaluate(
            achievements: achievements,
            streak: currentStreak,
            day: days[index],
            reachedMaximum: reachedMaximum,
            now: now
        )

        if reachedMaximum {
            showCelebration = true
            if settings.maxBehavior == .celebrationAndStop {
                isPausedAfterMaximum = true
            }
        }

        persist()
        return true
    }

    func saveSpends(items: [SpendItem], for dayIndex: Int, now: Date = Date()) -> Bool {
        ensureTodayEntry(now: now)

        guard let index = days.firstIndex(where: { $0.dayIndex == dayIndex }) else {
            return false
        }

        let total = items.reduce(0) { $0 + $1.amountMinor }
        let allowed = maxAllowedTotal(for: days[index].dailyLimitMinor)
        guard total <= allowed else {
            return false
        }

        if let todayIndex = todayEntry?.dayIndex, todayIndex == dayIndex {
            return saveToday(items: items, now: now)
        }

        days[index].items = items
        days[index].status = items.isEmpty ? .missed : .filled
        draftItemsByDayIndex.removeValue(forKey: days[index].dayIndex)
        mergeCategories(from: items)
        persist()
        return true
    }

    func maxAllowedTotal(for limitMinor: Int64) -> Int64 {
        (limitMinor * 105) / 100
    }

    func draftItems(for dayIndex: Int) -> [SpendItem] {
        draftItemsByDayIndex[dayIndex] ?? []
    }

    func updateDraftItems(_ items: [SpendItem], for dayIndex: Int) {
        if items.isEmpty {
            draftItemsByDayIndex.removeValue(forKey: dayIndex)
        } else {
            draftItemsByDayIndex[dayIndex] = items
        }
        persist()
    }

    func addCustomCategory(_ category: String) {
        let value = normalizedCategory(category)
        guard !value.isEmpty else { return }
        customCategories = Self.uniqueCategories(customCategories + [value])
        persist()
    }

    func removeCustomCategory(_ category: String) {
        let value = normalizedCategory(category)
        guard !value.isEmpty else { return }
        customCategories.removeAll { $0.caseInsensitiveCompare(value) == .orderedSame }
        persist()
    }

    func dismissCelebration() {
        showCelebration = false
    }

    func restartGame() {
        days = []
        currentStreak = 0
        isPausedAfterMaximum = false
        showCelebration = false
        draftItemsByDayIndex = [:]
        let lang = settings.languageCode
        nextDayAmountMinor = settings.startAmountMinor(for: lang)
        nextDayCurrencyCode = settings.currencyCode(for: lang)
        pendingConversionRateUsed = nil
        achievements = achievementService.bootstrap()
        ensureTodayEntry()
        persist()
    }

    func updateLanguage(_ newLanguage: SupportedLanguage) {
        let oldLanguage = settings.languageCode
        guard oldLanguage != newLanguage else { return }

        let result = languageService.switchLanguage(
            amountMinor: nextDayAmountMinor,
            from: oldLanguage,
            to: newLanguage,
            settings: settings
        )

        settings.languageCode = newLanguage
        nextDayAmountMinor = result.newAmountMinor
        nextDayCurrencyCode = result.newCurrencyCode
        pendingConversionRateUsed = result.conversionRateUsed
        persist()
    }

    func updateStartAmount(_ value: Int64, language: SupportedLanguage) {
        settings.startAmountMinorByLanguage[language] = max(value, 1)
        persist()
    }

    func updateMaxAmount(_ value: Int64, language: SupportedLanguage) {
        settings.maxAmountMinorByLanguage[language] = max(value, 1)
        persist()
    }

    func updateMaxBehavior(_ behavior: MaxBehavior) {
        settings.maxBehavior = behavior
        persist()
    }

    func updateReminder(hour: Int, minute: Int, enabled: Bool) {
        settings.reminderHour = min(max(hour, 0), 23)
        settings.reminderMinute = min(max(minute, 0), 59)
        settings.notificationsEnabled = enabled
        persist()
    }

    func updateFX(source: String, target: String, rate: Decimal) {
        settings.approxFxTable = fxService.updatedTable(
            from: source,
            to: target,
            rate: rate,
            table: settings.approxFxTable
        )
        persist()
    }

    private func addDay(for date: Date, status: DayStatus) {
        let nextIndex = (days.last?.dayIndex ?? 0) + 1
        let day = DayEntry(
            dayIndex: nextIndex,
            date: date,
            currencyCode: nextDayCurrencyCode,
            dailyLimitMinor: nextDayAmountMinor,
            status: status,
            conversionRateUsed: pendingConversionRateUsed,
            items: []
        )

        days.append(day)
        pendingConversionRateUsed = nil
        nextDayAmountMinor = projectedAmount(after: day.dailyLimitMinor, currencyCode: day.currencyCode)
    }

    private func mergeCategories(from items: [SpendItem]) {
        let extracted = items.compactMap { $0.category }.map(normalizedCategory).filter { !$0.isEmpty }
        customCategories = Self.uniqueCategories(customCategories + extracted)
    }

    private func normalizedCategory(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func uniqueCategories(_ categories: [String]) -> [String] {
        var set = Set<String>()
        var result: [String] = []
        for category in categories {
            let trimmed = category.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let key = trimmed.lowercased()
            if set.insert(key).inserted {
                result.append(trimmed)
            }
        }
        return result
    }

    private func cleanupDrafts() {
        let openIndices = Set(days.filter { $0.status == .open }.map { $0.dayIndex })
        draftItemsByDayIndex = draftItemsByDayIndex.filter { openIndices.contains($0.key) }
    }

    private func projectedAmount(after dailyLimitMinor: Int64, currencyCode: String) -> Int64 {
        let maxAmount = maximumAmount(for: currencyCode)
        let startAmount = startAmount(for: currencyCode)

        if dailyLimitMinor < maxAmount {
            return min(dailyLimitMinor * 2, maxAmount)
        }

        switch settings.maxBehavior {
        case .celebrationAndStop:
            return maxAmount
        case .resetAndRestart:
            return startAmount
        case .ceiling:
            return maxAmount
        }
    }

    private func maximumAmount(for currencyCode: String) -> Int64 {
        settings.maxAmountMinorByLanguage.first(where: { settings.currencyCode(for: $0.key) == currencyCode })?.value
        ?? settings.maxAmountMinor(for: settings.languageCode)
    }

    private func startAmount(for currencyCode: String) -> Int64 {
        settings.startAmountMinorByLanguage.first(where: { settings.currencyCode(for: $0.key) == currencyCode })?.value
        ?? settings.startAmountMinor(for: settings.languageCode)
    }

    private func persist() {
        persistence.saveSnapshot(
            GameSnapshot(
                settings: settings,
                days: days,
                achievements: achievements,
                currentStreak: currentStreak,
                nextDayAmountMinor: nextDayAmountMinor,
                nextDayCurrencyCode: nextDayCurrencyCode,
                pendingConversionRateUsed: pendingConversionRateUsed,
                isPausedAfterMaximum: isPausedAfterMaximum,
                draftBuckets: draftItemsByDayIndex.map { DraftBucket(dayIndex: $0.key, items: $0.value) },
                customCategories: customCategories
            )
        )
    }
}

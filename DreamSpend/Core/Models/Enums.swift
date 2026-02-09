import Foundation

enum DayStatus: String, Codable, CaseIterable, Sendable {
    case open
    case filled
    case missed
}

enum MaxBehavior: String, Codable, CaseIterable, Sendable {
    case celebrationAndStop
    case resetAndRestart
    case ceiling
}

enum SupportedLanguage: String, Codable, CaseIterable, Identifiable, Sendable {
    case ru
    case en
    case de

    var id: String { rawValue }

    var localeIdentifier: String {
        switch self {
        case .ru: return "ru_RU"
        case .en: return "en_US"
        case .de: return "de_DE"
        }
    }

    var currencyCode: String {
        switch self {
        case .ru: return "RUB"
        case .en: return "USD"
        case .de: return "EUR"
        }
    }

    var uiLabel: String {
        switch self {
        case .ru: return "RU"
        case .en: return "EN"
        case .de: return "DE"
        }
    }

    static var systemDefault: SupportedLanguage {
        let preferred = Locale.preferredLanguages.first ?? "en"
        if preferred.lowercased().hasPrefix("ru") { return .ru }
        if preferred.lowercased().hasPrefix("de") { return .de }
        return .en
    }
}

enum AchievementKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case streak3
    case streak7
    case streak14
    case streak30
    case perfectFill
    case reachedMaximum

    var id: String { rawValue }

    var requiredStreak: Int? {
        switch self {
        case .streak3: return 3
        case .streak7: return 7
        case .streak14: return 14
        case .streak30: return 30
        default: return nil
        }
    }
}

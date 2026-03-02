import Foundation
import SwiftUI

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

enum CategoryPalette {
    static let tokens: [String] = [
        "blue",
        "green",
        "orange",
        "pink",
        "teal",
        "indigo",
        "yellow",
        "mint",
        "cyan",
        "red",
        "brown",
        "gray"
    ]

    static func color(for token: String?) -> Color {
        switch token {
        case "green": return .green
        case "orange": return .orange
        case "pink": return .pink
        case "teal": return .teal
        case "indigo": return .indigo
        case "yellow": return .yellow
        case "mint": return .mint
        case "cyan": return .cyan
        case "red": return .red
        case "brown": return .brown
        case "gray": return .gray
        default: return .blue
        }
    }

    static func nextToken(after token: String?) -> String {
        guard let token, let index = tokens.firstIndex(of: token) else {
            return tokens.first ?? "blue"
        }
        return tokens[(index + 1) % tokens.count]
    }

    static func fallbackToken(for category: String) -> String {
        let source = category.lowercased().unicodeScalars.reduce(0) { partialResult, scalar in
            partialResult + Int(scalar.value)
        }
        return tokens[source % tokens.count]
    }
}

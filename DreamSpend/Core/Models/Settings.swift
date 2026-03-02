import Foundation

enum AppIconOption: String, Codable, CaseIterable, Sendable, Identifiable {
    case oldMoney
    case coin
    case game

    var id: String { rawValue }

    var alternateIconName: String? {
        switch self {
        case .oldMoney:
            return nil
        case .coin:
            return "AppIconCoin"
        case .game:
            return "AppIconGame"
        }
    }

    func title(for language: SupportedLanguage) -> String {
        switch (self, language) {
        case (.oldMoney, .ru):
            return "Old Money"
        case (.oldMoney, .en):
            return "Old Money"
        case (.oldMoney, .de):
            return "Old Money"
        case (.coin, .ru):
            return "Coin"
        case (.coin, .en):
            return "Coin"
        case (.coin, .de):
            return "Coin"
        case (.game, .ru):
            return "Game"
        case (.game, .en):
            return "Game"
        case (.game, .de):
            return "Game"
        }
    }
}

struct Settings: Codable, Sendable {
    var languageCode: SupportedLanguage
    var startAmountMinorByLanguage: [SupportedLanguage: Int64]
    var maxAmountMinorByLanguage: [SupportedLanguage: Int64]
    var currencyByLanguage: [SupportedLanguage: String]
    var approxFxTable: [String: Decimal]
    var reminderHour: Int
    var reminderMinute: Int
    var maxBehavior: MaxBehavior
    var notificationsEnabled: Bool
    var appIcon: AppIconOption

    private enum CodingKeys: String, CodingKey {
        case languageCode
        case startAmountMinorByLanguage
        case maxAmountMinorByLanguage
        case currencyByLanguage
        case approxFxTable
        case reminderHour
        case reminderMinute
        case maxBehavior
        case notificationsEnabled
        case appIcon
    }

    static var `default`: Settings {
        let language = SupportedLanguage.systemDefault
        return Settings(
            languageCode: language,
            startAmountMinorByLanguage: [
                .en: 5_00,
                .de: 4_60,
                .ru: 500_00
            ],
            maxAmountMinorByLanguage: [
                .en: 1_000_000_00,
                .de: 920_000_00,
                .ru: 100_000_000_00
            ],
            currencyByLanguage: [
                .ru: "RUB",
                .en: "USD",
                .de: "EUR"
            ],
            approxFxTable: [
                "USD->EUR": Decimal(string: "0.92")!,
                "EUR->USD": Decimal(string: "1.0869565")!,
                "USD->RUB": Decimal(string: "100")!,
                "RUB->USD": Decimal(string: "0.01")!,
                "EUR->RUB": Decimal(string: "108")!,
                "RUB->EUR": Decimal(string: "0.0092593")!
            ],
            reminderHour: 14,
            reminderMinute: 15,
            maxBehavior: .resetAndRestart,
            notificationsEnabled: false,
            appIcon: .oldMoney
        )
    }

    func currencyCode(for language: SupportedLanguage) -> String {
        currencyByLanguage[language] ?? language.currencyCode
    }

    func startAmountMinor(for language: SupportedLanguage) -> Int64 {
        startAmountMinorByLanguage[language] ?? 100
    }

    func maxAmountMinor(for language: SupportedLanguage) -> Int64 {
        maxAmountMinorByLanguage[language] ?? 10_000
    }

    init(
        languageCode: SupportedLanguage,
        startAmountMinorByLanguage: [SupportedLanguage: Int64],
        maxAmountMinorByLanguage: [SupportedLanguage: Int64],
        currencyByLanguage: [SupportedLanguage: String],
        approxFxTable: [String: Decimal],
        reminderHour: Int,
        reminderMinute: Int,
        maxBehavior: MaxBehavior,
        notificationsEnabled: Bool,
        appIcon: AppIconOption
    ) {
        self.languageCode = languageCode
        self.startAmountMinorByLanguage = startAmountMinorByLanguage
        self.maxAmountMinorByLanguage = maxAmountMinorByLanguage
        self.currencyByLanguage = currencyByLanguage
        self.approxFxTable = approxFxTable
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.maxBehavior = maxBehavior
        self.notificationsEnabled = notificationsEnabled
        self.appIcon = appIcon
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        languageCode = try container.decode(SupportedLanguage.self, forKey: .languageCode)
        startAmountMinorByLanguage = try container.decode([SupportedLanguage: Int64].self, forKey: .startAmountMinorByLanguage)
        maxAmountMinorByLanguage = try container.decode([SupportedLanguage: Int64].self, forKey: .maxAmountMinorByLanguage)
        currencyByLanguage = try container.decode([SupportedLanguage: String].self, forKey: .currencyByLanguage)
        approxFxTable = try container.decode([String: Decimal].self, forKey: .approxFxTable)
        reminderHour = try container.decode(Int.self, forKey: .reminderHour)
        reminderMinute = try container.decode(Int.self, forKey: .reminderMinute)
        maxBehavior = try container.decode(MaxBehavior.self, forKey: .maxBehavior)
        notificationsEnabled = try container.decode(Bool.self, forKey: .notificationsEnabled)
        appIcon = try container.decodeIfPresent(AppIconOption.self, forKey: .appIcon) ?? .oldMoney
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(languageCode, forKey: .languageCode)
        try container.encode(startAmountMinorByLanguage, forKey: .startAmountMinorByLanguage)
        try container.encode(maxAmountMinorByLanguage, forKey: .maxAmountMinorByLanguage)
        try container.encode(currencyByLanguage, forKey: .currencyByLanguage)
        try container.encode(approxFxTable, forKey: .approxFxTable)
        try container.encode(reminderHour, forKey: .reminderHour)
        try container.encode(reminderMinute, forKey: .reminderMinute)
        try container.encode(maxBehavior, forKey: .maxBehavior)
        try container.encode(notificationsEnabled, forKey: .notificationsEnabled)
        try container.encode(appIcon, forKey: .appIcon)
    }
}

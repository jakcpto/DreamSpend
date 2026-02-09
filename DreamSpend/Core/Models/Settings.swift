import Foundation

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
            notificationsEnabled: false
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
}

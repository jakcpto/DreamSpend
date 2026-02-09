import Foundation

struct LanguageSwitchResult {
    let newAmountMinor: Int64
    let newCurrencyCode: String
    let conversionRateUsed: Decimal
}

struct LanguageService {
    private let fxService = ApproxFXService()

    func switchLanguage(
        amountMinor: Int64,
        from oldLanguage: SupportedLanguage,
        to newLanguage: SupportedLanguage,
        settings: Settings
    ) -> LanguageSwitchResult {
        let oldCurrency = settings.currencyCode(for: oldLanguage)
        let newCurrency = settings.currencyCode(for: newLanguage)
        let conversion = fxService.convert(
            amountMinor: amountMinor,
            from: oldCurrency,
            to: newCurrency,
            table: settings.approxFxTable
        )

        return LanguageSwitchResult(
            newAmountMinor: max(conversion.convertedMinor, 1),
            newCurrencyCode: newCurrency,
            conversionRateUsed: conversion.rateUsed
        )
    }
}

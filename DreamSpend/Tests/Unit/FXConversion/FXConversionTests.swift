import XCTest
@testable import DreamSpend

final class FXConversionTests: XCTestCase {
    func testLanguageSwitchUsesApproxRate() {
        var settings = Settings.default
        settings.approxFxTable = ["USD->EUR": Decimal(string: "0.9")!]

        let service = LanguageService()
        let result = service.switchLanguage(
            amountMinor: 10_000,
            from: .en,
            to: .de,
            settings: settings
        )

        XCTAssertEqual(result.newCurrencyCode, "EUR")
        XCTAssertEqual(result.newAmountMinor, 9_000)
        XCTAssertEqual(result.conversionRateUsed, Decimal(string: "0.9")!)
    }
}

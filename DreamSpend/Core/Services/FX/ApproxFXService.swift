import Foundation

struct ApproxFXService {
    func rate(from sourceCurrency: String, to targetCurrency: String, table: [String: Decimal]) -> Decimal {
        if sourceCurrency == targetCurrency { return 1 }
        let key = "\(sourceCurrency)->\(targetCurrency)"
        return table[key] ?? 1
    }

    func convert(
        amountMinor: Int64,
        from sourceCurrency: String,
        to targetCurrency: String,
        table: [String: Decimal]
    ) -> (convertedMinor: Int64, rateUsed: Decimal) {
        let rate = rate(from: sourceCurrency, to: targetCurrency, table: table)
        let raw = (Decimal(amountMinor) * rate) as NSDecimalNumber
        let rounded = raw.rounding(accordingToBehavior: Self.bankersRounding)
        return (rounded.int64Value, rate)
    }

    func updatedTable(
        from sourceCurrency: String,
        to targetCurrency: String,
        rate: Decimal,
        table: [String: Decimal]
    ) -> [String: Decimal] {
        var copy = table
        copy["\(sourceCurrency)->\(targetCurrency)"] = rate
        if rate != 0 {
            copy["\(targetCurrency)->\(sourceCurrency)"] = 1 / rate
        }
        return copy
    }

    static let bankersRounding: NSDecimalNumberHandler = NSDecimalNumberHandler(
        roundingMode: .bankers,
        scale: 0,
        raiseOnExactness: false,
        raiseOnOverflow: false,
        raiseOnUnderflow: false,
        raiseOnDivideByZero: false
    )
}

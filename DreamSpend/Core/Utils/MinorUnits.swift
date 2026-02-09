import Foundation

enum MinorUnits {
    static func fromMajor(_ value: Decimal, currencyCode: String) -> Int64 {
        let factor = pow10(Self.fractionDigits(for: currencyCode))
        let raw = (value * Decimal(factor)) as NSDecimalNumber
        return raw.rounding(accordingToBehavior: bankersRounding).int64Value
    }

    static func toMajor(_ value: Int64, currencyCode: String) -> Decimal {
        let factor = Decimal(pow10(Self.fractionDigits(for: currencyCode)))
        return Decimal(value) / factor
    }

    static func fractionDigits(for currencyCode: String) -> Int {
        switch currencyCode {
        case "JPY": return 0
        default: return 2
        }
    }

    private static func pow10(_ power: Int) -> Int {
        Int(pow(10.0, Double(power)))
    }

    private static let bankersRounding = NSDecimalNumberHandler(
        roundingMode: .bankers,
        scale: 0,
        raiseOnExactness: false,
        raiseOnOverflow: false,
        raiseOnUnderflow: false,
        raiseOnDivideByZero: false
    )
}

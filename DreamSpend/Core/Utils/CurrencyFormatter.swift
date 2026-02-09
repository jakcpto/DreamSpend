import Foundation

enum CurrencyFormatter {
    static func format(minor: Int64, currencyCode: String, localeIdentifier: String) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = Locale(identifier: localeIdentifier)
        numberFormatter.currencyCode = currencyCode
        let major = MinorUnits.toMajor(minor, currencyCode: currencyCode) as NSDecimalNumber
        return numberFormatter.string(from: major) ?? "\(major) \(currencyCode)"
    }
}

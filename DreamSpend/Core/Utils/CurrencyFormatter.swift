import Foundation

enum CurrencyFormatter {
    enum Style {
        case standard
        case compactNoFraction
    }

    static func format(
        minor: Int64,
        currencyCode: String,
        localeIdentifier: String,
        style: Style = .standard
    ) -> String {
        let locale = Locale(identifier: localeIdentifier)
        let major = MinorUnits.toMajor(minor, currencyCode: currencyCode) as NSDecimalNumber

        switch style {
        case .standard:
            return standardFormatter(currencyCode: currencyCode, locale: locale).string(from: major) ?? "\(major) \(currencyCode)"
        case .compactNoFraction:
            return compactNoFractionString(major: major, currencyCode: currencyCode, locale: locale)
        }
    }

    private static func standardFormatter(currencyCode: String, locale: Locale) -> NumberFormatter {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = locale
        numberFormatter.currencyCode = currencyCode
        return numberFormatter
    }

    private static func compactNoFractionString(major: NSDecimalNumber, currencyCode: String, locale: Locale) -> String {
        let absoluteValue = abs(major.doubleValue)
        let standard = standardFormatter(currencyCode: currencyCode, locale: locale)
        standard.minimumFractionDigits = 0
        standard.maximumFractionDigits = 0

        guard absoluteValue >= 1_000_000 else {
            return standard.string(from: major) ?? "\(major) \(currencyCode)"
        }

        let compactValue: Double
        let suffix: String

        switch absoluteValue {
        case 1_000_000_000...:
            compactValue = major.doubleValue / 1_000_000_000
            suffix = compactSuffix(for: locale, kind: .billion)
        case 1_000_000...:
            compactValue = major.doubleValue / 1_000_000
            suffix = compactSuffix(for: locale, kind: .million)
        default:
            compactValue = major.doubleValue / 1_000_000
            suffix = compactSuffix(for: locale, kind: .million)
        }

        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.locale = locale
        numberFormatter.minimumFractionDigits = 0
        numberFormatter.maximumFractionDigits = 0

        let compactNumber = numberFormatter.string(from: NSNumber(value: compactValue.rounded())) ?? "\(Int(compactValue.rounded()))"
        let currencySymbol = standard.currencySymbol ?? currencyCode
        let formattedValue = "\(compactNumber)\(suffix)"

        if standard.positiveFormat.hasPrefix("¤") {
            return "\(currencySymbol)\(formattedValue)"
        }

        return "\(formattedValue) \(currencySymbol)"
    }

    private static func compactSuffix(for locale: Locale, kind: CompactKind) -> String {
        let languageCode = locale.language.languageCode?.identifier ?? locale.identifier

        switch languageCode {
        case "ru":
            switch kind {
            case .million: return " млн"
            case .billion: return " млрд"
            }
        case "de":
            switch kind {
            case .million: return " Mio."
            case .billion: return " Mrd."
            }
        default:
            switch kind {
            case .million: return "M"
            case .billion: return "B"
            }
        }
    }

    private enum CompactKind {
        case million
        case billion
    }
}

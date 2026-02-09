import Foundation

struct DayEntry: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var dayIndex: Int
    var date: Date
    var currencyCode: String
    var dailyLimitMinor: Int64
    var status: DayStatus
    var conversionRateUsed: Decimal?
    var items: [SpendItem]

    init(
        id: UUID = UUID(),
        dayIndex: Int,
        date: Date,
        currencyCode: String,
        dailyLimitMinor: Int64,
        status: DayStatus = .open,
        conversionRateUsed: Decimal? = nil,
        items: [SpendItem] = []
    ) {
        self.id = id
        self.dayIndex = dayIndex
        self.date = date
        self.currencyCode = currencyCode
        self.dailyLimitMinor = max(dailyLimitMinor, 0)
        self.status = status
        self.conversionRateUsed = conversionRateUsed
        self.items = items
    }

    var totalSpentMinor: Int64 {
        items.reduce(0) { $0 + $1.amountMinor }
    }

    var remainingMinor: Int64 {
        dailyLimitMinor - totalSpentMinor
    }

    var isPerfectFill: Bool {
        status == .filled && remainingMinor == 0
    }
}

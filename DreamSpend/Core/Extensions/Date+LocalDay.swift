import Foundation

extension Date {
    func startOfLocalDay(calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: self)
    }

    func addingDays(_ days: Int, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: days, to: self) ?? self
    }
}

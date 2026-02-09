import Foundation

struct SpendItem: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var title: String
    var amountMinor: Int64
    var category: String?

    init(id: UUID = UUID(), title: String, amountMinor: Int64, category: String? = nil) {
        self.id = id
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.amountMinor = max(amountMinor, 0)
        self.category = category?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

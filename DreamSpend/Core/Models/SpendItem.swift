import Foundation

struct SpendItem: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var title: String
    var amountMinor: Int64
    var category: String?
    var isDemo: Bool

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case amountMinor
        case category
        case isDemo
    }

    init(id: UUID = UUID(), title: String, amountMinor: Int64, category: String? = nil, isDemo: Bool = false) {
        self.id = id
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.amountMinor = max(amountMinor, 0)
        self.category = category?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        self.isDemo = isDemo
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title).trimmingCharacters(in: .whitespacesAndNewlines)
        amountMinor = max(try container.decode(Int64.self, forKey: .amountMinor), 0)
        category = try container.decodeIfPresent(String.self, forKey: .category)?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        isDemo = try container.decodeIfPresent(Bool.self, forKey: .isDemo) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(amountMinor, forKey: .amountMinor)
        try container.encodeIfPresent(category, forKey: .category)
        try container.encode(isDemo, forKey: .isDemo)
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

import Foundation
import Combine

@MainActor
final class DaySpendsViewModel: ObservableObject {
    let store: GameStateStore
    let targetDayIndex: Int?

    @Published private(set) var draftItems: [SpendItem] = []
    @Published private(set) var editingItemID: UUID?

    private var cancellables: Set<AnyCancellable> = []

    init(store: GameStateStore, dayIndex: Int? = nil) {
        self.store = store
        self.targetDayIndex = dayIndex

        if let dayEntry = resolvedDayEntry {
            let savedDraft = store.draftItems(for: dayEntry.dayIndex)
            if !savedDraft.isEmpty {
                self.draftItems = savedDraft
            } else {
                self.draftItems = dayEntry.items
            }
        } else {
            self.draftItems = []
        }

        $draftItems
            .dropFirst()
            .sink { [weak self] items in
                guard let self, let dayIndex = self.currentDayIndex else { return }
                self.store.updateDraftItems(items, for: dayIndex)
                _ = self.store.saveSpends(items: items, for: dayIndex)
            }
            .store(in: &cancellables)
    }

    var currentDayIndex: Int? {
        targetDayIndex ?? store.todayEntry?.dayIndex
    }

    var resolvedDayEntry: DayEntry? {
        guard let dayIndex = currentDayIndex else { return nil }
        return store.days.first(where: { $0.dayIndex == dayIndex })
    }

    var limitMinor: Int64 {
        resolvedDayEntry?.dailyLimitMinor ?? 0
    }

    var allowedTotalMinor: Int64 {
        store.maxAllowedTotal(for: limitMinor)
    }

    var currencyCode: String {
        resolvedDayEntry?.currencyCode ?? store.settings.currencyCode(for: store.settings.languageCode)
    }

    var totalMinor: Int64 {
        draftItems.reduce(0) { $0 + $1.amountMinor }
    }

    var remainingMinor: Int64 {
        limitMinor - totalMinor
    }

    var overageMinor: Int64 {
        max(totalMinor - limitMinor, 0)
    }

    var canSave: Bool {
        !draftItems.isEmpty && totalMinor <= allowedTotalMinor
    }

    var categorySuggestions: [String] {
        store.categorySuggestions
    }

    @discardableResult
    func upsertItem(id: UUID? = nil, title: String, amountMinor: Int64, category: String? = nil) -> UUID? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let normalizedCategory = category?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let normalizedCategory, !normalizedCategory.isEmpty {
            store.addCustomCategory(normalizedCategory)
        }

        let targetID = id ?? editingItemID ?? UUID()
        let item = SpendItem(id: targetID, title: trimmed, amountMinor: amountMinor, category: normalizedCategory)

        if let index = draftItems.firstIndex(where: { $0.id == targetID }) {
            draftItems[index] = item
        } else {
            draftItems.append(item)
        }

        if id == nil {
            clearEditing()
        }

        return targetID
    }

    func startEditing(item: SpendItem) {
        guard draftItems.contains(where: { $0.id == item.id }) else { return }
        editingItemID = item.id
    }

    func cancelEditing() {
        clearEditing()
    }

    func removeItem(id: UUID) {
        guard let index = draftItems.firstIndex(where: { $0.id == id }) else { return }
        draftItems.remove(at: index)
        if editingItemID == id {
            clearEditing()
        }
    }

    func removeItem(at offsets: IndexSet) {
        for index in offsets {
            if draftItems.indices.contains(index), draftItems[index].id == editingItemID {
                clearEditing()
            }
        }
        draftItems.remove(atOffsets: offsets)
    }

    func removeCategory(_ category: String) {
        store.removeCustomCategory(category)
    }

    func renameCategory(_ category: String, to newName: String) {
        store.renameCustomCategory(category, to: newName)
        if let editingItemID,
           let index = draftItems.firstIndex(where: { $0.id == editingItemID }),
           draftItems[index].category?.caseInsensitiveCompare(category) == .orderedSame {
            let item = draftItems[index]
            draftItems[index] = SpendItem(id: item.id, title: item.title, amountMinor: item.amountMinor, category: newName)
        }
    }

    func cycleCategoryColor(_ category: String) {
        store.cycleCustomCategoryColor(category)
    }

    func isDefaultCategory(_ category: String) -> Bool {
        store.defaultCategories.contains { $0.caseInsensitiveCompare(category) == .orderedSame }
    }

    func colorToken(for category: String) -> String {
        store.colorToken(for: category)
    }

    func matchingSuggestedCategory(for value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return categorySuggestions.first { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
    }

    @discardableResult
    func save() -> Bool {
        guard let dayIndex = currentDayIndex else { return false }
        return store.saveSpends(items: draftItems, for: dayIndex)
    }

    private func clearEditing() {
        editingItemID = nil
    }
}

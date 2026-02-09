import Foundation
import Combine

@MainActor
final class DaySpendsViewModel: ObservableObject {
    let store: GameStateStore

    @Published private(set) var draftItems: [SpendItem] = []
    @Published private(set) var editingItemID: UUID?

    private var editingIndex: Int?
    private var cancellables: Set<AnyCancellable> = []

    init(store: GameStateStore) {
        self.store = store

        if let today = store.todayEntry {
            let savedDraft = store.draftItems(for: today.dayIndex)
            if !savedDraft.isEmpty {
                self.draftItems = savedDraft
            } else {
                self.draftItems = today.items
            }
        } else {
            self.draftItems = []
        }

        $draftItems
            .dropFirst()
            .sink { [weak self] items in
                guard let self, let dayIndex = self.currentDayIndex else { return }
                self.store.updateDraftItems(items, for: dayIndex)
            }
            .store(in: &cancellables)
    }

    var currentDayIndex: Int? {
        store.todayEntry?.dayIndex
    }

    var limitMinor: Int64 {
        store.todayEntry?.dailyLimitMinor ?? 0
    }

    var allowedTotalMinor: Int64 {
        store.maxAllowedTotal(for: limitMinor)
    }

    var currencyCode: String {
        store.todayEntry?.currencyCode ?? store.settings.currencyCode(for: store.settings.languageCode)
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

    func upsertItem(title: String, amountMinor: Int64, category: String?) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let normalizedCategory = category?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let normalizedCategory, !normalizedCategory.isEmpty {
            store.addCustomCategory(normalizedCategory)
        }

        let item = SpendItem(title: trimmed, amountMinor: amountMinor, category: normalizedCategory)

        if let index = editingIndex, draftItems.indices.contains(index) {
            draftItems[index] = item
        } else {
            draftItems.append(item)
        }

        clearEditing()
    }

    func startEditing(item: SpendItem) {
        guard let index = draftItems.firstIndex(where: { $0.id == item.id }) else { return }
        editingIndex = index
        editingItemID = item.id
    }

    func cancelEditing() {
        clearEditing()
    }

    func removeItem(id: UUID) {
        guard let index = draftItems.firstIndex(where: { $0.id == id }) else { return }
        draftItems.remove(at: index)
        if editingIndex == index {
            clearEditing()
        }
    }

    func removeItem(at offsets: IndexSet) {
        for index in offsets {
            if index == editingIndex {
                clearEditing()
            }
        }
        draftItems.remove(atOffsets: offsets)
    }

    func removeCategory(_ category: String) {
        store.removeCustomCategory(category)
    }

    func isDefaultCategory(_ category: String) -> Bool {
        store.defaultCategories.contains { $0.caseInsensitiveCompare(category) == .orderedSame }
    }

    @discardableResult
    func save() -> Bool {
        store.saveToday(items: draftItems)
    }

    private func clearEditing() {
        editingIndex = nil
        editingItemID = nil
    }
}

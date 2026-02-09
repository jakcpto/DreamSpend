import Foundation

@MainActor
final class HistoryViewModel {
    let store: GameStateStore

    init(store: GameStateStore) {
        self.store = store
    }

    var days: [DayEntry] {
        store.days.sorted { $0.dayIndex > $1.dayIndex }
    }
}

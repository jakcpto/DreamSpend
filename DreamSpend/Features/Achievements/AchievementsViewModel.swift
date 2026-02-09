import Foundation

@MainActor
final class AchievementsViewModel {
    let store: GameStateStore

    init(store: GameStateStore) {
        self.store = store
    }

    var achievements: [Achievement] {
        store.achievements
    }
}

import Foundation

@MainActor
final class CelebrationViewModel {
    let store: GameStateStore

    init(store: GameStateStore) {
        self.store = store
    }

    func restart() {
        store.restartGame()
        store.dismissCelebration()
    }

    func close() {
        store.dismissCelebration()
    }
}

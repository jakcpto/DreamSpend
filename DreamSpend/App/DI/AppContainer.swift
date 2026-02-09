import Foundation

@MainActor
final class AppContainer {
    let gameStateStore: GameStateStore
    let appSettingsStore: AppSettingsStore
    let notificationService: NotificationService

    init() {
        let gameStore = GameStateStore()
        self.gameStateStore = gameStore
        self.appSettingsStore = AppSettingsStore(gameStore: gameStore)
        self.notificationService = NotificationService()
    }
}

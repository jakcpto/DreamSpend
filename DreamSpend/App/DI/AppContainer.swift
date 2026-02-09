import Foundation

@MainActor
final class AppContainer {
    let gameStateStore: GameStateStore
    let appSettingsStore: AppSettingsStore
    let notificationService: NotificationService
    let todayViewModel: TodayViewModel
    let historyViewModel: HistoryViewModel
    let achievementsViewModel: AchievementsViewModel
    let settingsViewModel: SettingsViewModel

    init() {
        let gameStore = GameStateStore()
        let settingsStore = AppSettingsStore(gameStore: gameStore)
        let notificationService = NotificationService()

        self.gameStateStore = gameStore
        self.appSettingsStore = settingsStore
        self.notificationService = notificationService
        self.todayViewModel = TodayViewModel(store: gameStore)
        self.historyViewModel = HistoryViewModel(store: gameStore)
        self.achievementsViewModel = AchievementsViewModel(store: gameStore)
        self.settingsViewModel = SettingsViewModel(
            gameStore: gameStore,
            settingsStore: settingsStore,
            notificationService: notificationService
        )
    }
}

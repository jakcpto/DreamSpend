import Foundation
#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class AppIconService {
    func sync(with appIcon: AppIconOption) {
        guard supportsAlternateIcons else { return }
        let desiredIconName = appIcon.alternateIconName
        guard currentAlternateIconName != desiredIconName else { return }
        UIApplication.shared.setAlternateIconName(desiredIconName, completionHandler: nil)
    }

    func setAppIcon(_ appIcon: AppIconOption) {
        guard supportsAlternateIcons else { return }
        UIApplication.shared.setAlternateIconName(appIcon.alternateIconName, completionHandler: nil)
    }

    private var supportsAlternateIcons: Bool {
        #if canImport(UIKit)
        UIApplication.shared.supportsAlternateIcons
        #else
        false
        #endif
    }

    private var currentAlternateIconName: String? {
        #if canImport(UIKit)
        UIApplication.shared.alternateIconName
        #else
        nil
        #endif
    }
}

@MainActor
final class AppContainer {
    let gameStateStore: GameStateStore
    let appSettingsStore: AppSettingsStore
    let notificationService: NotificationService
    let todayViewModel: TodayViewModel
    let historyViewModel: HistoryViewModel
    let achievementsViewModel: AchievementsViewModel
    let settingsViewModel: SettingsViewModel
    let appIconService: AppIconService

    init() {
        let gameStore = GameStateStore()
        let settingsStore = AppSettingsStore(gameStore: gameStore)
        let notificationService = NotificationService()
        let appIconService = AppIconService()

        self.gameStateStore = gameStore
        self.appSettingsStore = settingsStore
        self.notificationService = notificationService
        self.appIconService = appIconService
        self.todayViewModel = TodayViewModel(store: gameStore)
        self.historyViewModel = HistoryViewModel(store: gameStore)
        self.achievementsViewModel = AchievementsViewModel(store: gameStore)
        self.settingsViewModel = SettingsViewModel(
            gameStore: gameStore,
            settingsStore: settingsStore,
            notificationService: notificationService,
            appIconService: appIconService
        )
    }

    func syncAppIcon() {
        appIconService.sync(with: gameStateStore.settings.appIcon)
    }
}

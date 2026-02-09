import SwiftUI

struct RootView: View {
    let container: AppContainer
    @ObservedObject private var gameStore: GameStateStore
    @State private var selectedTab: AppTab = .today

    init(container: AppContainer) {
        self.container = container
        self._gameStore = ObservedObject(wrappedValue: container.gameStateStore)
    }

    var body: some View {
        let language = gameStore.settings.languageCode

        TabView(selection: $selectedTab) {
            TodayView(viewModel: TodayViewModel(store: container.gameStateStore))
                .tabItem { Label(L10n.text("tab.today", language), systemImage: "sun.max") }
                .tag(AppTab.today)

            HistoryView(viewModel: HistoryViewModel(store: container.gameStateStore))
                .tabItem { Label(L10n.text("tab.history", language), systemImage: "clock.arrow.circlepath") }
                .tag(AppTab.history)

            AchievementsView(viewModel: AchievementsViewModel(store: container.gameStateStore))
                .tabItem { Label(L10n.text("tab.achievements", language), systemImage: "trophy") }
                .tag(AppTab.achievements)

            SettingsView(viewModel: SettingsViewModel(gameStore: container.gameStateStore, settingsStore: container.appSettingsStore, notificationService: container.notificationService))
                .tabItem { Label(L10n.text("tab.settings", language), systemImage: "gearshape") }
                .tag(AppTab.settings)
        }
        .environment(\.locale, Locale(identifier: language.localeIdentifier))
    }
}

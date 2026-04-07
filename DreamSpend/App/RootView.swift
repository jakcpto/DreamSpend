import SwiftUI

struct RootView: View {
    let container: AppContainer
    @ObservedObject private var gameStore: GameStateStore
    @State private var selectedTab: AppTab = .today
    @State private var requestedEditingDayIndex: Int?
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    init(container: AppContainer) {
        self.container = container
        self._gameStore = ObservedObject(wrappedValue: container.gameStateStore)
    }

    var body: some View {
        let language = gameStore.settings.languageCode
        let shouldShowOnboarding = !hasCompletedOnboarding

        TabView(selection: $selectedTab) {
            Tab(L10n.text("tab.today", language), systemImage: "sun.max", value: AppTab.today) {
                TodayView(
                    viewModel: container.todayViewModel,
                    requestedEditingDayIndex: $requestedEditingDayIndex
                )
            }

            Tab(L10n.text("tab.achievements", language), systemImage: "trophy", value: AppTab.achievements) {
                AchievementsView(viewModel: container.achievementsViewModel)
            }

            Tab(L10n.text("tab.settings", language), systemImage: "gearshape", value: AppTab.settings) {
                SettingsView(viewModel: container.settingsViewModel)
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .environment(\.locale, Locale(identifier: language.localeIdentifier))
        .fullScreenCover(isPresented: Binding(
            get: { shouldShowOnboarding },
            set: { if !$0 { hasCompletedOnboarding = true } }
        )) {
            OnboardingView(
                language: language,
                onStartDemo: {
                    selectedTab = .today
                    requestedEditingDayIndex = gameStore.prepareOnboardingDemo()
                    hasCompletedOnboarding = true
                },
                onSkip: {
                    gameStore.clearOnboardingDemo()
                    hasCompletedOnboarding = true
                }
            )
        }
    }
}

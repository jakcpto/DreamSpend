import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    let gameStore: GameStateStore
    let settingsStore: AppSettingsStore
    let notificationService: NotificationService

    @Published var fxStatusMessage: String?

    private let liveFXService: LiveFXService
    private var cancellables: Set<AnyCancellable> = []

    init(
        gameStore: GameStateStore,
        settingsStore: AppSettingsStore,
        notificationService: NotificationService,
        liveFXService: LiveFXService = LiveFXService()
    ) {
        self.gameStore = gameStore
        self.settingsStore = settingsStore
        self.notificationService = notificationService
        self.liveFXService = liveFXService

        gameStore.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    var settings: Settings { gameStore.settings }

    var language: SupportedLanguage { settings.languageCode }

    var manualFXPair: (source: String, target: String) {
        switch language {
        case .ru: return ("USD", "RUB")
        case .en: return ("USD", "EUR")
        case .de: return ("EUR", "USD")
        }
    }

    func currentManualRateString() -> String {
        let pair = manualFXPair
        let key = "\(pair.source)->\(pair.target)"
        if let rate = settings.approxFxTable[key] {
            return NSDecimalNumber(decimal: rate).stringValue
        }
        return ""
    }

    func toggleNotifications(enabled: Bool) async {
        if enabled {
            let granted = await notificationService.requestPermissionIfNeeded()
            settingsStore.setReminder(
                hour: settings.reminderHour,
                minute: settings.reminderMinute,
                enabled: granted
            )
            if granted {
                await notificationService.scheduleDailyReminder(
                    hour: settings.reminderHour,
                    minute: settings.reminderMinute
                )
            }
        } else {
            settingsStore.setReminder(
                hour: settings.reminderHour,
                minute: settings.reminderMinute,
                enabled: false
            )
            await notificationService.clearPendingReminders()
        }
    }

    func fetchRatesForCurrentLanguage() async {
        do {
            switch language {
            case .ru:
                let usdRub = try await liveFXService.fetchRate(from: "USD", to: "RUB")
                settingsStore.setFXRate(source: "USD", target: "RUB", rate: usdRub)
                let eurRub = try await liveFXService.fetchRate(from: "EUR", to: "RUB")
                settingsStore.setFXRate(source: "EUR", target: "RUB", rate: eurRub)
            case .en:
                let usdEur = try await liveFXService.fetchRate(from: "USD", to: "EUR")
                settingsStore.setFXRate(source: "USD", target: "EUR", rate: usdEur)
            case .de:
                let eurUsd = try await liveFXService.fetchRate(from: "EUR", to: "USD")
                settingsStore.setFXRate(source: "EUR", target: "USD", rate: eurUsd)
            }
            fxStatusMessage = L10n.text("settings.fx.updated", language)
        } catch {
            fxStatusMessage = L10n.text("settings.fx.failed", language)
        }
    }
}

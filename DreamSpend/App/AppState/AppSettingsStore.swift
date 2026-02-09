import Foundation
import Combine

@MainActor
final class AppSettingsStore: ObservableObject {
    private let gameStore: GameStateStore

    init(gameStore: GameStateStore) {
        self.gameStore = gameStore
    }

    var settings: Settings {
        gameStore.settings
    }

    func switchLanguage(_ language: SupportedLanguage) {
        gameStore.updateLanguage(language)
    }

    func setStartAmount(_ amountMinor: Int64, for language: SupportedLanguage) {
        gameStore.updateStartAmount(amountMinor, language: language)
    }

    func setMaxAmount(_ amountMinor: Int64, for language: SupportedLanguage) {
        gameStore.updateMaxAmount(amountMinor, language: language)
    }

    func setMaxBehavior(_ behavior: MaxBehavior) {
        gameStore.updateMaxBehavior(behavior)
    }

    func setReminder(hour: Int, minute: Int, enabled: Bool) {
        gameStore.updateReminder(hour: hour, minute: minute, enabled: enabled)
    }

    func setFXRate(source: String, target: String, rate: Decimal) {
        gameStore.updateFX(source: source, target: target, rate: rate)
    }
}

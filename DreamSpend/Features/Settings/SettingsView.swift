import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    @State private var reminderTime: Date = Date()
    @State private var notificationsEnabled: Bool = false
    @State private var startAmountText: String = ""
    @State private var maxAmountText: String = ""
    @State private var fxRateText: String = ""
    @State private var showResetConfirmation = false
    @State private var showFXSavedState = false

    private var language: SupportedLanguage {
        viewModel.language
    }

    var body: some View {
        NavigationStack {
            List {
                Section(L10n.text("settings.lang", language)) {
                    Picker(L10n.text("settings.lang", language), selection: Binding(
                        get: { viewModel.settings.languageCode },
                        set: { newLanguage in
                            viewModel.settingsStore.switchLanguage(newLanguage)
                            syncLimitFields()
                        }
                    )) {
                        ForEach(SupportedLanguage.allCases) { language in
                            Text(language.uiLabel).tag(language)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(L10n.text("settings.limits", language)) {
                    decimalTextField(L10n.text("settings.start", language), text: $startAmountText)
                    decimalTextField(L10n.text("settings.max", language), text: $maxAmountText)
                    Button(L10n.text("settings.saveLimits", language)) {
                        let currentLanguage = viewModel.settings.languageCode
                        let currency = viewModel.settings.currencyCode(for: currentLanguage)
                        viewModel.settingsStore.setStartAmount(MinorUnits.fromMajor(Decimal(string: startAmountText.replacingOccurrences(of: ",", with: ".")) ?? 0, currencyCode: currency), for: currentLanguage)
                        viewModel.settingsStore.setMaxAmount(MinorUnits.fromMajor(Decimal(string: maxAmountText.replacingOccurrences(of: ",", with: ".")) ?? 0, currencyCode: currency), for: currentLanguage)
                    }
                }

                Section(L10n.text("settings.maxBehavior", language)) {
                    Picker(L10n.text("settings.mode", language), selection: Binding(
                        get: {
                            switch viewModel.settings.maxBehavior {
                            case .resetAndRestart, .ceiling: return viewModel.settings.maxBehavior
                            case .celebrationAndStop: return .resetAndRestart
                            }
                        },
                        set: { viewModel.settingsStore.setMaxBehavior($0) }
                    )) {
                        Text(L10n.text("settings.reset", language)).tag(MaxBehavior.resetAndRestart)
                        Text(L10n.text("settings.ceiling", language)).tag(MaxBehavior.ceiling)
                    }
                    .pickerStyle(.segmented)

                    if viewModel.settings.maxBehavior == .ceiling {
                        Text(L10n.text("settings.ceiling.hint", language))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(L10n.text("settings.reset.hint", language))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section(L10n.text("settings.fx", language)) {
                    decimalTextField("\(viewModel.manualFXPair.source) -> \(viewModel.manualFXPair.target)", text: $fxRateText)
                    Button(L10n.text("settings.fx.update", language)) {
                        if let rate = Decimal(string: fxRateText.replacingOccurrences(of: ",", with: ".")) {
                            let pair = viewModel.manualFXPair
                            viewModel.settingsStore.setFXRate(source: pair.source, target: pair.target, rate: rate)
                            triggerFXSavedAnimation()
                        }
                    }
                    .overlay(alignment: .trailing) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .scaleEffect(showFXSavedState ? 1 : 0.1)
                            .opacity(showFXSavedState ? 1 : 0)
                            .animation(.spring(response: 0.28, dampingFraction: 0.78), value: showFXSavedState)
                    }

                    Button(L10n.text("settings.fx.fetch", language)) {
                        Task { await viewModel.fetchRatesForCurrentLanguage() }
                    }

                    if let message = viewModel.fxStatusMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section(L10n.text("settings.notifications", language)) {
                    Toggle(L10n.text("settings.notifications.enabled", language), isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, value in
                            Task { await viewModel.toggleNotifications(enabled: value) }
                        }

                    DatePicker(L10n.text("settings.notifications.time", language), selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .onChange(of: reminderTime) { _, value in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: value)
                            viewModel.settingsStore.setReminder(
                                hour: components.hour ?? 14,
                                minute: components.minute ?? 15,
                                enabled: notificationsEnabled
                            )
                        }
                }

                Section {
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Text(L10n.text("settings.resetAll", language))
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                } footer: {
                    Text(L10n.text("settings.resetAll.hint", language))
                }
            }
            .navigationTitle(L10n.text("settings.title", language))
            .alert(
                L10n.text("settings.resetAll.confirm.title", language),
                isPresented: $showResetConfirmation
            ) {
                Button(L10n.text("common.cancel", language), role: .cancel) {}
                Button(L10n.text("settings.resetAll", language), role: .destructive) {
                    viewModel.resetProgress()
                }
            } message: {
                Text(L10n.text("settings.resetAll.confirm.message", language))
            }
            .onAppear {
                notificationsEnabled = viewModel.settings.notificationsEnabled
                var components = DateComponents()
                components.hour = viewModel.settings.reminderHour
                components.minute = viewModel.settings.reminderMinute
                reminderTime = Calendar.current.date(from: components) ?? Date()
                syncLimitFields()
                fxRateText = viewModel.currentManualRateString()
            }
            .onChange(of: viewModel.settings.languageCode) { _, _ in
                syncLimitFields()
                fxRateText = viewModel.currentManualRateString()
            }
        }
    }

    @ViewBuilder
    private func decimalTextField(_ title: String, text: Binding<String>) -> some View {
        #if os(iOS)
        TextField(title, text: text)
            .keyboardType(.decimalPad)
        #else
        TextField(title, text: text)
        #endif
    }

    private func syncLimitFields() {
        let currentLanguage = viewModel.settings.languageCode
        let currency = viewModel.settings.currencyCode(for: currentLanguage)
        let start = MinorUnits.toMajor(viewModel.settings.startAmountMinor(for: currentLanguage), currencyCode: currency)
        let max = MinorUnits.toMajor(viewModel.settings.maxAmountMinor(for: currentLanguage), currencyCode: currency)
        startAmountText = NSDecimalNumber(decimal: start).stringValue
        maxAmountText = NSDecimalNumber(decimal: max).stringValue
    }

    private func triggerFXSavedAnimation() {
        showFXSavedState = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            showFXSavedState = false
        }
    }
}

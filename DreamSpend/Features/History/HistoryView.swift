import SwiftUI

struct HistoryView: View {
    let viewModel: HistoryViewModel

    private var language: SupportedLanguage {
        viewModel.store.settings.languageCode
    }

    var body: some View {
        NavigationStack {
            List {
                if viewModel.days.isEmpty {
                    EmptyStateView(title: L10n.text("history.empty", language), subtitle: L10n.text("history.empty.sub", language))
                } else {
                    ForEach(viewModel.days) { day in
                        NavigationLink {
                            List {
                                ForEach(day.items) { item in
                                    LabeledContent(item.title) {
                                        Text(amount(day: day, minor: item.amountMinor))
                                    }
                                }
                            }
                            .navigationTitle(L10n.day(day.dayIndex, language))
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L10n.day(day.dayIndex, language))
                                    .font(.headline)
                                Text(day.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(amount(day: day, minor: day.dailyLimitMinor))
                                    .font(.subheadline)
                                Text(statusText(day.status))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle(L10n.text("history.title", language))
        }
    }

    private func amount(day: DayEntry, minor: Int64) -> String {
        CurrencyFormatter.format(
            minor: minor,
            currencyCode: day.currencyCode,
            localeIdentifier: viewModel.store.settings.languageCode.localeIdentifier
        )
    }

    private func statusText(_ status: DayStatus) -> String {
        switch status {
        case .open: return L10n.text("history.status.open", language)
        case .filled: return L10n.text("history.status.filled", language)
        case .missed: return L10n.text("history.status.missed", language)
        }
    }
}

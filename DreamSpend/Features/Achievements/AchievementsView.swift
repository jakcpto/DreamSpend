import SwiftUI
import Charts

struct AchievementsView: View {
    @ObservedObject var viewModel: AchievementsViewModel
    @State private var showsAmounts = false

    private var language: SupportedLanguage {
        viewModel.store.settings.languageCode
    }

    var body: some View {
        NavigationStack {
            List {
                Section(L10n.text("achievements.analytics.title", language)) {
                    if viewModel.categorySlices.isEmpty {
                        Text(L10n.text("achievements.analytics.empty", language))
                            .foregroundStyle(.secondary)
                    } else {
                        Chart(viewModel.categorySlices) { slice in
                            SectorMark(
                                angle: .value("Share", slice.share),
                                innerRadius: .ratio(0.58),
                                angularInset: 1
                            )
                            .foregroundStyle(by: .value("Category", slice.name))
                        }
                        .chartForegroundStyleScale(
                            domain: viewModel.categorySlices.map(\.name),
                            range: categoryPalette
                        )
                        .frame(height: 220)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showsAmounts.toggle()
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(viewModel.categorySlices) { slice in
                                HStack {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(categoryPalette[viewModel.colorIndex(for: slice)])
                                        .frame(width: 12, height: 12)
                                    Text(slice.name)
                                    Spacer()
                                    Text(showsAmounts ? viewModel.categoryAmountText(slice) : viewModel.categoryPercentText(slice))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        Text(showsAmounts ? L10n.text("achievements.analytics.hint.amount", language) : L10n.text("achievements.analytics.hint.percent", language))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let range = viewModel.analyticsDateRangeText {
                            LabeledContent(L10n.text("achievements.analytics.range", language)) {
                                Text(range)
                                    .font(.caption)
                            }
                        }
                    }
                }

                Section {
                    ForEach(viewModel.achievements) { achievement in
                        HStack {
                            Image(systemName: achievement.isEarned ? "checkmark.seal.fill" : "seal")
                                .foregroundStyle(achievement.isEarned ? .green : .secondary)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(title(for: achievement.kind))
                                Text(achievement.isEarned ? L10n.text("achievements.earned", language) : L10n.text("achievements.progress", language))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let date = achievement.earnedAt {
                                Text(date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle(L10n.text("achievements.title", language))
        }
    }

    private func title(for kind: AchievementKind) -> String {
        switch kind {
        case .streak3: return streakTitle(3)
        case .streak7: return streakTitle(7)
        case .streak14: return streakTitle(14)
        case .streak30: return streakTitle(30)
        case .perfectFill: return language == .ru ? "Идеальное заполнение" : (language == .de ? "Perfektes Fuellen" : "Perfect fill")
        case .reachedMaximum: return language == .ru ? "Достигнут максимум" : (language == .de ? "Maximum erreicht" : "Maximum reached")
        }
    }

    private func streakTitle(_ days: Int) -> String {
        switch language {
        case .ru: return "Серия \(days) дней"
        case .en: return "\(days)-day streak"
        case .de: return "Serie \(days) Tage"
        }
    }

    private var categoryPalette: [Color] {
        [.blue, .green, .orange, .pink, .teal, .indigo, .yellow, .mint, .cyan, .red, .brown, .gray]
    }
}

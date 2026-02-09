import SwiftUI

struct AchievementsView: View {
    let viewModel: AchievementsViewModel

    private var language: SupportedLanguage {
        viewModel.store.settings.languageCode
    }

    var body: some View {
        NavigationStack {
            List(viewModel.achievements) { achievement in
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
}

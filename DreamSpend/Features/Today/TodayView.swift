import SwiftUI

struct TodayView: View {
    let viewModel: TodayViewModel
    @State private var isEditingSpends = false

    private var language: SupportedLanguage {
        viewModel.store.settings.languageCode
    }

    var body: some View {
        NavigationStack {
            List {
                ProgressHeader(
                    title: viewModel.dayLabel,
                    subtitle: viewModel.amountLabel,
                    progress: viewModel.progressToMax
                )

                if viewModel.isDayFilled {
                    Section(L10n.text("today.spends", language)) {
                        ForEach(viewModel.todayItems) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.headline)
                                if let category = item.category {
                                    Text(category)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                } else {
                    Section {
                        PrimaryButton(title: L10n.text("today.fill", language)) {
                            isEditingSpends = true
                        }
                    }
                }

                if viewModel.store.isPausedAfterMaximum {
                    Section {
                        Text(L10n.text("today.paused", language))
                            .font(.subheadline)
                        PrimaryButton(title: L10n.text("common.restart", language)) {
                            viewModel.store.restartGame()
                        }
                    }
                }
            }
            .navigationTitle(L10n.text("tab.today", language))
            .sheet(isPresented: $isEditingSpends) {
                NavigationStack {
                    DaySpendsView(viewModel: DaySpendsViewModel(store: viewModel.store))
                }
            }
            #if os(iOS)
            .fullScreenCover(isPresented: Binding(
                get: { viewModel.store.showCelebration },
                set: { if !$0 { viewModel.store.dismissCelebration() } }
            )) {
                CelebrationView(viewModel: CelebrationViewModel(store: viewModel.store))
            }
            #else
            .sheet(isPresented: Binding(
                get: { viewModel.store.showCelebration },
                set: { if !$0 { viewModel.store.dismissCelebration() } }
            )) {
                CelebrationView(viewModel: CelebrationViewModel(store: viewModel.store))
            }
            #endif
        }
    }
}

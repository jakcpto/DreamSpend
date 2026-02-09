import SwiftUI

struct TodayView: View {
    let viewModel: TodayViewModel
    @State private var selectedDayIndex: Int?
    @State private var editingDayIndex: Int?

    private var language: SupportedLanguage {
        viewModel.store.settings.languageCode
    }

    private var selectedDay: DayEntry? {
        viewModel.day(for: selectedDayIndex ?? viewModel.todayDayIndex)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let topHeight = proxy.size.height * 0.25
                let bottomHeight = proxy.size.height * 0.75

                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(viewModel.monthAndYear(for: selectedDay))
                            .font(.title2.bold())
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(viewModel.availableDays) { day in
                                    dateTile(for: day)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .frame(height: topHeight, alignment: .top)

                    Group {
                        if viewModel.isFilled(day: selectedDay) {
                            List {
                                Section(L10n.text("today.spends", language)) {
                                    ForEach(viewModel.spends(for: selectedDay)) { item in
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
                            }
                        } else {
                            VStack {
                                Spacer()
                                PrimaryButton(title: L10n.text("today.fill", language)) {
                                    editingDayIndex = selectedDay?.dayIndex ?? viewModel.todayDayIndex
                                }
                                .padding(.horizontal, 16)
                                Spacer()
                            }
                        }
                    }
                    .frame(height: bottomHeight)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                selectedDayIndex = viewModel.todayDayIndex
            }
            .onChange(of: viewModel.todayDayIndex) { _, newValue in
                if let selectedDayIndex,
                   viewModel.day(for: selectedDayIndex) == nil {
                    self.selectedDayIndex = newValue
                } else if self.selectedDayIndex == nil {
                    self.selectedDayIndex = newValue
                }
            }
            .sheet(item: Binding(
                get: {
                    editingDayIndex.map { EditableDay(id: $0) }
                },
                set: { editingDayIndex = $0?.id }
            )) { day in
                NavigationStack {
                    DaySpendsView(viewModel: DaySpendsViewModel(store: viewModel.store, dayIndex: day.id))
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

    @ViewBuilder
    private func dateTile(for day: DayEntry) -> some View {
        let isSelected = selectedDay?.dayIndex == day.dayIndex

        VStack(spacing: 8) {
            Text(day.date.formatted(.dateTime.day()))
                .font(.title3.bold())
            Text(viewModel.amountLabel(for: day))
                .font(.caption2)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(isSelected ? Color.white : Color.primary)
        .frame(width: 92, height: 92)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isSelected ? Color.accentColor : Color.gray.opacity(0.14))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? Color.clear : Color.gray.opacity(0.25), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            selectedDayIndex = day.dayIndex
        }
        .onLongPressGesture {
            editingDayIndex = day.dayIndex
        }
    }
}

private struct EditableDay: Identifiable {
    let id: Int
}

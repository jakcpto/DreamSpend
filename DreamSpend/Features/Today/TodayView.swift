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
                let topHeight = proxy.size.height * 0.34
                let bottomHeight = proxy.size.height * 0.66

                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(viewModel.monthAndYear(for: selectedDay))
                            .font(.title2.bold())
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ScrollView([.horizontal, .vertical], showsIndicators: true) {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(viewModel.monthSections) { section in
                                    HStack(alignment: .top, spacing: 12) {
                                        ForEach(section.days) { day in
                                            dateTile(for: day)
                                                .id(day.dayIndex)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                            .padding(.bottom, 4)
                        }
                        .onAppear {
                            selectLatestDay()
                        }
                        .onChange(of: viewModel.availableDays.last?.dayIndex) { newValue in
                            guard let target = newValue else { return }
                            selectedDayIndex = target
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
        let progress = viewModel.fillProgress(for: day)
        let tileBackground = tileBackgroundColor(for: day, isSelected: isSelected)
        let progressColor = tileProgressColor(for: day, isSelected: isSelected)

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
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(tileBackground)

                if progress > 0 {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(progressColor)
                        .frame(height: 92 * progress)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(tileBorderColor(for: day, isSelected: isSelected), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            selectedDayIndex = day.dayIndex
        }
        .onLongPressGesture {
            editingDayIndex = day.dayIndex
        }
    }

    private func selectLatestDay() {
        guard let latest = viewModel.availableDays.last else {
            selectedDayIndex = viewModel.todayDayIndex
            return
        }
        selectedDayIndex = latest.dayIndex
    }

    private func tileBackgroundColor(for day: DayEntry, isSelected: Bool) -> Color {
        if isSelected {
            return Color.accentColor.opacity(day.status == .missed ? 0.22 : 0.28)
        }

        switch day.status {
        case .missed:
            return Color.orange.opacity(0.14)
        case .filled:
            return Color.gray.opacity(0.12)
        case .open:
            return Color.gray.opacity(0.14)
        }
    }

    private func tileProgressColor(for day: DayEntry, isSelected: Bool) -> Color {
        if isSelected {
            return Color.accentColor
        }

        return day.status == .filled ? Color.accentColor.opacity(0.82) : Color.clear
    }

    private func tileBorderColor(for day: DayEntry, isSelected: Bool) -> Color {
        if isSelected {
            return Color.accentColor
        }

        return day.status == .missed ? Color.orange.opacity(0.32) : Color.gray.opacity(0.25)
    }
}

private struct EditableDay: Identifiable {
    let id: Int
}

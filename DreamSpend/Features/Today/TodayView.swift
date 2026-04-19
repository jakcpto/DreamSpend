import SwiftUI
#if os(iOS)
import CoreMotion
#endif

struct TodayView: View {
    let viewModel: TodayViewModel
    @Binding var requestedEditingDayIndex: Int?
    @State private var selectedDayIndex: Int?
    @State private var editingDayIndex: Int?
    @AppStorage("liquidEffectEnabled") private var liquidEffectEnabled: Bool = true
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var language: SupportedLanguage {
        viewModel.store.settings.languageCode
    }

    private var selectedDay: DayEntry? {
        viewModel.day(for: selectedDayIndex ?? viewModel.todayDayIndex)
    }

    private var isRegularWidth: Bool {
        horizontalSizeClass == .regular
    }

    private var selectedSpentLabel: String {
        guard let selectedDay else { return amountLabel(minor: 0, currencyCode: viewModel.store.settings.currencyCode(for: language)) }
        return amountLabel(minor: selectedDay.totalSpentMinor, currencyCode: selectedDay.currencyCode)
    }

    private var selectedRemainingLabel: String {
        guard let selectedDay else { return amountLabel(minor: 0, currencyCode: viewModel.store.settings.currencyCode(for: language)) }
        return amountLabel(minor: selectedDay.remainingMinor, currencyCode: selectedDay.currencyCode)
    }

    private var selectedStatusText: String {
        guard let selectedDay else { return L10n.text("history.status.open", language) }
        switch selectedDay.status {
        case .open:
            return L10n.text("history.status.open", language)
        case .filled:
            return L10n.text("history.status.filled", language)
        case .missed:
            return L10n.text("history.status.missed", language)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isRegularWidth {
                    iPadLayout
                } else {
                    iPhoneLayout
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: viewModel.todayDayIndex) {
                let newValue = viewModel.todayDayIndex
                if let selectedDayIndex,
                   viewModel.day(for: selectedDayIndex) == nil {
                    self.selectedDayIndex = newValue
                } else if self.selectedDayIndex == nil {
                    self.selectedDayIndex = newValue
                }
            }
            .onAppear {
                handleExternalEditingRequest()
            }
            .onChange(of: requestedEditingDayIndex) {
                handleExternalEditingRequest()
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

    // MARK: - Calendar Grid (shared)

    private var calendarGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.monthAndYear(for: selectedDay))
                .font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)

            ScrollViewReader { proxy in
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.monthSections) { section in
                            HStack(alignment: .top, spacing: 10) {
                                Text(viewModel.monthLabel(for: section.monthStart))
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                    .frame(width: 34, alignment: .leading)
                                    .padding(.top, 8)

                                HStack(alignment: .top, spacing: 12) {
                                    ForEach(section.days) { day in
                                        dateTile(for: day)
                                            .id(day.dayIndex)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 2)
                    .padding(.bottom, 4)
                }
                .onAppear {
                    selectLatestDay()
                    scrollCalendarToCurrentDay(using: proxy, animated: false)
                }
                .onChange(of: viewModel.availableDays.last?.dayIndex) {
                    guard let target = viewModel.availableDays.last?.dayIndex else { return }
                    selectedDayIndex = target
                    scrollCalendarToCurrentDay(using: proxy)
                }
            }
        }
    }

    private var dayDetailPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(selectedDayTitle)
                        .font(.title2.bold())
                    Text(selectedDay?.date.formatted(date: .long, time: .omitted) ?? "")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                LazyVGrid(columns: detailSummaryColumns, alignment: .leading, spacing: 12) {
                    detailStatCard(
                        title: L10n.text("today.summary.spent", language),
                        value: selectedSpentLabel,
                        tint: .accentColor
                    )
                    detailStatCard(
                        title: L10n.text("today.summary.remaining", language),
                        value: selectedRemainingLabel,
                        tint: (selectedDay?.remainingMinor ?? 0) < 0 ? .red : .green
                    )
                    detailStatCard(
                        title: L10n.text("today.summary.status", language),
                        value: selectedStatusText,
                        tint: statusColor(for: selectedDay)
                    )
                }

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text(L10n.text("today.spends", language))
                            .font(.headline)
                        Spacer()
                        if selectedDay != nil {
                            Button(L10n.text("today.fill", language)) {
                                editingDayIndex = selectedDay?.dayIndex ?? viewModel.todayDayIndex
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }

                    if viewModel.spends(for: selectedDay).isEmpty {
                        EmptyStateView(
                            title: L10n.text("today.empty.title", language),
                            subtitle: L10n.text("today.empty.subtitle", language)
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    } else {
                        ForEach(viewModel.spends(for: selectedDay)) { item in
                            HStack(alignment: .top, spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title)
                                        .font(.headline)
                                    if let category = item.category {
                                        Text(category)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                Text(amountLabel(minor: item.amountMinor, currencyCode: selectedDay?.currencyCode ?? viewModel.store.settings.currencyCode(for: language)))
                                    .font(.subheadline.weight(.semibold))
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color(.secondarySystemBackground))
                            )
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(panelBackground)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    // MARK: - iPhone Layout

    private var iPhoneLayout: some View {
        GeometryReader { proxy in
            let calendarHeight = min(max(proxy.size.height * 0.34, 240), 280)

            VStack(spacing: 16) {
                calendarSectionCard
                    .frame(height: calendarHeight)

                dayDetailPanel
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .padding(16)
        .background(screenBackground.ignoresSafeArea())
    }

    private var iPadLayout: some View {
        GeometryReader { proxy in
            let leftWidth = min(max(proxy.size.width * 0.44, 380), 520)

            HStack(alignment: .top, spacing: 20) {
                calendarSectionCard
                    .frame(width: leftWidth)

                dayDetailPanel
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .background(screenBackground.ignoresSafeArea())
    }

    @ViewBuilder
    private func dateTile(for day: DayEntry) -> some View {
        let isSelected = selectedDay?.dayIndex == day.dayIndex
        let progress = viewModel.fillProgress(for: day)
        let tileBackground = tileBackgroundColor(for: day, isSelected: isSelected)
        let progressColor = tileProgressColor(for: day, progress: progress)
        let glassColor = tileGlassColor(for: day, isSelected: isSelected)
        let inset: CGFloat = 7

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

                RoundedRectangle(cornerRadius: 11)
                    .fill(glassColor)
                    .padding(inset)

                if progress > 0 {
                    if liquidEffectEnabled {
                        LiquidFill(progress: progress, color: progressColor, cornerRadius: 11)
                            .padding(inset)
                    } else {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(progressColor)
                            .padding(.horizontal, inset)
                            .padding(.bottom, inset)
                            .frame(height: (92 - inset) * progress, alignment: .bottom)
                    }
                }

                RoundedRectangle(cornerRadius: 11)
                    .stroke(glassColor.opacity(isSelected ? 0.5 : 0.8), lineWidth: 1)
                    .padding(inset)
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

    private func scrollCalendarToCurrentDay(using proxy: ScrollViewProxy, animated: Bool = true) {
        let targetDayIndex = viewModel.todayDayIndex ?? viewModel.availableDays.last?.dayIndex
        guard let targetDayIndex else { return }

        DispatchQueue.main.async {
            if animated {
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo(targetDayIndex, anchor: .center)
                }
            } else {
                proxy.scrollTo(targetDayIndex, anchor: .center)
            }
        }
    }

    private func handleExternalEditingRequest() {
        guard let requestedEditingDayIndex else { return }
        selectedDayIndex = requestedEditingDayIndex
        editingDayIndex = requestedEditingDayIndex
        self.requestedEditingDayIndex = nil
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

    private func tileProgressColor(for day: DayEntry, progress: CGFloat) -> Color {
        // No fill color when there's no progress
        guard progress > 0 else { return .clear }

        let p = Double(progress)

        // Map progress to color ranges:
        // 1%..45%  -> red
        // 46%..90% -> orange
        // 91%..101% -> green
        // 102%..105% -> burgundy
        switch p {
        case 0.01...0.45:
            return .red
        case 0.46...0.90:
            return .orange
        case 0.91...1.01:
            return .green
        case 1.02...1.05:
            return Color(red: 0.6, green: 0.0, blue: 0.2) // burgundy
        default:
            if p > 1.05 {
                return Color(red: 0.6, green: 0.0, blue: 0.2) // cap to burgundy when over 105%
            } else if p > 0 && p < 0.01 {
                return .red // treat very tiny non-zero as red
            } else {
                return .clear
            }
        }
    }

    private func tileBorderColor(for day: DayEntry, isSelected: Bool) -> Color {
        if isSelected {
            return Color.accentColor
        }

        return day.status == .missed ? Color.orange.opacity(0.32) : Color.gray.opacity(0.25)
    }

    private func tileGlassColor(for day: DayEntry, isSelected: Bool) -> Color {
        if day.status == .missed {
            return Color.orange.opacity(isSelected ? 0.08 : 0.05)
        }

        return Color.white.opacity(isSelected ? 0.18 : 0.12)
    }

    private var selectedDayTitle: String {
        guard let selectedDay else { return L10n.text("tab.today", language) }
        return L10n.day(selectedDay.dayIndex, language)
    }

    private var detailSummaryColumns: [GridItem] {
        [
            GridItem(.adaptive(minimum: isRegularWidth ? 160 : 140), spacing: 12, alignment: .top)
        ]
    }

    private var calendarSectionCard: some View {
        calendarGrid
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(panelBackground)
    }

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(.regularMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
    }

    private var screenBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.96, green: 0.97, blue: 0.99),
                Color(red: 0.92, green: 0.95, blue: 0.98)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func detailStatCard(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(tint.opacity(0.12))
        )
    }

    private func amountLabel(minor: Int64, currencyCode: String) -> String {
        CurrencyFormatter.format(
            minor: minor,
            currencyCode: currencyCode,
            localeIdentifier: language.localeIdentifier
        )
    }

    private func statusColor(for day: DayEntry?) -> Color {
        guard let day else { return .secondary }
        switch day.status {
        case .open:
            return .blue
        case .filled:
            return .green
        case .missed:
            return .orange
        }
    }

    // MARK: - Liquid Effect
    private struct LiquidFill: View {
        let progress: CGFloat
        let color: Color
        let cornerRadius: CGFloat

        @State private var phase: CGFloat = 0
        @State private var bubbleSeed: UInt64 = UInt64.random(in: 0...UInt64.max)

        var body: some View {
            GeometryReader { geo in
                let size = geo.size
                TimelineView(.animation) { timeline in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    let amplitude = max(2, min(size.height * 0.05, 8))
                    let speed = 1.2
                    let phase = CGFloat(time * speed)

                    ZStack(alignment: .bottom) {
                        // Liquid body with wavy, tilted surface
                        LiquidWaveShape(progress: progress, phase: phase, amplitude: amplitude)
                            .fill(color)

                        // Bubbles rising inside the liquid
                        BubblesLayer(seed: bubbleSeed, progress: progress)
                            .blendMode(.plusLighter)
                            .opacity(0.5)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                }
            }
        }
    }

    private struct LiquidWaveShape: Shape {
        let progress: CGFloat
        let phase: CGFloat
        let amplitude: CGFloat

        func path(in rect: CGRect) -> Path {
            var path = Path()
            let clamped = max(0, min(1, progress))
            let fillTop = rect.maxY - rect.height * clamped

            // Compute a simple tilt based on device roll (iOS only)
            #if os(iOS)
            let tilt = CGFloat(MotionManager.shared.currentRoll) // radians
            #else
            let tilt = CGFloat(0)
            #endif

            let waveAmp = amplitude
            let twoPi = CGFloat.pi * 2

            // Build top wavy edge with slight tilt
            var points: [CGPoint] = []
            let steps = max(24, Int(rect.width / 6))
            for i in 0...steps {
                let x = rect.minX + CGFloat(i) / CGFloat(steps) * rect.width
                let baseY = fillTop + sin((x / rect.width) * twoPi + phase) * waveAmp
                let tiltOffset = (x - rect.midX) * tan(tilt) * 0.06 // small tilt factor
                let y = min(rect.maxY, max(rect.minY, baseY + tiltOffset))
                points.append(CGPoint(x: x, y: y))
            }

            // Start from bottom-left
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            // Up to first point
            if let first = points.first {
                path.addLine(to: CGPoint(x: first.x, y: first.y))
            }
            // Wave along the top
            for p in points.dropFirst() {
                path.addLine(to: p)
            }
            // Down to bottom-right and close
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.closeSubpath()

            return path
        }
    }

    private struct BubblesLayer: View {
        let seed: UInt64
        let progress: CGFloat
        private let bubbleCount = 10

        var body: some View {
            GeometryReader { geo in
                let size = geo.size
                var rng = SeededRandom(seed: seed)
                let bubbles = (0..<bubbleCount).map { idx -> Bubble in
                    let r = rng.random(in: 3...7) + CGFloat(idx % 3)
                    let x = rng.random(in: r...(size.width - r))
                    let base = rng.random(in: 0.0...1.0)
                    return Bubble(x: x, radius: r, base: base)
                }
                TimelineView(.animation) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    ZStack {
                        ForEach(0..<bubbles.count, id: \.self) { i in
                            let b = bubbles[i]
                            let speed = (12.0 + Double(b.radius) * 1.2) / 10.0 // 10x slower
                            let yProgress = CGFloat((t * speed + Double(b.base) * 4).truncatingRemainder(dividingBy: Double(1.2)))
                            let liquidHeight = size.height * max(0, min(1, progress))
                            let y = size.height - liquidHeight + (1 - yProgress) * liquidHeight
                            Circle()
                                .fill(Color.white.opacity(0.25))
                                .frame(width: b.diameter, height: b.diameter)
                                .position(x: b.x, y: y)
                        }
                    }
                }
            }
        }

        private struct Bubble {
            let x: CGFloat
            let radius: CGFloat
            let base: CGFloat
            var diameter: CGFloat { radius * 2 }
        }
    }

    private struct SeededRandom {
        var state: UInt64
        init(seed: UInt64) { self.state = seed &* 0x9E3779B97F4A7C15 }
        mutating func next() -> UInt64 {
            state &+= 0x9E3779B97F4A7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
            z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
            return z ^ (z >> 31)
        }
        mutating func random(in range: ClosedRange<CGFloat>) -> CGFloat {
            let v = next()
            let unit = CGFloat(v) / CGFloat(UInt64.max)
            return range.lowerBound + (range.upperBound - range.lowerBound) * unit
        }
        mutating func random(in range: ClosedRange<Double>) -> Double {
            let v = next()
            let unit = Double(v) / Double(UInt64.max)
            return range.lowerBound + (range.upperBound - range.lowerBound) * unit
        }
    }

    #if os(iOS)
    private final class MotionManager {
        static let shared = MotionManager()
        private let manager = CMMotionManager()
        private(set) var currentRoll: Double = 0 // radians
        private init() {
            if manager.isDeviceMotionAvailable {
                manager.deviceMotionUpdateInterval = 1.0 / 30.0
                manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
                    guard let self, let motion else { return }
                    // Use roll relative to gravity; clamp to reasonable range
                    let roll = motion.attitude.roll
                    self.currentRoll = max(-.pi/4, min(.pi/4, roll))
                }
            }
        }
    }
    #endif
}

private struct EditableDay: Identifiable {
    let id: Int
}

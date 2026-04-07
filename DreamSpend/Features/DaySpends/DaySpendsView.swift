import SwiftUI

struct DaySpendsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: DaySpendsViewModel

    @State private var title: String = ""
    @State private var category: String = ""
    @State private var amountText: String = ""
    @State private var animateAdd: Bool = false
    @State private var selectedCategoryForEditing: String = ""
    @State private var categoryDraftName: String = ""
    @State private var isCategoryEditorPresented: Bool = false
    @State private var autosavedItemID: UUID?
    @State private var autosaveTask: Task<Void, Never>?
    @State private var amountFieldValidationTint: Double = 0

    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case title
        case amount
        case category
    }

    private var language: SupportedLanguage {
        viewModel.store.settings.languageCode
    }

    private var localeIdentifier: String {
        language.localeIdentifier
    }

    private var addButtonTitle: String {
        viewModel.editingItemID == nil ? L10n.text("spends.add", language) : L10n.text("spends.update", language)
    }

    var body: some View {
        List {
            if viewModel.hasDemoItems {
                Section {
                    Text(L10n.text("onboarding.editor.demoHint", language))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Section(L10n.text("spends.limit", language)) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(CurrencyFormatter.format(minor: viewModel.limitMinor, currencyCode: viewModel.currencyCode, localeIdentifier: localeIdentifier))
                    Text(L10n.text("spends.plus5", language))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section(viewModel.editingItemID == nil ? L10n.text("spends.section.add", language) : L10n.text("spends.section.edit", language)) {
                TextField(L10n.text("spends.name", language), text: $title)
                    .focused($focusedField, equals: .title)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .amount
                    }

                decimalTextField(L10n.text("spends.amount", language), text: $amountText)
                    .focused($focusedField, equals: .amount)
                    .submitLabel(.done)
                    .onSubmit {
                        focusedField = nil
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.red.opacity(amountFieldValidationTint))
                            .padding(.vertical, 2)
                    )

                HStack {
                    TextField(L10n.text("spends.category", language), text: $category)
                        .focused($focusedField, equals: .category)
                        .submitLabel(.done)
                        .onSubmit {
                            focusedField = nil
                        }
                    if !category.isEmpty {
                        Button {
                            category = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if !viewModel.categorySuggestions.isEmpty {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], alignment: .leading, spacing: 8) {
                        ForEach(viewModel.categorySuggestions, id: \.self) { suggestion in
                            categoryChip(for: suggestion)
                        }
                    }
                }

                Button {
                    commitCurrentSpend(categoryOverride: normalizedCategory)
                } label: {
                    HStack {
                        Image(systemName: viewModel.editingItemID == nil ? "plus.circle.fill" : "pencil.circle.fill")
                        Text(addButtonTitle)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .scaleEffect(animateAdd ? 0.98 : 1)
                .animation(.easeOut(duration: 0.12), value: animateAdd)
                .disabled(trimmedTitle.isEmpty || parsedAmountMinor <= 0)

                if viewModel.editingItemID != nil {
                    Button(L10n.text("spends.cancel.edit", language)) {
                        viewModel.cancelEditing()
                        resetEditor()
                    }
                    .buttonStyle(.bordered)
                }
            }

            Section(L10n.text("spends.list", language)) {
                if viewModel.draftItems.isEmpty {
                    EmptyStateView(title: L10n.text("spends.empty", language), subtitle: L10n.text("spends.empty.sub", language))
                } else {
                    ForEach(viewModel.draftItems) { item in
                        HStack(spacing: 10) {
                            VStack(alignment: .leading) {
                                Text(item.title)
                                    .font(.body)
                                if item.isDemo {
                                    Text(L10n.text("onboarding.editor.demoBadge", language))
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(.orange)
                                }
                                if let category = item.category {
                                    Text(category)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text(CurrencyFormatter.format(minor: item.amountMinor, currencyCode: viewModel.currencyCode, localeIdentifier: localeIdentifier))
                                .foregroundStyle(.primary)
                            Button {
                                withAnimation(.snappy) {
                                    viewModel.removeItem(id: item.id)
                                }
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            loadEditor(from: item)
                            viewModel.startEditing(item: item)
                        }
                    }
                    .onDelete(perform: viewModel.removeItem)
                }
            }
            .animation(.snappy, value: viewModel.draftItems)

            Section(L10n.text("spends.total", language)) {
                LabeledContent(L10n.text("spends.total", language)) {
                    Text(CurrencyFormatter.format(minor: viewModel.totalMinor, currencyCode: viewModel.currencyCode, localeIdentifier: localeIdentifier))
                }
                LabeledContent(L10n.text("spends.remaining", language)) {
                    Text(CurrencyFormatter.format(minor: viewModel.remainingMinor, currencyCode: viewModel.currencyCode, localeIdentifier: localeIdentifier))
                        .foregroundStyle(viewModel.remainingMinor < 0 ? .red : .primary)
                }
                if viewModel.totalMinor > viewModel.allowedTotalMinor {
                    Text(L10n.text("spends.over5", language))
                        .font(.caption)
                        .foregroundStyle(.red)
                } else if viewModel.totalMinor > viewModel.limitMinor {
                    Text(L10n.allowedOverage(CurrencyFormatter.format(minor: viewModel.overageMinor, currencyCode: viewModel.currencyCode, localeIdentifier: localeIdentifier), language))
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .navigationTitle(L10n.text("spends.title", language))
        .onChange(of: title) {
            scheduleAutosave()
        }
        .onChange(of: amountText) {
            scheduleAutosave()
        }
        .onChange(of: category) {
            scheduleAutosave()
        }
        .onDisappear {
            autosaveTask?.cancel()
            autosaveEditorIfNeeded()
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.text("common.close", language)) { dismiss() }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .sheet(isPresented: $isCategoryEditorPresented) {
            NavigationStack {
                Form {
                    Section {
                        TextField(L10n.text("spends.category", language), text: $categoryDraftName)
                    }

                    Section {
                        Button {
                            viewModel.cycleCategoryColor(selectedCategoryForEditing)
                        } label: {
                            HStack {
                                Circle()
                                    .fill(CategoryPalette.color(for: viewModel.colorToken(for: selectedCategoryForEditing)))
                                    .frame(width: 18, height: 18)
                                Text(language == .ru ? "Сменить цвет" : (language == .de ? "Farbe wechseln" : "Change color"))
                            }
                        }
                    }
                }
                .navigationTitle(language == .ru ? "Тег" : (language == .de ? "Kategorie" : "Category"))
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(L10n.text("spends.cancel.edit", language)) {
                            isCategoryEditorPresented = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(L10n.text("spends.update", language)) {
                            let previousName = selectedCategoryForEditing
                            let updatedName = categoryDraftName
                            viewModel.renameCategory(previousName, to: updatedName)
                            if category.caseInsensitiveCompare(previousName) == .orderedSame {
                                category = updatedName.trimmingCharacters(in: .whitespacesAndNewlines)
                            }
                            isCategoryEditorPresented = false
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func categoryChip(for suggestion: String) -> some View {
        HStack(spacing: 6) {
            Text(suggestion)
                .font(.subheadline)
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    Capsule()
                        .fill(CategoryPalette.color(for: viewModel.colorToken(for: suggestion)).opacity(0.16))
                )
                .overlay(
                    Capsule()
                        .stroke(CategoryPalette.color(for: viewModel.colorToken(for: suggestion)).opacity(0.4), lineWidth: 1)
                )
                .contentShape(Capsule())
                .onTapGesture(count: 2) {
                    guard !viewModel.isDefaultCategory(suggestion) else { return }
                    selectedCategoryForEditing = suggestion
                    categoryDraftName = suggestion
                    focusedField = nil
                    isCategoryEditorPresented = true
                }
                .onTapGesture {
                    category = suggestion
                    focusedField = nil
                    commitCurrentSpend(categoryOverride: suggestion)
                }

            if !viewModel.isDefaultCategory(suggestion) {
                Button {
                    viewModel.removeCategory(suggestion)
                    if category.caseInsensitiveCompare(suggestion) == .orderedSame {
                        category = ""
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption2.bold())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.removeCategory(suggestion, language))
            }
        }
    }

    private func loadEditor(from item: SpendItem) {
        autosaveTask?.cancel()
        autosavedItemID = item.id
        title = item.title
        amountText = majorString(fromMinor: item.amountMinor)
        category = item.category ?? ""
        DispatchQueue.main.async {
            focusedField = nil
        }
    }

    private func resetEditor() {
        autosaveTask?.cancel()
        autosavedItemID = nil
        title = ""
        amountText = ""
        category = ""
        viewModel.cancelEditing()
        DispatchQueue.main.async {
            focusedField = nil
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            animateAdd = false
        }
    }

    private func majorString(fromMinor minor: Int64) -> String {
        let major = MinorUnits.toMajor(minor, currencyCode: viewModel.currencyCode)
        return NSDecimalNumber(decimal: major).stringValue
    }

    private func parseMinor(_ value: String) -> Int64 {
        let normalized = value.replacingOccurrences(of: ",", with: ".")
        let decimal = Decimal(string: normalized) ?? 0
        return MinorUnits.fromMajor(decimal, currencyCode: viewModel.currencyCode)
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var parsedAmountMinor: Int64 {
        parseMinor(amountText)
    }

    private var normalizedCategory: String? {
        let trimmed = category.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private var autosaveCategory: String? {
        guard let normalizedCategory else { return nil }
        return viewModel.matchingSuggestedCategory(for: normalizedCategory)
    }

    private var currentEditorItemID: UUID? {
        viewModel.editingItemID ?? autosavedItemID
    }

    private func commitCurrentSpend(categoryOverride: String?) {
        let selectedCategory = categoryOverride?.trimmingCharacters(in: .whitespacesAndNewlines)
        let category = (selectedCategory?.isEmpty == false ? selectedCategory : normalizedCategory)

        guard !trimmedTitle.isEmpty, parsedAmountMinor > 0, let category else { return }
        guard canCommit(amountMinor: parsedAmountMinor) else {
            triggerAmountValidationFeedback()
            return
        }

        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
            _ = viewModel.upsertItem(
                id: currentEditorItemID,
                title: title,
                amountMinor: parsedAmountMinor,
                category: category
            )
            animateAdd = true
        }
        resetEditor()
    }

    private func canCommit(amountMinor: Int64) -> Bool {
        let itemID = currentEditorItemID
        let existingAmount = itemID.flatMap { id in
            viewModel.draftItems.first(where: { $0.id == id })?.amountMinor
        } ?? 0
        let proposedTotal = viewModel.totalMinor - existingAmount + amountMinor
        return proposedTotal <= viewModel.allowedTotalMinor
    }

    private func triggerAmountValidationFeedback() {
        autosaveTask?.cancel()
        amountFieldValidationTint = 0.32

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeOut(duration: 0.5)) {
                amountFieldValidationTint = 0
            }
        }
    }

    private func scheduleAutosave() {
        autosaveTask?.cancel()
        let itemID = currentEditorItemID
        let title = trimmedTitle
        let amountMinor = parsedAmountMinor
        let category = autosaveCategory

        guard !title.isEmpty, amountMinor > 0, let category else { return }

        autosaveTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            autosavedItemID = viewModel.upsertItem(
                id: itemID,
                title: title,
                amountMinor: amountMinor,
                category: category
            )
        }
    }

    private func autosaveEditorIfNeeded() {
        guard !trimmedTitle.isEmpty, parsedAmountMinor > 0, let category = autosaveCategory else { return }
        autosavedItemID = viewModel.upsertItem(
            id: currentEditorItemID,
            title: trimmedTitle,
            amountMinor: parsedAmountMinor,
            category: category
        )
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
}
